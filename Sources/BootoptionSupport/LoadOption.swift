/*
 * LoadOption.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public extension FirmwareVariables {
        func loadOptionData(_ bootNumber: BootNumber) -> Data? {
                return dataValue(forGlobalVariable: bootNumber.variableName)
        }
}
        
public struct LoadOption {
        private(set) public var bootNumber: BootNumber = 0xFFFF
        
        private var attributes: UInt32
        private var descriptionData: Data
        public var optionalData = OptionalData()

        private let devicePathListData: Data?
        
        public let devicePathList: DevicePathList?
        
        public var isClover: Bool {
                guard let loaderPath = devicePathList?.filePath else {
                        return false
                }
                return loaderPath.lowercased().contains("cloverx64.efi") ? true : false
        }

        public func data() throws -> Data {
                guard let devicePathListData = devicePathListData ?? devicePathList?.data else {
                        throw BootoptionError.foundNil(id: "devicePathListData", Location())
                }
                
                let devicePathListLengthData = UInt16(devicePathListData.count).toData()
                
                var buffer = Data.init()
                
                buffer.append(attributes.toData())
                buffer.append(devicePathListLengthData)
                buffer.append(descriptionData)
                buffer.append(devicePathListData)
                
                if let optionalData = self.optionalData.data {
                        buffer.append(optionalData)
                }
                
                return buffer
        }
        
        public var active: Bool {
                get {
                        return attributes & 0x1 == 0x1 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x1
                        }
                        if newValue == false {
                                attributes = attributes & 0xFFFFFFFE
                        }
                }
        }
        
        public var hidden: Bool {
                get {
                        return attributes & 0x8 == 0x8 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x8
                        }
                        if newValue == false {
                                attributes = attributes & 0xFFFFFFF7
                        }
                }
        }
        
        public var description: String {
                get {
                        if descriptionData.count == 0 {
                                return ""
                        }
                        guard let descriptionString = descriptionData.efiStringValue else {
                                fatalError("descriptionString should not be nil")
                        }
                        return descriptionString
                }
                set {
                        guard let newData = newValue.toUCS2Data() else {
                                fatalError("newData should not be nil")
                        }
                        descriptionData = newData
                }
        }
        
        public init?(fromBootNumber number: BootNumber, details: Bool = false) throws {
                try self.init(number: number, data: nil, details: details)
        }
        
        public init?(fromData data: Data, details: Bool = false) throws {
                try self.init(number: nil, data: data, details: details)
        }
        
        /* Init from boot number / NVRAM */
        private init?(number: BootNumber?, data: Data?, details: Bool = false) throws {
                
                var buffer: Data
                
                switch (number, data) {
                case (.none, .none):
                        return nil
                case (.some, .some):
                        bootNumber = number!
                        buffer = data!
                case (.some, .none):
                        bootNumber = number!
                        if let optionData = FirmwareVariables.default.loadOptionData(number!) {
                                buffer = optionData
                        } else {
                                return nil
                        }
                case (.none, .some):
                        bootNumber = 0xFFFF
                        buffer = data!
                }
                
                /* Attributes */
                attributes = buffer.remove32()
                
                /* Device path list length */
                let devicePathListLength = Int(buffer.remove16())
                
                /* Description */
                descriptionData = Data()
                for _ in buffer {
                        let char = buffer.removeData(bytes: MemoryLayout<UInt16>.size)
                        descriptionData.append(char)
                        if char.toUInt16() == 0x0000 {
                                break
                        }
                }
                
                if details {
                        /* Device path list */
                        devicePathListData = buffer.removeData(bytes: devicePathListLength)
                        devicePathList = try DevicePathList(data: devicePathListData!)
                        
                        /* Optional data */
                        if !buffer.isEmpty {
                                optionalData.data = buffer
                        }
                } else {
                        devicePathListData = nil
                        devicePathList = nil
                }
        }
        
        /* Init create from local filesystem path */
        public init(loaderPath: String, description descriptionString: String, optionalData: Any?, useUCS2: Bool = false) throws {
                Debug.log("Initializing EfiLoadOption from loader filesystem path", type: .info)
                
                devicePathListData = nil
                
                /* Device path list */
                let loader = try LoaderManager.default.getLoader(path: loaderPath)
                let hardDriveDP = try HardDriveDevicePath(loader: loader)
                let filePathDP = try FilePathDevicePath(loader: loader)
                devicePathList = try DevicePathList(hardDriveDevicePath: hardDriveDP, filePathDevicePath: filePathDP)

                /* Attributes */
                attributes = 1
                Debug.log("Creating option from filesystem path with attributes: %@", type: .info, argsList: String(attributes, radix: 2).leftPadding(toLength: 32, withPad: "0"))
                
                
                /* Description */
                guard let descriptionData = descriptionString.toUCS2Data() else {
                        throw BootoptionError.internal(message: "descriptionString.toUCS2Data() unexpectedly returned nil", Location())
                }
                
                guard descriptionData.count > 1 else {
                        throw BootoptionError.internal(message: "the option description should not be an empty string", Location())
                }
                
                self.descriptionData = descriptionData
                
                Debug.log("Description string: '%@', data: %@", type: .info, argsList: descriptionString, descriptionData)
                
                /* Optional data */
                switch optionalData {
                case let string as String:
                        try self.optionalData.set(string: string, isClover: isClover, useUCS2: useUCS2)
                        Debug.log("Optional data initialized from string", type: .info)
                case let data as Data:
                        self.optionalData.data = data
                        Debug.log("Optional data initialized from data", type: .info)
                default:
                        Debug.log("Not generating optional data", type: .info)
                }
                
                Debug.log("LoadOption initialized from loader filesystem path", type: .info)
        }
}
