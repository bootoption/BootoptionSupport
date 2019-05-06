/*
 * HardDrivePartitionFormat.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public enum HardDrivePartitionFormat: UInt8 {
        case MBR = 1
        case GUID = 2
        
        var ioClass: String {
                switch self {
                case .MBR:
                        return "IOFDiskPartitionScheme"
                case .GUID:
                        return "IOGUIDPartitionScheme"
                }
        }
        
        var ioMediaContent: String {
                switch self {
                case .MBR:
                        return "FDisk_partition_scheme"
                case .GUID:
                        return "GUID_partition_scheme"
                }
        }
}
