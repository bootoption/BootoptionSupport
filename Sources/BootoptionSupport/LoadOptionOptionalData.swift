/*
 * LoadOptionOptionalData.swift
 * Copyright © 2017-2018 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct LoadOptionOptionalData: HexViewerDataSource {
        public var data: Data
        
        public init() {
                data = Data()
                hexViewer.dataSource = self
        }
        
        public init(data: Data?) {
                self.data = data ?? Data()
                hexViewer.dataSource = self
        }
        
        public init(string: String, isClover: Bool = false, useUCS2: Bool = false) throws {
                if useUCS2 {
                        guard let data = string.toUCS2Data(nullTerminated: false) else {
                                throw BootoptionError.internal(errorMessage: "UCS-2 encoding of optional data string failed", file: #file, function: #function)
                        }
                        self.data = data
                        Debug.log("UCS-2 encoded optional data string: %@", type: .info, argsList: data)
                } else {
                        guard var data = string.toASCIIData(nullTerminated: false) else {
                                throw BootoptionError.internal(errorMessage: "ascii encoding of optional data string failed", file: #file, function: #function)
                        }
                        if isClover {
                                Debug.log("Optional data string for Clover, appending 2 null bytes", type: .warning)
                                data += Data(bytes: [0x00, 0x00])
                        }
                        self.data = data
                        Debug.log("Ascii encoded optional data string: %@", type: .info, argsList: data)
                }
                hexViewer.dataSource = self
        }
        
        public var hexViewer = HexViewer()
        
        public var string: String? {
                var data = self.data
                
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
                
                if let ucs2 = String(UCS2Data: data) {
                        let string = ucs2.replacingOccurrences(of: "\r\n|\r|\n", with: " ", options: .regularExpression)
                        Debug.log("'%@' decoded as UCS-2 from data: %@", type: .info, argsList: string, self.data as Any)
                        return string
                }
                
                Debug.log("Did not decode a string from optional data: %@", type: .info, argsList: self.data as Any)
                
                return nil
        }
}
