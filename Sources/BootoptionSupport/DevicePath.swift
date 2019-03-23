/*
 * DevicePath.swift
 * Copyright © 1998 Intel Corporation
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit.storage

fileprivate func format(_ title: String, _ fields: String...) -> String {
        return title + "(" + fields.joined(separator: ",") + ")"
}

fileprivate func eisaPnpID(_ efiPnpID: UInt32) -> String? {
        var buffer = efiPnpID.toData()
        switch buffer.remove16() {
        case 0x41d0:
                let id = buffer.remove16()
                return "PNP" + String(format: "%04X", id)
        default:
                return nil
        }
}

fileprivate func readMBRSignature(bsdName: String) throws -> UInt32 {
        var signature: UInt32
        let file = "/dev/\(bsdName)"
        guard let fileHandle = FileHandle.init(forReadingAtPath: file) else {
                throw BootoptionError.file(message: "couldn't open file for reading at path '\(file)'")
        }
        let offset: UInt64 = 0x1B8
        Debug.log("Seek to file offset %@, %@", type: .info, argsList: offset.shortHexString, file)
        fileHandle.seek(toFileOffset: offset)
        let bytesToRead = 4
        Debug.log("Read %@ bytes", type: .info, argsList: bytesToRead)
        signature = fileHandle.readData(ofLength: bytesToRead).toUInt32()
        Debug.log("UInt32 value: %@", type: .info, argsList: signature.hexString)
        fileHandle.closeFile()
        return signature
}

fileprivate extension String {
        var quoted: String {
                return "\"" + self + "\""
        }
}

public enum DevicePathType: UInt8 {
        case HARDWARE_DEVICE_PATH = 1
        case ACPI_DEVICE_PATH = 2
        case MESSAGING_DEVICE_PATH = 3
        case MEDIA_DEVICE_PATH = 4
        case BBS_DEVICE_PATH = 5
        case END_DEVICE_PATH_TYPE = 0x7f
}

public struct DevicePathNode {
        public enum Hardware: UInt8 {
                case HW_PCI_DP = 1
                case HW_PCCARD_DP = 2
                case HW_MEMMAP_DP = 3
                case HW_VENDOR_DP = 4
                case HW_CONTROLLER_DP = 5
                case HW_BMC_DP = 6
        }
        
        public enum Acpi: UInt8 {
                case ACPI_DP = 1
                case ACPI_EXTENDED_DP = 2
                case ACPI_ADR_DP = 3
        }
        
        public enum Messaging: UInt8 {
                case MSG_ATAPI_DP = 1
                case MSG_SCSI_DP = 2
                case MSG_FIBRECHANNEL_DP = 3
                case MSG_1394_DP = 4
                case MSG_USB_DP = 5
                case MSG_I2O_DP = 6
                case MSG_INFINIBAND_DP = 9
                case MSG_VENDOR_DP = 10
                case MSG_MAC_ADDR_DP = 11
                case MSG_IPv4_DP = 12
                case MSG_IPv6_DP = 13
                case MSG_UART_DP = 14
                case MSG_USB_CLASS_DP = 15
                case MSG_USB_WWID_DP = 16
                case MSG_DEVICE_LOGICAL_UNIT_DP = 17
                case MSG_SATA_DP = 18
                case MSG_ISCSI_DP = 19
                case MSG_VLAN_DP = 20
                case MSG_FIBRECHANNELEX_DP = 21
                case MSG_SASEX_DP = 22
                case MSG_NVME_NAMESPACE_DP = 23
                case MSG_URI_DP = 24
                case MSG_UFS_DP = 25
                case MSG_SD_DP = 26
                case MSG_BLUETOOTH_DP = 27
                case MSG_WIFI_DP = 28
                case MSG_EMMC_DP = 29
                case MSG_BLUETOOTH_LE_DP = 30
                case MSG_DNS_DP = 31
        }
        
        public enum Media: UInt8 {
                case MEDIA_HARDDRIVE_DP = 1
                case MEDIA_CDROM_DP = 2
                case MEDIA_VENDOR_DP = 3
                case MEDIA_FILEPATH_DP = 4
                case MEDIA_PROTOCOL_DP = 5
                case MEDIA_PIWG_FW_FILE_DP = 6
                case MEDIA_PIWG_FW_VOL_DP = 7
                case MEDIA_RELATIVE_OFFSET_RANGE_DP = 8
                case MEDIA_RAM_DISK_DP = 9
        }
        
        public enum End: UInt8 {
                case END_INSTANCE_DEVICE_PATH_SUBTYPE = 1
                case END_ENTIRE_DEVICE_PATH_SUBTYPE = 0xff
        }
}

fileprivate let AppleAPFSVolumeGUID = MicrosoftGUID(
        bytes: [0xf7, 0xfc, 0x74, 0xbe, 0x7c, 0x0b, 0xf3, 0x49, 0x91, 0x47, 0x01, 0xf4, 0x04, 0x2e, 0x68, 0x42]
)

public typealias DevicePathHeader = (UInt8, UInt8, UInt16)

open class DevicePath {
        public let type: UInt8
        public let subType: UInt8
        public var length: UInt16 {
                return UInt16(devicePath.count + MemoryLayout<DevicePathHeader>.size)
        }
        public var header: DevicePathHeader {
                return (type, subType, length)
        }
        public let devicePath: Data
        public var data: Data {
                var buffer = Data()
                buffer.append(type.toData())
                buffer.append(subType.toData())
                buffer.append(length.toData())
                buffer.append(devicePath)
                return buffer
        }
        
        open var description: String {
                switch type {
                case DevicePathType.HARDWARE_DEVICE_PATH.rawValue:
                        return format("Hw", subType.string, devicePath.hexString)
                case DevicePathType.ACPI_DEVICE_PATH.rawValue:
                        return format("Acpi", subType.string, devicePath.hexString)
                case DevicePathType.MESSAGING_DEVICE_PATH.rawValue:
                        return format("Msg", subType.string, devicePath.hexString)
                case DevicePathType.MEDIA_DEVICE_PATH.rawValue:
                        return format("Media", subType.string, devicePath.hexString)
                case DevicePathType.BBS_DEVICE_PATH.rawValue:
                        return format("Bios", subType.string, devicePath.hexString)
                case DevicePathType.END_DEVICE_PATH_TYPE.rawValue:
                        return format("End", subType.hexString)
                default:
                        return format(type.string, subType.string, devicePath.hexString)
                }
        }
        
        public init(type: UInt8, subType: UInt8, devicePath: Data) throws {
                self.type = type
                self.subType = subType
                self.devicePath = devicePath
                Debug.log("%@ (%@:%@) initialized, description: %@", type: .info, argsList: Swift.type(of: self), type, subType, description)
        }
}

public class PciDevicePath: DevicePath {
        private let function: UInt8
        private let device: UInt8
        
        override public var description: String {
                let function = String(format: "%X", self.function)
                return format("Pci", device.hexString + ":" + function)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                function = buffer.remove8()
                device = buffer.remove8()
                try super.init(type: DevicePathType.HARDWARE_DEVICE_PATH.rawValue, subType: DevicePathNode.Hardware.HW_PCI_DP.rawValue, devicePath: devicePath) // 1
        }
}

public class VendorHardwareDevicePath: DevicePath {
        private let vendorGUID: MicrosoftGUID?
        private let vendorData: Data
        
        override public var description: String {
                if let vendorGUID = vendorGUID {
                        switch vendorGUID.uuidString {
                        case "2D6447EF-3BC9-41A0-AC19-4D51D01B4CE6":
                                return format("VenHw", vendorGUID.uuidString, vendorData.efiStringValue?.quoted ?? vendorData.hexString)
                        default:
                                return format("VenHw", vendorGUID.uuidString, vendorData.hexString)
                        }
                } else {
                        return format("VenHw", devicePath.hexString)
                }
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                let uuid = buffer.removeData(bytes: 16)
                vendorGUID = MicrosoftGUID(data: uuid)
                vendorData = buffer
                try super.init(type: DevicePathType.HARDWARE_DEVICE_PATH.rawValue, subType: DevicePathNode.Hardware.HW_VENDOR_DP.rawValue, devicePath: devicePath)
        }
}

public class AcpiDevicePath: DevicePath {
        private let hardwareID: UInt32
        private let uniqueID: UInt32

        override public var description: String {
                if let id = eisaPnpID(hardwareID) {
                        switch id {
                        case "PNP0A03":
                                return format("PciBus", uniqueID.string)
                        default:
                                return format("Acpi", id, uniqueID.string)
                        }
                } else {
                        return format("Acpi", hardwareID.hexString, uniqueID.string)
                }
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                hardwareID = buffer.remove32()
                uniqueID = buffer.remove32()
                try super.init(type: DevicePathType.ACPI_DEVICE_PATH.rawValue, subType: DevicePathNode.Acpi.ACPI_DP.rawValue, devicePath: devicePath)
        }
}

public class AcpiExtendedDevicePath: DevicePath {
        private let hardwareID: UInt32
        private let uniqueID: UInt32
        private let compatibleID: UInt32
        private var hardwareIDString: String?
        
        override public var description: String {
                let hid = eisaPnpID(hardwareID)
                let cid = eisaPnpID(compatibleID)
                return format("Acpi", hardwareIDString ?? hid ?? hardwareID.hexString, cid ?? compatibleID.hexString, uniqueID.string)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                hardwareID = buffer.remove32()
                uniqueID = buffer.remove32()
                compatibleID = buffer.remove32()
                let string = String(data: buffer, encoding: .ascii)?.replacingOccurrences(of: "\0", with: "")
                if string != nil, string!.count > 0 {
                        hardwareIDString = string
                }
                try super.init(type: DevicePathType.ACPI_DEVICE_PATH.rawValue, subType: DevicePathNode.Acpi.ACPI_EXTENDED_DP.rawValue, devicePath: devicePath)
        }
}

public class UsbDevicePath: DevicePath {
        private let port: UInt8
        private let interface: UInt8
        
        override public var description: String {
                return format("Usb", port.shortHexString, interface.shortHexString)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                port = buffer.remove8()
                interface = buffer.remove8()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_USB_DP.rawValue, devicePath: devicePath)
        }
}

public class MacAddressDevicePath: DevicePath {
        private let address: Data
        private let interfaceType: UInt8
        public var addressString: String? {
                if address.count < 8 {
                        return nil
                }
                var macData: Data
                switch address.subdata(in: Range(6...7)).toUInt32() {
                case 0x0000:
                        macData = address.subdata(in: Range(0...5))
                default:
                        macData = address.subdata(in: Range(0...7))
                }
                return [UInt8](macData).map { String(format: "%02X", $0) }.joined(separator: ":")
        }
        
        override public var description: String {
                if let string = addressString {
                        return format("Mac", string, interfaceType.shortHexString)
                } else {
                        return format("Mac", address.hexString, interfaceType.shortHexString)
                }
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                address = buffer.removeData(bytes: 32)
                interfaceType = buffer.remove8()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_MAC_ADDR_DP.rawValue, devicePath: devicePath)
        }
}

public class IPv4DevicePath: DevicePath {
        override public var description: String {
                return format("IPv4", devicePath.hexString)
        }
        
        public init(devicePath: Data) throws {
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_IPv4_DP.rawValue, devicePath: devicePath)
        }
}

public class IPv6DevicePath: DevicePath {
        override public var description: String {
                return format("IPv6", devicePath.hexString)
        }
        
        public init(devicePath: Data) throws {
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_IPv6_DP.rawValue, devicePath: devicePath)
        }
}

public class UsbClassDevicePath: DevicePath {
        private let vendorID: UInt16
        private let productID: UInt16
        private let deviceClass: UInt8
        private let deviceSubClass: UInt8
        private let deviceProtocol: UInt8
        
        override public var description: String {
                return format("Usb", vendorID.hexString, productID.hexString)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                vendorID = buffer.remove16()
                productID = buffer.remove16()
                deviceClass = buffer.remove8()
                deviceSubClass = buffer.remove8()
                deviceProtocol = buffer.remove8()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_USB_CLASS_DP.rawValue, devicePath: devicePath)
        }
}

public class UsbWwidDevicePath: DevicePath {
        private let maxSerialLength = MemoryLayout<UInt16>.size * 64
        private let interface: UInt16
        private let vendorID: UInt16
        private let productID: UInt16
        private let serialNumber: Data
        
        override public var description: String {
                let serialString: String = serialNumber.efiStringValue ?? "nil"
                return format("Usb", serialString.quoted, vendorID.hexString, productID.hexString, interface.shortHexString)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                interface = buffer.remove16()
                vendorID = buffer.remove16()
                productID = buffer.remove16()
                if buffer.count > maxSerialLength {
                        Debug.log("USB WWID serial number exceeds %@ bytes", type: .error, argsList: maxSerialLength)
                }
                serialNumber = buffer
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_USB_WWID_DP.rawValue, devicePath: devicePath)
        }
}

public class LogicalUnitNumberDevicePath: DevicePath {
        private let logicalUnitNumber: UInt8
        
        override public var description: String {
                return format("Lun", logicalUnitNumber.string)
        }
        
        public init(devicePath: Data) throws {
                logicalUnitNumber = devicePath.toUInt8()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_DEVICE_LOGICAL_UNIT_DP.rawValue, devicePath: devicePath)
        }
}

public class SataDevicePath: DevicePath {
        private let hardwarePortNumber: UInt16
        private let portMultiplierPortNumber: UInt16
        private let logicalUnitNumber: UInt16
        
        override public var description: String {
                let port = hardwarePortNumber.shortHexString
                let multiplier = portMultiplierPortNumber.hexString
                let unit = logicalUnitNumber.shortHexString
                return format("Sata", port, multiplier, unit)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                hardwarePortNumber = buffer.remove16()
                portMultiplierPortNumber = buffer.remove16()
                logicalUnitNumber = buffer.remove16()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_SATA_DP.rawValue, devicePath: devicePath)
        }
}

public class NvmeDevicePath: DevicePath {
        private let namespaceID: UInt32
        private let extendedUniqueID: UInt64
        
        override public var description: String {
                return format("Nvme", namespaceID.shortHexString, extendedUniqueID.hexString)
        }
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                namespaceID = buffer.remove32()
                extendedUniqueID = buffer.remove64()
                try super.init(type: DevicePathType.MESSAGING_DEVICE_PATH.rawValue, subType: DevicePathNode.Messaging.MSG_NVME_NAMESPACE_DP.rawValue, devicePath: devicePath)
        }
}

public class HardDriveDevicePath: DevicePath {
        public let partitionNumber: UInt32
        private(set) public var partitionUUID: MicrosoftGUID?
        private(set) public var masterBootSignature: UInt32?
        private(set) public var mountPoint: String?
        
        private let partitionStart: UInt64
        private let partitionSize: UInt64
        private let partitionFormat: UInt8
        private let signatureType: UInt8
        
        private var partitionSignature = Data.init(capacity: 16)
        
        override public var description: String {
                if let uuid = partitionUUID?.uuidString {
                        return format("Hd", partitionNumber.string, "GPT", uuid, partitionStart.shortHexString, partitionSize.shortHexString)
                } else if let mbrSignature = masterBootSignature {
                        return format("Hd", partitionNumber.string, "MBR", mbrSignature.hexString, partitionStart.shortHexString, partitionSize.shortHexString)
                } else {
                        return format("Hd", devicePath.hexString)
                }
        }
        
        /* Init from device path data */
        
        public init(devicePath: Data) throws {
                Debug.log("Initializing %@ from device path data...", type: .info, argsList: Swift.type(of: self))
                Debug.log("Data: %@", type: .info, argsList: devicePath)
                
                var buffer: Data = devicePath
                partitionNumber = buffer.remove32()
                Debug.log("Partition Number: %@", type: .info, argsList: partitionNumber)
                partitionStart = buffer.remove64()
                Debug.log("Partition Start: %@", type: .info, argsList: partitionStart)
                partitionSize = buffer.remove64()
                Debug.log("Partition Size: %@", type: .info, argsList: partitionSize)
                partitionSignature = buffer.removeData(bytes: 16)
                Debug.log("Partition Signature: %@", type: .info, argsList: partitionSignature)
                partitionFormat = buffer.remove8()
                Debug.log("Partition Format: %@", type: .info, argsList: partitionFormat)
                signatureType = buffer.remove8()
                Debug.log("Signature Type: %@", type: .info, argsList: signatureType)
                if !buffer.isEmpty {
                        throw BootoptionError.devicePath(message: "buffer not empty after parsing hard drive device path", Location())
                }
                
                switch (partitionFormat, signatureType) {
                case (1,1):
                        masterBootSignature = partitionSignature.subdata(in: Range(0...3)).toUInt32()
                        if let signature = masterBootSignature {
                                Debug.log("MBR Signature: %@", type: .info, argsList: signature.hexString)
                        }
                case (2,2):
                        partitionUUID = MicrosoftGUID(data: partitionSignature)
                        Debug.log("UUID: %@", type: .info, argsList: String(partitionUUID?.uuidString ?? "nil"))
                default:
                        break
                }
                
                try super.init(type: DevicePathType.MEDIA_DEVICE_PATH.rawValue, subType: DevicePathNode.Media.MEDIA_HARDDRIVE_DP.rawValue, devicePath: devicePath)
        }
        
        /* Init from loader path */
        
        public init(loader: Loader) throws {
                let loaderPath = loader.path
                Debug.log("Initializing %@ from path: %@", type: .info, argsList: Swift.type(of: self), loaderPath)
                switch loader.partitionScheme {
                case .FDisk:
                        partitionFormat = 1 /* PC-AT compatible legacy MBR */
                        signatureType = 1 /* 32-bit signature from address 0x1b8 of the type 0x01 MBR */
                        guard let bsdName = loader.ioMediaWhole.createCFProperty(forKey: kIOBSDNameKey) as? String else {
                                throw BootoptionError.devicePath(message: "failed to obtain whole disk's BSD name", Location())
                        }
                        Debug.log("Whole BSD Name: %@", type: .info, argsList: bsdName)
                        let signature = try readMBRSignature(bsdName: bsdName)
                        masterBootSignature = signature
                        if signature == 0 {
                                Debug.log("MBR signature is zero, deterministic boot is not guaranteed", type: .warning)
                        }
                        partitionSignature = signature.toData() + Data([UInt8](repeating: 0x00, count: 12))
                case .GUID:
                        partitionFormat = 2 /* GPT */
                        signatureType = 2 /* GUID signature */
                        guard let ioUUIDString = loader.ioMedia.createCFProperty(forKey: kIOMediaUUIDKey) as? String else {
                                throw BootoptionError.devicePath(message: "failed to get IOMedia UUID", Location())
                        }
                        Debug.log("UUID: %@", type: .info, argsList: ioUUIDString)
                        if let uuid = UUID(uuidString: ioUUIDString) {
                                partitionUUID = MicrosoftGUID(uuid: uuid)
                                partitionSignature = partitionUUID!.data()
                        } else {
                                throw BootoptionError.devicePath(message: "failed to initialize partition UUID from string", Location())
                        }
                }
                let count = partitionSignature.count
                guard count == 16 else {
                        throw BootoptionError.devicePath(message: "partition signature is \(count) bytes, should be 16", Location())
                }
                Debug.log("Partition Format: %@", type: .info, argsList: partitionFormat)
                Debug.log("Partition Signature Type: %@", type: .info, argsList: signatureType)
                Debug.log("Partition Signature: %@", type: .info, argsList: partitionSignature)
                guard let blockSize = loader.ioMedia.createCFProperty(forKey: kIOMediaPreferredBlockSizeKey) as? Int else {
                        throw BootoptionError.devicePath(message: "failed to get IO Media Preferred Block Size", Location())
                }
                Debug.log("Preferred Block Size: %@", type: .info, argsList: blockSize)
                if let partId = loader.ioMedia.createCFProperty(forKey: kIOMediaPartitionIDKey) as? Int {
                        Debug.log("Partition ID: %@", type: .info, argsList: partId)
                        partitionNumber = UInt32(partId)
                } else {
                        throw BootoptionError.devicePath(message: "failed to get IOMedia Partition ID", Location())
                }
                if let base = loader.ioMedia.createCFProperty(forKey: kIOMediaBaseKey) as? Int {
                        partitionStart = UInt64(base / blockSize)
                        Debug.log("Base: %@", type: .info, argsList: partitionStart)
                } else {
                        throw BootoptionError.devicePath(message: "failed to get IOMedia Base", Location())
                }
                if let size = loader.ioMedia.createCFProperty(forKey: kIOMediaSizeKey) as? Int {
                        Debug.log("Size: %@", type: .info, argsList: size)
                        partitionSize = UInt64(size / blockSize)
                } else {
                        throw BootoptionError.devicePath(message: "failed to get IOMedia Size", Location())
                }
                
                /* Initialize the super class */
                
                var devicePathData = Data()
                devicePathData.append(partitionNumber.toData())
                devicePathData.append(partitionStart.toData())
                devicePathData.append(partitionSize.toData())
                devicePathData.append(partitionSignature)
                devicePathData.append(partitionFormat)
                devicePathData.append(signatureType)
                try super.init(type: DevicePathType.MEDIA_DEVICE_PATH.rawValue, subType: DevicePathNode.Media.MEDIA_HARDDRIVE_DP.rawValue, devicePath: devicePathData)
        }
}

