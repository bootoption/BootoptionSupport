/*
 * OptionalData.swift
 * Copyright © 2017-2018 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct OptionalData {
        public var data: Data? {
                didSet {
                       hexViewer.data = data
                }
        }        
        
        mutating public func remove() {
                data = nil
        }
        
        public var hexViewer = HexViewer()
        
        public var string: String? {
                guard var data = self.data else {
                        return nil
                }
                
                if data.count > 1, data[data.endIndex - 1] + data[data.endIndex - 2] == 0 {
                        data.removeLast(2)
                }
                
                guard !data.isEmpty else {
                        return nil
                }
                
                let i = data.firstIndex(of: 0x00) ?? data.count
                
                if i > data.count - 2, let ascii = String(data: data, encoding: .ascii) {
                        let string = ascii.replacingOccurrences(of: "\r\n|\r|\n", with: " ", options: .regularExpression)
                        Debug.log("'%@' decoded as ASCII from data: %@", type: .info, argsList: string, self.data as Any)
                        return string
                }
                
                if let ucs2 = data.efiStringValue {
                        let string = ucs2.replacingOccurrences(of: "\r\n|\r|\n", with: " ", options: .regularExpression)
                        Debug.log("'%@' decoded as UCS-2 from data: %@", type: .info, argsList: string, self.data as Any)
                        return string
                }
                
                Debug.log("Did not decode a string from optional data: %@", type: .info, argsList: self.data as Any)
                
                return nil
        }
        
        mutating private func setUsingASCII(string: String, isClover: Bool = false) throws {
                guard var data = string.toASCIIData(nullTerminated: false) else {
                        throw BootoptionError.internal(message: "ascii encoding of optional data string failed", Location())
                }
                if isClover {
                        Debug.log("Optional data string for Clover, appending 2 null bytes", type: .warning)
                        data += Data(bytes: [0x00, 0x00])
                }
                self.data = data
                Debug.log("Ascii encoded optional data string: %@", type: .info, argsList: data)
        }
        
        mutating private func setUsingUCS2(string: String) throws {
                guard let data = string.toUCS2Data(nullTerminated: false) else {
                        throw BootoptionError.internal(message: "UCS-2 encoding of optional data string failed", Location())
                }
                self.data = data
                Debug.log("UCS-2 encoded optional data string: %@", type: .info, argsList: data)
        }
        
        mutating public func set(string: String, isClover: Bool = false, useUCS2: Bool = false) throws {
                if useUCS2 {
                        try setUsingUCS2(string: string)
                } else {
                        try setUsingASCII(string: string, isClover: isClover)
                }
        }
}
