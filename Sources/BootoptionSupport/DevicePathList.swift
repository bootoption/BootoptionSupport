/*
 * DevicePathList.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public class DevicePathList {
        private let immutableDevicePathData: Data?
        
        private var devicePaths = [DevicePathProtocol]()
        
        public var data: Data {
                return immutableDevicePathData ?? Data(devicePaths.map { $0.data }.joined())
        }
        
        public var descriptions: [String] {
                let slices: [ArraySlice<DevicePathProtocol>] = devicePaths.split(whereSeparator: {
                        $0.type == DevicePathType.rawValue.end && $0.subType == DevicePathType.EndSubType.END_ENTIRE_DEVICE_PATH_SUBTYPE.rawValue
                })

                return slices.map { $0.map { #"\"# + $0.description }.joined() }
        }
        
        public init(hardDriveDevicePath: MEDIA_HARD_DRIVE_DP, filePathDevicePath: MEDIA_FILEPATH_DP) throws {
                immutableDevicePathData = nil
                devicePaths.append(hardDriveDevicePath)
                devicePaths.append(filePathDevicePath)
                devicePaths.append(DevicePath(type: DevicePathType.end(.END_ENTIRE_DEVICE_PATH_SUBTYPE), data: nil))
        }
        
        public init(data buffer: Buffer) throws {
                immutableDevicePathData = buffer.data
                
                Debug.log("Parsing device path list...", type: .info)
                
                while buffer.remaining > 0 {
                        let type: UInt8 = buffer.read()
                        let subType: UInt8 = buffer.read()
                        let entireLength: UInt16 = buffer.read()
                        let dataCount = Int(entireLength - 4)
                        
                        if dataCount > buffer.remaining {
                                Debug.log("DP data count \(dataCount) exceeds remaining buffer count \(buffer.remaining)", type: .error)
                                buffer.seek(toOffset: buffer.count)
                                break
                        }
                        
                        let devicePathData = buffer.read(count: dataCount)
                        
                        if devicePathData.isEmpty {
                                Debug.log("Device Path (%@:%@)", type: .info, argsList: type, subType)
                        } else {
                                Debug.log("Device Path (%@:%@), data: %@", type: .info, argsList: type, subType, devicePathData)
                        }

                        if let devicePathType = DevicePathType(type: type, subType: subType), let T = devicePathType.associatedType {
                                devicePaths.append(try T.init(type: devicePathType, devicePathData: Buffer(devicePathData)))
                        } else if let devicePathType = DevicePathType(type: type, subType: subType) {
                                devicePaths.append(DevicePath(type: devicePathType, data: devicePathData))
                        } else {
                                devicePaths.append(DevicePath(type: RawDevicePathType(type: type, subType: subType), data: devicePathData))
                        }
                }
        }
}

public extension DevicePathList {
        func last<T>(ofType: T.Type) -> T? {
                for dp in devicePaths.reversed() {
                        guard let devicePath = dp as? T else {
                                continue
                        }
                        return devicePath
                }
                return nil
        }
        
        var partitionUUIDString: String? {
                return last(ofType: MEDIA_HARD_DRIVE_DP.self)?.signature.UUID?.uuidString
        }
        
        var partitionNumber: String? {
                return last(ofType: MEDIA_HARD_DRIVE_DP.self)?.partitionNumber.string
        }
        
        var masterBootSignature: String? {
                return last(ofType: MEDIA_HARD_DRIVE_DP.self)?.signature.MBR?.hexString
        }
        
        var appleAPFSVolumeUUIDString: String? {
                return last(ofType: MEDIA_VENDOR_DP.self)?.appleAPFSVolumeUUID?.uuidString
        }
        
        var filePath: String? {
                return last(ofType: MEDIA_FILEPATH_DP.self)?.pathString
        }
        
        var macAddress: String? {
                return last(ofType: MSG_MAC_ADDR_DP.self)?.macAddressString
        }
}
