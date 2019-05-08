/*
 * LoadOption.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
        
public struct LoadOption {
        private(set) public var bootNumber: BootNumber = 0xFFFF        
        public var attributes: LoadOptionAttributes
        public var description: LoadOptionDescription
        public var optionalData: LoadOptionOptionalData?
        public var devicePathList: DevicePathList?
        
        public var isClover: Bool {
                guard let loaderPath = devicePathList?.filePath else {
                        return false
                }
                return loaderPath.lowercased().contains("cloverx64.efi")
        }

        public func data() throws -> Data {
                guard let dpList = devicePathList?.data else {
                        throw BootoptionError.foundNil(description: "device path list data", file: #file, function: #function)
                }
                
                guard let optionalData = optionalData?.data else {
                        throw BootoptionError.foundNil(description: "optional data", file: #file, function: #function)
                }
                
                let attributes = self.attributes.data
                let dpListLength = UInt16(dpList.count).toData()
                let description = self.description.data
                
                return attributes + dpListLength + description + dpList + optionalData
        }
        
        public init(fromBootNumber number: BootNumber, details: Bool = false) throws {
                try self.init(number: number, data: nil, details: details)
        }
        
        public init(fromData data: Data, details: Bool = false) throws {
                try self.init(number: nil, data: data, details: details)
        }
        
        /* from boot number or data */
        private init(number: BootNumber?, data: Data?, details: Bool = false) throws {                
                var buffer: Data
                
                switch (number, data) {
                case (.none, .none):
                        fatalError()
                case (.some, .some):
                        bootNumber = number!
                        buffer = data!
                case (.some, .none):
                        bootNumber = number!
                        if let optionData = FirmwareVariables.default.dataValue(forGlobalVariable: bootNumber.variableName) {
                                buffer = optionData
                        } else {
                                throw FirmwareVariablesError.notFound(variable: number!.variableName)
                        }
                case (.none, .some):
                        bootNumber = BootNumber(0xFFFF)
                        buffer = data!
                }
                
                /* Attributes */
                attributes = LoadOptionAttributes(buffer.remove32())
                
                /* Device path list length */
                let devicePathListLength = Int(buffer.remove16())
                
                /* Description */
                var descriptionData = Data()
                for _ in buffer {
                        let unichar: UInt16 = buffer.remove()
                        descriptionData.append(unichar)
                        if unichar == 0 {
                                break
                        }
                }
                description = LoadOptionDescription(data: descriptionData)
                
                if details {
                        /* Device path list */
                        devicePathList = try DevicePathList(data: Buffer(buffer.remove(count: devicePathListLength)))
                        
                        /* Optional data */
                        optionalData = LoadOptionOptionalData(data: buffer)

                }
        }
        
        /* from loader path */
        public init(loaderPath: String, description descriptionString: String, optionalData: Any?, useUCS2: Bool = false) throws {
                Debug.log("Initializing EfiLoadOption from loader filesystem path", type: .info)
               
                /* Device path list */
                let loader = try LoaderFactory.default.makeLoader(path: loaderPath)
                let hardDriveDP = try MEDIA_HARD_DRIVE_DP(loader: loader)
                let filePathDP = try MEDIA_FILEPATH_DP(loader: loader)
                devicePathList = try DevicePathList(hardDriveDevicePath: hardDriveDP, filePathDevicePath: filePathDP)

                /* Attributes */
                attributes = LoadOptionAttributes()
                Debug.log("Creating option from filesystem path with attributes: %@", type: .info, argsList: String(attributes.intValue, radix: 2).leftPadding(toLength: 32, withPad: "0"))
                
                
                /* Description */
                guard let descriptionData = descriptionString.toUCS2Data() else {
                        throw BootoptionError.internal(errorMessage: "descriptionString.toUCS2Data() unexpectedly returned nil", file: #file, function: #function)
                }
                
                guard descriptionData.count > 1 else {
                        throw BootoptionError.internal(errorMessage: "the option description should not be an empty string", file: #file, function: #function)
                }
                
                description = LoadOptionDescription(data: descriptionData)
                
                Debug.log("Description string: '%@', data: %@", type: .info, argsList: descriptionString, descriptionData)
                
                /* Optional data */
                switch optionalData {
                case let string as String:
                        self.optionalData = try LoadOptionOptionalData(string: string, isClover: isClover, useUCS2: useUCS2)
                        Debug.log("Optional data: initialized from string", type: .info)
                case let data as Data:
                        self.optionalData = LoadOptionOptionalData(data: data)
                        Debug.log("Optional data: initialized from data", type: .info)
                default:
                        self.optionalData = LoadOptionOptionalData()
                        Debug.log("Not initializing optional data", type: .info)
                }
                
                Debug.log("LoadOption initialized from loader filesystem path", type: .info)
        }
}
