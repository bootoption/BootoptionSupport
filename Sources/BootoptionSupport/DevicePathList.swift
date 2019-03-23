/*
 * DevicePathList.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public class DevicePathList {
        public var data: Data {
                var buffer = Data()
                for devicePath in devicePaths {
                        buffer.append(devicePath.data)
                }
                return buffer
        }
        
        public var descriptions: [String] {
                var strings = [String]()
                guard !devicePaths.isEmpty else {
                        return strings
                }
                var buffer = ""
                devicePaths.forEach {
                        if $0.type == 0x7f && $0.subType == 0xff {
                                strings.append(buffer)
                                buffer.removeAll()
                        } else {
                                buffer += "\\" + $0.description
                        }
                }
                if !buffer.isEmpty {
                        strings.append(buffer)
                }
                return strings
        }
        
        private var devicePaths = [DevicePath]()
        
        public var partitionUUIDString: String? {
                for dp in devicePaths.reversed() {
                        if let hd = dp as? HardDriveDevicePath {
                                return hd.partitionUUID?.uuidString
                        }
                }
                return nil
        }
        
        public var masterBootPartitionNumberSignature: (String, String)? {
                for dp in devicePaths.reversed() {
                        if let hd = dp as? HardDriveDevicePath {
                                if let signature = hd.masterBootSignature?.hexString {
                                        return (String(hd.partitionNumber), signature)
                                }
                        }
                }
                return nil
        }
        
        public var appleAPFSVolumeUUIDString: String? {
                for dp in devicePaths.reversed() {
                        if let vm = dp as? VendorMediaDevicePath {
                                return vm.appleAPFSVolumeUUID?.uuidString
                        }
                }
                return nil
        }
        
        public var filePath: String? {
                for dp in devicePaths.reversed() {
                        if let fp = dp as? FilePathDevicePath {
                                return fp.path
                        }
                }
                return nil
        }
        
        public var macAddress: String? {
                for dp in devicePaths.reversed() {
                        if let mac = dp as? MacAddressDevicePath {
                                return mac.addressString
                        }
                }
                return nil
        }
        
        public init(hardDriveDevicePath: HardDriveDevicePath, filePathDevicePath: FilePathDevicePath) throws {
                devicePaths.append(hardDriveDevicePath)
                devicePaths.append(filePathDevicePath)
                devicePaths.append(try DevicePath(type: 0x7F, subType: 0xFF, devicePath: Data()))
        }
        
        public init(data: Data) throws {
                Debug.log("Parsing device path list...", type: .info)
                var buffer = data
                while !(buffer.isEmpty) {
                        let listLength = devicePaths.count
                        let type = buffer.remove8()
                        let subType = buffer.remove8()
                        let entireLength = buffer.remove16()
                        let dataCount = Int(entireLength - 4)
                        if dataCount > buffer.count {
                                Debug.log("DP data count exceeds buffer size", type: .error)
                                buffer = Data()
                                break
                        }
                        let devicePathData = buffer.removeData(bytes: dataCount)
                        if devicePathData.isEmpty {
                                Debug.log("Device Path (%@:%@)", type: .info, argsList: type, subType)
                        } else {
                                Debug.log("Device Path (%@:%@), data: %@", type: .info, argsList: type, subType, devicePathData)
                        }
                        
                        switch type {
                        case DevicePathType.HARDWARE_DEVICE_PATH.rawValue: // type 1, hardware
                                switch subType {
                                case DevicePathNode.Hardware.HW_PCI_DP.rawValue: // type 1, sub-type 1, PCI
                                        devicePaths.append(try PciDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Hardware.HW_VENDOR_DP.rawValue: // type 1, sub-type 4, Vendor HW
                                        devicePaths.append(try VendorHardwareDevicePath(devicePath: devicePathData))
                                default:
                                        devicePaths.append(try DevicePath(type: type, subType: subType, devicePath: devicePathData))
                                }
                        case DevicePathType.ACPI_DEVICE_PATH.rawValue: // type 2, ACPI
                                switch subType {
                                case DevicePathNode.Acpi.ACPI_DP.rawValue: // type 2, sub-type 1, ACPI HID
                                        devicePaths.append(try AcpiDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Acpi.ACPI_EXTENDED_DP.rawValue: // type 2, sub-type 2, ACPI extended HID
                                        devicePaths.append(try AcpiExtendedDevicePath(devicePath: devicePathData))
                                default:
                                        devicePaths.append(try DevicePath(type: type, subType: subType, devicePath: devicePathData))
                                }
                        case DevicePathType.MESSAGING_DEVICE_PATH.rawValue: // type 3, messaging
                                switch subType {
                                case DevicePathNode.Messaging.MSG_USB_DP.rawValue: // type 3, sub-type 5, USB
                                        devicePaths.append(try UsbDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_MAC_ADDR_DP.rawValue: // type 3, sub-type 11, MAC address
                                        devicePaths.append(try MacAddressDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_IPv4_DP.rawValue: // type 3, sub-type 12,IPv4
                                        devicePaths.append(try IPv4DevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_IPv6_DP.rawValue: // type 3, sub-type 11, IPv6
                                        devicePaths.append(try IPv6DevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_USB_CLASS_DP.rawValue: // type 3, sub-type 15, USB Class
                                        devicePaths.append(try UsbClassDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_USB_WWID_DP.rawValue: // type 3, sub-type 16, USB WWID
                                        devicePaths.append(try UsbWwidDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_DEVICE_LOGICAL_UNIT_DP.rawValue: // type 3, sub-type 17, LUN
                                        devicePaths.append(try LogicalUnitNumberDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Messaging.MSG_SATA_DP.rawValue: // type 3, sub-type 18, SATA
                                        devicePaths.append(try SataDevicePath(devicePath: devicePathData))
                                default:
                                        devicePaths.append(try DevicePath(type: type, subType: subType, devicePath: devicePathData))
                                }
                        case DevicePathType.MEDIA_DEVICE_PATH.rawValue: // type 4, media
                                switch subType {
                                case DevicePathNode.Media.MEDIA_HARDDRIVE_DP.rawValue: // type 4, sub-type 1, hard drive
                                        devicePaths.append(try HardDriveDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Media.MEDIA_VENDOR_DP.rawValue: // type 4, sub-type 3, vendor-specific media
                                        devicePaths.append(try VendorMediaDevicePath(devicePath: devicePathData))
                                case DevicePathNode.Media.MEDIA_FILEPATH_DP.rawValue: // type 4, sub-type 4, file path
                                        devicePaths.append(try FilePathDevicePath(devicePath: devicePathData))
                                default: // Found some other sub-type
                                        devicePaths.append(try DevicePath(type: type, subType: subType, devicePath: devicePathData))
                                }
                        default: // Found some other type
                                devicePaths.append(try DevicePath(type: type, subType: subType, devicePath: devicePathData))
                        }
                        
                        guard devicePaths.count == listLength + 1 else {
                                throw BootoptionError.devicePath(message: "a device path went missing during parsing", Location())
                        }
                }
        }
}
