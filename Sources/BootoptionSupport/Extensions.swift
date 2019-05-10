/*
 * Extensions.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

/* public */

public extension Data {
        init?(hexString: String) {
                let len = hexString.count / 2
                var data = Data(capacity: len)
                
                for i in 0..<len {
                        let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
                        let k = hexString.index(j, offsetBy: 2)
                        let bytes = hexString[j..<k]
                        
                        if var num = UInt8(bytes, radix: 16) {
                                data.append(&num, count: 1)
                        } else {
                                return nil
                        }
                }
                
                self = data
        }
        
        var hexString: String {
                let hexDigits = Array("0123456789ABCDEF".utf16)
                var chars: [unichar] = []
                chars.reserveCapacity(2 * count)
                
                for byte in self {
                        chars.append(hexDigits[Int(byte / 16)])
                        chars.append(hexDigits[Int(byte % 16)])
                }
                
                return "0x" + String(utf16CodeUnits: chars, count: chars.count)
        }
        
        mutating func append<T>(_ int: T) where T: FixedWidthInteger {
                append(int.toData())
        }
        
        func toUInt8() -> UInt8 {
                return withUnsafeBytes { $0.load(as: UInt8.self) }
        }
        
        func toUInt16() -> UInt16 {
                return withUnsafeBytes { $0.load(as: UInt16.self) }
        }
        
        func toUInt32() -> UInt32 {
                return withUnsafeBytes { $0.load(as: UInt32.self) }
        }
        
        func toUInt64() -> UInt64 {
                return withUnsafeBytes { $0.load(as: UInt64.self) }
        }
        
        mutating func remove<T>() -> T where T: FixedWidthInteger {
                let range = 0..<T.bitWidth / 8
                let buffer = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes { $0.load(as: T.self) }
        }
        
        @discardableResult mutating func remove64() -> UInt64 {
                let range = Range(0...7)
                let buffer = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes { $0.load(as: UInt64.self) }
        }
        
        @discardableResult mutating func remove32() -> UInt32 {
                let range = Range(0...3)
                let buffer = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes { $0.load(as: UInt32.self) }
        }
        
        @discardableResult mutating func remove16() -> UInt16 {
                let range = Range(0...1)
                let buffer = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes { $0.load(as: UInt16.self) }
        }
        
        @discardableResult mutating func remove8() -> UInt8 {
                return self.remove(at: 0)
        }
        
        @discardableResult mutating func remove(count: Int) -> Data {
                let start = self.startIndex
                let end = index(start, offsetBy: count)
                let range = start..<end
                let buffer = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer
        }
}

public extension FixedWidthInteger {
        func toData() -> Data {
                var value = self
                return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        }
        
        var hexString: String {
                return String(format: "0x%0\(bitWidth / 8)X", self as! CVarArg)
        }
        
        var shortHexString: String {
                return String(format: "0x%X", self as! CVarArg)
        }
        
        var string: String {
                return "\(self)"
        }
}

public extension String {
        func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
                let length = self.count
                if length < newLength {
                        return String(repeatElement(character, count: newLength - length)) + self
                } else {
                        let i: String.Index = index(self.startIndex, offsetBy: length - newLength)
                        return String(self[i...])
                }
        }
}

public extension FileHandle {
        func write(string: String, terminator: String = "\n") {
                guard let data = (string + terminator).data(using: .utf8) else {
                        return
                }
                self.write(data)
        }
}

public extension Array {
        mutating func order(itemAtIndex index: Int, to destination: Int) {
                insert(remove(at: index), at: destination)
        }
}

internal extension UInt32 {
        var eisaPnpID: String? {
                var buffer = self.toData()
                switch buffer.remove16() {
                case 0x41d0:
                        let id: UInt16 = buffer.remove()
                        return "PNP" + String(format: "%04X", id)
                default:
                        return nil
                }
        }
}

internal extension String {
        func stringFromSubSequence(startIndexOffsetBy offset: Int) -> String {
                let start = index(startIndex, offsetBy: offset)
                return String(self[start...])
        }
        
        init?(UCS2Data: Data) {
                var buffer = UCS2Data
                
                guard let string = buffer.removeEFIString() else {
                        return nil
                }
                
                if !buffer.isEmpty {
                        Debug.log("UCS2 buffer is not empty, entire data: %@", type: .error, argsList: UCS2Data)
                }
                
                self = string
        }
        
        func toUCS2Data(nullTerminated: Bool = true) -> Data? {
                var data = Data()
                
                for character in self {
                        let scalar: Unicode.Scalar? = UnicodeScalar(String(character))
                        
                        guard scalar != nil else {
                                Debug.log("scalar should no longer be nil", type: .error)
                                return nil
                        }
                        
                        guard scalar!.value > 0x19, scalar!.value < 0xD800 else {
                                Debug.log("%@ unicode scalar value for '%@' out of range", type: .error, argsList: self, String(character))
                                return nil
                        }
                        
                        data.append(UniChar(scalar!.value))
                }
                
                if nullTerminated {
                        data.append(Data([0x00, 0x00]))
                }
                
                return data
        }
        
        func toASCIIData(nullTerminated: Bool = true) -> Data? {
                guard self.canBeConverted(to: .ascii) else {
                        Debug.log("%@ cannot be converted to ascii", type: .error, argsList: self)
                        return nil
                }
                
                var data = Data(self.utf8)
                
                if nullTerminated {
                        data.append(Data([0x00]))
                }
                
                return data
        }
        
        var quoted: String {
                return "\"" + self + "\""
        }
}

internal extension Data {       
        mutating func removeEFIString() -> String? {
                var data = [UniChar]()
                
                if self.count < 2 {
                        Debug.log("No EFI string data to decode", type: .error)
                        return nil
                }
                
                while self.count >= 2 {
                        data.append(self.remove16())
                        if data.last == 0 {
                                break
                        }
                }
                
                var string = ""
                
                for unichar in data {
                        if unichar == 0 {
                                /* Debug.log(#""%@", %@"#, type: .info, argsList: string, data) */
                                return string
                        } else if unichar < 0x20 || unichar > 0xD7FF {
                                Debug.log("Unexpected UCS2 value: %@", type: .warning, argsList: unichar.hexString)
                                return nil
                        } else {
                                string += "\(UnicodeScalar(unichar)!)"
                        }
                }
                /* Debug.log(#""%@", %@"#, type: .info, argsList: string, data) */
                return string
        }
}
