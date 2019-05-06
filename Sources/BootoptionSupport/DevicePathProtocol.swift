/*
 * DevicePathProtocol.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public protocol DevicePathProtocol {
        init(type: DevicePathTypeProtocol, devicePathData buffer: Buffer) throws
        
        var devicePathType: DevicePathTypeProtocol {
                get
        }
        
        var type: UInt8 {
                get
        }
        
        var subType: UInt8 {
                get
        }
        
        var length: UInt16 {
                get
        }
        
        var devicePathData: Data {
                get
        }
        
        var data: Data {
                get
        }
        
        var descriptionStrings: [String] {
                get
        }
        
        var description: String {
                get
        }
}

extension DevicePathProtocol {        
        public var type: UInt8 {
                return devicePathType.type
        }
        
        public var subType: UInt8 {
                return devicePathType.subType
        }
        
        public var length: UInt16 {
                return UInt16(devicePathData.count + 4)
        }
        
        public var data: Data {
                var buffer = Data()
                buffer.append(type)
                buffer.append(subType)
                buffer.append(length)
                buffer.append(devicePathData)
                return buffer
        }
        
        public var description: String {
                var strings = descriptionStrings.isEmpty ? ["\(type)", "\(subType)", devicePathData.hexString] : descriptionStrings
                let title = strings.removeFirst()
                return title + "(" + strings.joined(separator: ",") + ")"
        }
}
