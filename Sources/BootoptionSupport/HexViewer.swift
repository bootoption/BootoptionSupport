/*
 * HexViewer.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public protocol HexViewerDataSource {
        var data: Data {
                get
        }
}

public struct HexViewer {
        public var dataSource: HexViewerDataSource?
        
        public var string: String? {
                guard var buffer = dataSource?.data else {
                        return nil
                }
                
                guard !buffer.isEmpty else {
                        return nil
                }
                
                var output = ""
                var ascii = ""
                var col = 0
                
                repeat {
                        col += 1
                        
                        let bytes: [UInt8] = buffer.count > 1 ? [buffer.remove(), buffer.remove()] : [buffer.remove()]
                        
                        bytes.forEach {
                                output += String(format: "%02x", $0)
                        }
                       
                        bytes.forEach {
                                ascii += $0.toASCII() ?? "."
                        }
                        
                        output += bytes.count == 2 ? " " : "   "
                        
                        if col % 8 == 0 {
                                output += " "
                                output += ascii
                                output += "\n"
                                ascii = ""
                        }
                        
                } while !buffer.isEmpty
                
                for _ in 1...(8 - col % 8) {
                        output += "     "
                }
                
                output += " "
                output += ascii
                
                return output
        }
}

fileprivate extension UInt8 {
        func toASCII() -> String? {
                if 0x21...0x7E ~= self {
                        return String(Character(UnicodeScalar(self)))
                } else {
                        return nil
                }
        }
}