public class VendorMediaDevicePath: DevicePath {
        private let vendorGUID: MicrosoftGUID?
        private let vendorData: Data
        
        override public var description: String {
                if let apfsVolumeUuidString = appleAPFSVolumeUUID?.uuidString {
                        return format("Apfs", apfsVolumeUuidString)
                } else if let vendorGUID = vendorGUID {
                        return format("VenMedia", vendorGUID.uuidString, vendorData.hexString)
                } else {
                        return format("VenMedia", devicePath.hexString)
                }
        }
        
        public var appleAPFSVolumeUUID: MicrosoftGUID?
        
        public init(devicePath: Data) throws {
                var buffer = devicePath
                let uuid = buffer.removeData(bytes: 16)
                vendorGUID = MicrosoftGUID(data: uuid)
                vendorData = buffer
                if vendorGUID == AppleAPFSVolumeGUID, vendorData.count > 15 {
                        appleAPFSVolumeUUID = MicrosoftGUID(data: vendorData)
                }
                try super.init(type: DevicePathType.MEDIA_DEVICE_PATH.rawValue, subType: DevicePathNode.Media.MEDIA_VENDOR_DP.rawValue, devicePath: devicePath)
        }
}

public class FilePathDevicePath: DevicePath {
        override public var description: String {
                return format("File", path.quoted)
        }
        
