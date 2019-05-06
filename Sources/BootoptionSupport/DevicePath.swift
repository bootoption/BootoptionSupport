/*
 * DevicePath.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

open class DevicePath: DevicePathProtocol {
        public var devicePathType: DevicePathTypeProtocol
        public var devicePathData: Data
        
        open var descriptionStrings: [String] {
                switch type {
                case DevicePathType.rawValue.hardware:
                        return ["Hw", subType.string, devicePathData.hexString]
                case DevicePathType.rawValue.acpi:
                        return ["Acpi", subType.string, devicePathData.hexString]
                case DevicePathType.rawValue.messaging:
                        return ["Msg", subType.string, devicePathData.hexString]
                case DevicePathType.rawValue.media:
                        return ["Media", subType.string, devicePathData.hexString]
                case DevicePathType.rawValue.bbs:
                        return ["BBS", subType.string, devicePathData.hexString]
                case DevicePathType.rawValue.end:
                        return ["End", subType.hexString]
                default:
                        return [type.string, subType.string, devicePathData.hexString]
                }
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                devicePathType = type
                devicePathData = buffer.data
                Debug.log("%@ (%@:%@) initialized, description: %@", type: .info, argsList: Swift.type(of: self), self.type, subType, description)
        }
        
        public init(type: DevicePathTypeProtocol, data: Data?) {
                devicePathType = type
                devicePathData = data ?? Data()
                Debug.log("%@ (%@:%@) initialized, description: %@", type: .info, argsList: Swift.type(of: self), self.type, subType, description)
        }
}

public class HW_PCI_DP: DevicePath {
        private let function: UInt8
        private let device: UInt8
        
        override public var descriptionStrings: [String] {
                return ["Pci", device.hexString + ":" + function.shortHexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                function = buffer.read()
                device = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class HW_VENDOR_DP: DevicePath {
        private let vendorGUID: MicrosoftGUID?
        private let vendorData: Data
        
        override public var descriptionStrings: [String] {
                guard let vendorGUID = vendorGUID else {
                        return ["VenHw", devicePathData.hexString]
                }
                
                switch vendorGUID.uuidString {
                case "2D6447EF-3BC9-41A0-AC19-4D51D01B4CE6":
                        return ["VenHw", vendorGUID.uuidString, String(UCS2Data: vendorData)?.quoted ?? vendorData.hexString]
                default:
                        return ["VenHw", vendorGUID.uuidString, vendorData.hexString]
                }
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                vendorGUID = buffer.read()
                vendorData = buffer.readRemaining()
                super.init(type: type, data: buffer.data)
        }
}

public class ACPI_DP: DevicePath {
        private let hardwareID: UInt32
        private let uniqueID: UInt32

        override public var descriptionStrings: [String] {
                guard let id = hardwareID.eisaPnpID else {
                        return ["Acpi", hardwareID.hexString, uniqueID.string]
                }
                switch id {
                case "PNP0A03":
                        return ["PciBus", uniqueID.string]
                default:
                        return [id, uniqueID.string]
                }
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                hardwareID = buffer.read()
                uniqueID = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class ACPI_EXTENDED_DP: DevicePath {
        private let hardwareID: UInt32
        private let uniqueID: UInt32
        private let compatibleID: UInt32
        private let hardwareIDStringData: Data
        
        var hardwareIDString: String? {
                guard let string = String(data: hardwareIDStringData, encoding: .ascii)?.replacingOccurrences(of: "\0", with: "") else {
                        return nil
                }
                
                return string.count > 0 ? string : nil
        }
        
        override public var descriptionStrings: [String] {
                let hid = hardwareID.eisaPnpID
                let cid = compatibleID.eisaPnpID
                return ["AcpiEx", hardwareIDString ?? hid ?? hardwareID.hexString, cid ?? compatibleID.hexString, uniqueID.string]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                hardwareID = buffer.read()
                uniqueID = buffer.read()
                compatibleID = buffer.read()
                hardwareIDStringData = buffer.readRemaining()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_USB_DP: DevicePath {
        private let port: UInt8
        private let interface: UInt8
        
        override public var descriptionStrings: [String] {
                return ["Usb", port.shortHexString, interface.shortHexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                port = buffer.read()
                interface = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_MAC_ADDR_DP: DevicePath {
        private let address: Data
        private let interfaceType: UInt8
        
        public var macAddressString: String? {
                let r = address.subdata(in: Range(6...7)).toUInt16() == 0 ? Range(0...5) : Range(0...7)
                return [UInt8](address.subdata(in: r)).map { String(format: "%02X", $0) }.joined(separator: ":")
        }
        
        override public var descriptionStrings: [String] {
                guard let string = macAddressString else {
                        return ["MAC", address.hexString, interfaceType.shortHexString]
                }
                return ["MAC", string, interfaceType.shortHexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                address = buffer.read(count: 32)
                interfaceType = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_IPv4_DP: DevicePath {
        override public var descriptionStrings: [String] {
                return ["IPv4", devicePathData.hexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_IPv6_DP: DevicePath {
        override public var descriptionStrings: [String] {
                return ["IPv6", devicePathData.hexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_USB_CLASS_DP: DevicePath {
        private let vendorID: UInt16
        private let productID: UInt16
        private let deviceClass: UInt8
        private let deviceSubClass: UInt8
        private let deviceProtocol: UInt8
        
        override public var descriptionStrings: [String] {
                return ["UsbClass", vendorID.hexString, productID.hexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                vendorID = buffer.read()
                productID = buffer.read()
                deviceClass = buffer.read()
                deviceSubClass = buffer.read()
                deviceProtocol = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_USB_WWID_DP: DevicePath {
        private let maxSerialLength = MemoryLayout<UInt16>.size * 64
        private let interface: UInt16
        private let vendorID: UInt16
        private let productID: UInt16
        private let serialNumber: Data
        
        override public var descriptionStrings: [String] {
                let serialString: String = String(UCS2Data: serialNumber) ?? "nil"
                return ["UsbWwid", serialString.quoted, vendorID.hexString, productID.hexString, interface.shortHexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                interface = buffer.read()
                vendorID = buffer.read()
                productID = buffer.read()
                serialNumber = buffer.readRemaining()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_DEVICE_LOGICAL_UNIT_DP: DevicePath {
        private let logicalUnitNumber: UInt8
        
        override public var descriptionStrings: [String] {
                return ["Unit", logicalUnitNumber.string]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                logicalUnitNumber = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_SATA_DP: DevicePath {
        private let hardwarePortNumber: UInt16
        private let portMultiplierPortNumber: UInt16
        private let logicalUnitNumber: UInt16
        
        override public var descriptionStrings: [String] {
                let port = hardwarePortNumber.shortHexString
                let multiplier = portMultiplierPortNumber.hexString
                let unit = logicalUnitNumber.shortHexString
                return ["Sata", port, multiplier, unit]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                hardwarePortNumber = buffer.read()
                portMultiplierPortNumber = buffer.read()
                logicalUnitNumber = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MSG_NVME_NAMESPACE_DP: DevicePath {
        private let namespaceID: UInt32
        private let extendedUniqueID: UInt64
        
        override public var descriptionStrings: [String] {
                return ["NVMe", namespaceID.shortHexString, extendedUniqueID.hexString]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                namespaceID = buffer.read()
                extendedUniqueID = buffer.read()
                super.init(type: type, data: buffer.data)
        }
}

public class MEDIA_HARD_DRIVE_DP: DevicePath {
        private let partitionStart: UInt64
        private let partitionSize: UInt64
        private let partitionFormat: UInt8
        
        public let partitionNumber: UInt32
        public let signature: HardDriveDevicePathSignature
        
        override public var descriptionStrings: [String] {
                if let uuid = signature.UUID?.uuidString {
                        return ["HD", partitionNumber.string, "GPT", uuid, partitionStart.shortHexString, partitionSize.shortHexString]
                } else if let mbrSignature = signature.MBR {
                        return ["HD", partitionNumber.string, "MBR", mbrSignature.hexString, partitionStart.shortHexString, partitionSize.shortHexString]
                } else {
                        return ["HD", devicePathData.hexString]
                }
        }
        
        /* Init from device path data */
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                Debug.log("Initializing %@ from device path data...", type: .info, argsList: Swift.type(of: self))
                Debug.log("Data: %@", type: .info, argsList: buffer.data)
                let signatureBytes: Data
                let signatureType: UInt8
                
                partitionNumber = buffer.read()
                Debug.log("Partition Number: %@", type: .info, argsList: partitionNumber)
                partitionStart = buffer.read()
                Debug.log("Partition Start: %@", type: .info, argsList: partitionStart)
                partitionSize = buffer.read()
                Debug.log("Partition Size: %@", type: .info, argsList: partitionSize)
                signatureBytes = buffer.read(count: 16)
                Debug.log("Partition Signature: %@", type: .info, argsList: signatureBytes)
                partitionFormat = buffer.read()
                Debug.log("Partition Format: %@", type: .info, argsList: partitionFormat)
                signatureType = buffer.read()
                Debug.log("Signature Type: %@", type: .info, argsList: signatureType)
                
                guard let signature = HardDriveDevicePathSignature(type: HardDriveDevicePathSignature.SignatureType(rawValue: signatureType), data: signatureBytes) else {
                        throw BootoptionError.internal(errorMessage: "HardDriveDevicePathSignature(type: \(signatureType) data: \(signatureBytes.hexString)) initialization failed", file: #file, function: #function)
                }
                
                self.signature = signature
                
                guard buffer.remaining == 0 else {
                        throw BootoptionError.internal(errorMessage: "buffer remaining not zero after parsing hard drive device path", file: #file, function: #function)
                }
               
                super.init(type: type, data: buffer.data)
        }
        
        /* Init from loader path */
        
        public init(loader: Loader) throws {
                let loaderPath = loader.path
                Debug.log("Initializing %@ from Loader with path: %@", type: .info, argsList: Swift.type(of: self), loaderPath)
                
                partitionFormat = loader.partitionFormat.rawValue

                guard let signature = HardDriveDevicePathSignature(loader: loader) else {
                        throw BootoptionError.internal(errorMessage: "HardDriveDevicePathSignature(loader:) initialization failed", file: #file, function: #function)
                }
                
                self.signature = signature
                
                Debug.log("Partition Format: %@", type: .info, argsList: partitionFormat)
                Debug.log("Partition Signature Type: %@", type: .info, argsList: signature.type)
                Debug.log("Partition Signature: %@", type: .info, argsList: signature.data)
                
                guard let blockSize = loader.ioMedia.createCFProperty(forKey: kIOMediaPreferredBlockSizeKey) as? Int else {
                        throw BootoptionError.internal(errorMessage: "failed to get IOMedia value for key '\(kIOMediaPreferredBlockSizeKey)'", file: #file, function: #function)
                }
                
                Debug.log("Preferred Block Size: %@", type: .info, argsList: blockSize)
                
                if let partId = loader.ioMedia.createCFProperty(forKey: kIOMediaPartitionIDKey) as? Int {
                        Debug.log("Partition ID: %@", type: .info, argsList: partId)
                        partitionNumber = UInt32(partId)
                } else {
                        throw BootoptionError.internal(errorMessage: "failed to get IOMedia value for key '\(kIOMediaPartitionIDKey)'", file: #file, function: #function)
                }
                
                if let base = loader.ioMedia.createCFProperty(forKey: kIOMediaBaseKey) as? Int {
                        partitionStart = UInt64(base / blockSize)
                        Debug.log("Base: %@", type: .info, argsList: partitionStart)
                } else {
                        throw BootoptionError.internal(errorMessage: "failed to get IOMedia value for key '\(kIOMediaBaseKey)'", file: #file, function: #function)
                }
                
                if let size = loader.ioMedia.createCFProperty(forKey: kIOMediaSizeKey) as? Int {
                        Debug.log("Size: %@", type: .info, argsList: size)
                        partitionSize = UInt64(size / blockSize)
                } else {
                        throw BootoptionError.internal(errorMessage: "failed to get IOMedia value for key '\(kIOMediaSizeKey)'", file: #file, function: #function)
                }
                
                var data = Data()
                data.append(partitionNumber)
                data.append(partitionStart)
                data.append(partitionSize)
                data.append(signature.data)
                data.append(partitionFormat)
                data.append(signature.type)
                
                super.init(type: DevicePathType.media(.MEDIA_HARDDRIVE_DP), data: data)
        }
}

public class MEDIA_VENDOR_DP: DevicePath {
        private let vendorGUID: MicrosoftGUID?
        private let vendorData: Data
        
        override public var descriptionStrings: [String] {
                if let vendorGUID = vendorGUID {
                        return ["VenMedia", vendorGUID.uuidString, vendorData.hexString]
                } else {
                        return ["VenMedia", devicePathData.hexString]
                }
        }
        
        let appleAPFSVendorGUID = MicrosoftGUID(
                bytes: [0xf7, 0xfc, 0x74, 0xbe, 0x7c, 0x0b, 0xf3, 0x49, 0x91, 0x47, 0x01, 0xf4, 0x04, 0x2e, 0x68, 0x42]
        )
        
        public var appleAPFSVolumeUUID: MicrosoftGUID? {
                guard vendorGUID == appleAPFSVendorGUID else {
                        return nil
                }
                guard vendorData.count == 16 else {
                        return nil
                }
                return MicrosoftGUID(data: vendorData)
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                vendorGUID = buffer.read()
                vendorData = buffer.readRemaining()
                super.init(type: type, data: buffer.data)
        }
}

public class MEDIA_FILEPATH_DP: DevicePath {
        public var pathString: String {
                guard let path = String(UCS2Data: devicePathData) else {
                        fatalError("String(UCSData:) should not return nil here")
                }
                return path
        }
        
        override public var descriptionStrings: [String] {
                return ["File", pathString.quoted]
        }
        
        required public init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws {
                super.init(type: type, data: buffer.data)
        }
        
        /* Init from loader path */
        
        public init(loader: Loader) throws {
                Debug.log("Initializing %@ from Loader with path: %@", type: .info, argsList: Swift.type(of: self), loader.path)
                
                guard let data = loader.filesystemPath.toUCS2Data() else {
                        throw BootoptionError.internal(errorMessage: "failed to initialize file device path data", file: #file, function: #function)
                }
                
                super.init(type: DevicePathType.media(.MEDIA_FILEPATH_DP), data: data)
        }
}
