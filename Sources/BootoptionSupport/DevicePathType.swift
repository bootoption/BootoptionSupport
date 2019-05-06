/*
 * DevicePathType.swift
 * Copyright © 1998 Intel Corporation
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public protocol DevicePathTypeProtocol {
        var type: UInt8 {
                get
        }
        
        var subType: UInt8 {
                get
        }
        
        var associatedType: DevicePathProtocol.Type? {
                get
        }
}

struct RawDevicePathType: DevicePathTypeProtocol {
        let type: UInt8
        let subType: UInt8
        
        var associatedType: DevicePathProtocol.Type? {
                return nil
        }
}

enum DevicePathType: DevicePathTypeProtocol {
        case hardware(HardwareSubType)
        case acpi(ACPISubType)
        case messaging(MessagingSubType)
        case media(MediaSubType)
        case bbs(BBSSubType)
        case end(EndSubType)
        
        struct rawValue {
                static let hardware: UInt8 = 1
                static let acpi: UInt8 = 2
                static let messaging: UInt8 = 3
                static let media: UInt8 = 4
                static let bbs: UInt8 = 5
                static let end: UInt8 = 0x7f
        }
        
        init?(type: UInt8, subType: UInt8) {
                switch type {
                case DevicePathType.rawValue.hardware:
                        guard let subType = HardwareSubType(rawValue: subType) else {
                                return nil
                        }
                        self = .hardware(subType)
                case DevicePathType.rawValue.acpi:
                        guard let subType = ACPISubType(rawValue: subType) else {
                                return nil
                        }
                        self = .acpi(subType)
                case DevicePathType.rawValue.messaging:
                        guard let subType = MessagingSubType(rawValue: subType) else {
                                return nil
                        }
                        self = .messaging(subType)
                case DevicePathType.rawValue.media:
                        guard let subType = MediaSubType(rawValue: subType) else {
                                return nil
                        }
                        self = .media(subType)
                case DevicePathType.rawValue.bbs:
                        guard let subType = BBSSubType(rawValue: subType) else {
                                return nil
                        }
                        self = .bbs(subType)
                case DevicePathType.rawValue.end:
                        guard let subType = EndSubType(rawValue: subType) else {
                                return nil
                        }
                        self = .end(subType)
                default:
                        return nil
                }
        }
        
        var associatedType: DevicePathProtocol.Type? {
                switch self {
                case .hardware(.HW_PCI_DP):
                        return BootoptionSupport.HW_PCI_DP.self
                case .hardware(.HW_VENDOR_DP):
                        return BootoptionSupport.HW_VENDOR_DP.self
                case .acpi(.ACPI_DP):
                        return BootoptionSupport.ACPI_DP.self
                case .acpi(.ACPI_EXTENDED_DP):
                        return BootoptionSupport.ACPI_EXTENDED_DP.self
                case .messaging(.MSG_USB_DP):
                        return BootoptionSupport.MSG_USB_DP.self
                case .messaging(.MSG_MAC_ADDR_DP):
                        return BootoptionSupport.MSG_MAC_ADDR_DP.self
                case .messaging(.MSG_IPv4_DP):
                        return BootoptionSupport.MSG_IPv4_DP.self
                case .messaging(.MSG_IPv6_DP):
                        return BootoptionSupport.MSG_IPv6_DP.self
                case .messaging(.MSG_USB_CLASS_DP):
                        return BootoptionSupport.MSG_USB_CLASS_DP.self
                case .messaging(.MSG_USB_WWID_DP):
                        return BootoptionSupport.MSG_USB_WWID_DP.self
                case .messaging(.MSG_DEVICE_LOGICAL_UNIT_DP):
                        return BootoptionSupport.MSG_DEVICE_LOGICAL_UNIT_DP.self
                case .messaging(.MSG_SATA_DP):
                        return BootoptionSupport.MSG_SATA_DP.self
                case .messaging(.MSG_NVME_NAMESPACE_DP):
                        return BootoptionSupport.MSG_NVME_NAMESPACE_DP.self
                case .media(.MEDIA_HARDDRIVE_DP):
                        return BootoptionSupport.MEDIA_HARD_DRIVE_DP.self
                case .media(.MEDIA_VENDOR_DP):
                        return BootoptionSupport.MEDIA_VENDOR_DP.self
                case .media(.MEDIA_FILEPATH_DP):
                        return BootoptionSupport.MEDIA_FILEPATH_DP.self
                default:
                        return nil
                }
        }
        
        var type: UInt8 {
                switch self {
                case .hardware:
                        return DevicePathType.rawValue.hardware
                case .acpi:
                        return DevicePathType.rawValue.acpi
                case .messaging:
                        return DevicePathType.rawValue.messaging
                case .media:
                        return DevicePathType.rawValue.media
                case .bbs:
                        return DevicePathType.rawValue.bbs
                case .end:
                        return DevicePathType.rawValue.end
                }
        }
        
        var subType: UInt8 {
                switch self {
                case .hardware(let subType):
                        return subType.rawValue
                case .acpi(let subType):
                        return subType.rawValue
                case .messaging(let subType):
                        return subType.rawValue
                case .media(let subType):
                        return subType.rawValue
                case .bbs(let subType):
                        return subType.rawValue
                case .end(let subType):
                        return subType.rawValue
                }
        }
        
        enum HardwareSubType: UInt8  {
                case HW_PCI_DP = 1
                case HW_PCCARD_DP = 2
                case HW_MEMMAP_DP = 3
                case HW_VENDOR_DP = 4
                case HW_CONTROLLER_DP = 5
                case HW_BMC_DP = 6
        }
        
        enum ACPISubType: UInt8 {
                case ACPI_DP = 1
                case ACPI_EXTENDED_DP = 2
                case ACPI_ADR_DP = 3
        }
        
        enum MessagingSubType: UInt8 {
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
        
        enum MediaSubType: UInt8 {
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
        
        enum BBSSubType: UInt8 {
                case BBS_BBS_DP = 1
        }
        
        enum EndSubType: UInt8 {
                case END_INSTANCE_DEVICE_PATH_SUBTYPE = 1
                case END_ENTIRE_DEVICE_PATH_SUBTYPE = 0xff
        }
}
