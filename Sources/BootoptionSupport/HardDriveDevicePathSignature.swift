/*
 * HardDriveDevicePathSignature.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct HardDriveDevicePathSignature {
        let type: UInt8
        let data: Data        
        
        var MBR: UInt32? {
                return type == 1 ? data.subdata(in: Range(0...3)).toUInt32() : nil
        }
        
        var UUID: MicrosoftGUID? {
                return type == 2 ? MicrosoftGUID(data: data) : nil
        }
        
        init?(type: SignatureType?, data: Data) {
                guard let type = type else {
                        return nil
                }
                self.type = type.rawValue
                self.data = data
        }
        
        init?(loader: Loader) {
                switch loader.partitionFormat {
                case .MBR:
                        guard let bsdName = loader.ioMediaWhole.createCFProperty(forKey: kIOBSDNameKey) as? String else {
                                return nil
                        }
                        
                        guard let mbrSignature = HardDriveDevicePathSignature.readMBRSignature(bsdName: bsdName) else {
                                return nil
                        }
                        
                        Debug.log("Read MBR signature: %@", type: .info, argsList: mbrSignature.hexString)
                        
                        let signatureBytes = mbrSignature.toData() + Data([UInt8](repeating: 0x00, count: 12))
                        
                        self.init(type: .MBR, data: signatureBytes)
                case .GUID:
                        guard let ioUUIDString = loader.ioMedia.createCFProperty(forKey: kIOMediaUUIDKey) as? String else {
                                return nil
                        }
                        
                        Debug.log("Loader partition UUID: %@", type: .info, argsList: ioUUIDString)
                        
                        guard let uuid = MicrosoftGUID(uuidString: ioUUIDString) else {
                                return nil
                        }
                        
                        self.init(type: .GPT, data: uuid.data())
                }
        }
        
        enum SignatureType: UInt8 {
                case MBR = 1
                case GPT = 2
        }
        
        static func readMBRSignature(bsdName: String) -> UInt32? {
                var signature: UInt32
                
                guard let fileHandle = FileHandle.init(forReadingAtPath: "/dev/\(bsdName)") else {
                        return nil
                }
                
                fileHandle.seek(toFileOffset: 0x1B8)
                signature = fileHandle.readData(ofLength: 4).toUInt32()
                fileHandle.closeFile()
                
                return signature
        }
}