        public var path: String {
                if let string = devicePath.efiStringValue {
                        return string
                } else {
                        fatalError("efiStringValue was unexpectedly nil")
                }                
        }
        
        public init(devicePath: Data) throws {
                Debug.log("Initializing %@ from device path data...", type: .info, argsList: Swift.type(of: self))
                try super.init(type: DevicePathType.MEDIA_DEVICE_PATH.rawValue, subType: DevicePathNode.Media.MEDIA_FILEPATH_DP.rawValue, devicePath: devicePath)
        }
        
        /* Init from loader path */
        
        public init(loader: Loader) throws {
                let loaderPath = loader.path
                Debug.log("Initializing %@ from path: %@", type: .info, argsList: Swift.type(of: self), loaderPath)
                Debug.log("Path: %@", type: .info, argsList: loaderPath)
                
                let pathStartIndex: String.Index = loaderPath.index(loaderPath.startIndex, offsetBy: loader.mountPoint.count)
                var pathString = "/" + loaderPath[pathStartIndex...]
                pathString = pathString.replacingOccurrences(of: "/", with: "\\")
                pathString = pathString.replacingOccurrences(of: "\\\\", with: "\\")
                
                guard let devicePathData = pathString.toUCS2Data() else {
                        throw BootoptionError.devicePath(message: "failed to initialize file device path data", Location())
                }
                
                try super.init(type: DevicePathType.MEDIA_DEVICE_PATH.rawValue, subType: DevicePathNode.Media.MEDIA_FILEPATH_DP.rawValue, devicePath: devicePathData)
        }
}
