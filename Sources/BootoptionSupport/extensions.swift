/*
 * extensions.swift
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
                        let j = hexString.index(hexString.startIndex, offsetBy: i*2)
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
        
        func toUInt8() -> UInt8 {
                let value: UInt8 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt8>) -> UInt8 in
                        return pointer.pointee
                }
                return value
        }
        
        func toUInt16() -> UInt16 {
                let value: UInt16 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt16>) -> UInt16 in
                        return pointer.pointee
                }
                return value
        }
        
        func toUInt32() -> UInt32 {
                let value: UInt32 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt32>) -> UInt32 in
                        return pointer.pointee
                }
                return value
        }
        
        func toUInt64() -> UInt64 {
                let value: UInt64 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt64>) -> UInt64 in
                        return pointer.pointee
                }
                return value
        }
        
        @discardableResult mutating func remove64() -> UInt64 {
                let range = Range(0...7)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove32() -> UInt32 {
                let range = Range(0...3)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove16() -> UInt16 {
                let range = Range(0...1)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove8() -> UInt8 {
                return self.remove(at: 0)
        }
        
        @discardableResult mutating func removeData(bytes: Int) -> Data {
                let start = self.startIndex
                let end = index(start, offsetBy: bytes)
                let range = start..<end
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer
        }
}

public extension UInt8 {
        func toData() -> Data {
                var value: UInt8 = self
                return Data(buffer: UnsafeBufferPointer<UInt8>(start: &value, count: 1))
        }
}

public extension UInt16 {
        func toData() -> Data {
                var value: UInt16 = self
                return Data(buffer: UnsafeBufferPointer<UInt16>(start: &value, count: 1))
        }
}

public extension UInt32 {
        func toData() -> Data {
                var value: UInt32 = self
                return Data(buffer: UnsafeBufferPointer<UInt32>(start: &value, count: 1))
        }
}

public extension UInt64 {
        func toData() -> Data {
                var value: UInt64 = self
                return Data(buffer: UnsafeBufferPointer<UInt64>(start: &value, count: 1))
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

public typealias BootNumber = UInt16
public extension BootNumber {
        public var variableName: String {
                return String(format: "Boot%04X", self)
        }
}

/* internal */

internal extension UInt64 {
        var hexString: String {
                return String(format: "0x%016X", self)
        }
        
        var shortHexString: String {
                return String(format: "0x%X", self)
        }
        
        var string: String {
                return String(self)
        }
}

internal extension UInt32 {
        var hexString: String {
                return String(format: "0x%08X", self)
        }
        
        var shortHexString: String {
                return String(format: "0x%X", self)
        }
        
        var string: String {
                return String(self)
        }
}

internal extension UInt16 {
        var hexString: String {
                return String(format: "0x%04X", self)
        }
        
        var shortHexString: String {
                return String(format: "0x%X", self)
        }
        
        var string: String {
                return String(self)
        }
}

internal extension UInt8 {
        var hexString: String {
                return String(format: "0x%02X", self)
        }
        
        var shortHexString: String {
                return String(format: "0x%X", self)
        }
        
        var string: String {
                return String(self)
        }
}

internal extension String {
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
                        
                        data.append(UniChar(scalar!.value).toData())
                }
                
                if nullTerminated {
                        data.append(Data(bytes: [0x00, 0x00]))
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
                        data.append(Data(bytes: [0x00]))
                }
                
                return data
        }
}

internal extension Data {       
        var efiStringValue: String? {
                var buffer = self
                
                let string = buffer.removeEFIString()
                
                if string != nil, !buffer.isEmpty {
                        Debug.log("EFI string buffer is not empty, entire data: %@", type: .error, argsList: self)
                }
                
                return string
        }
        
        private mutating func removeEFIString() -> String? {
                var data = [UniChar]()
                
                while self.count >= 2 {
                        data.append(self.remove16())
                        if data.last == 0x0000 {
                                break
                        }
                }
                
                if data.count == 0 {
                        Debug.log("No string data to decode", type: .error)
                        return nil
                }
                
                var string = ""
                
                for unichar in data {
                        if unichar == 0x0000 {
                                /* Debug.log("\"%@\", %@", type: .info, argsList: string, data) */
                                return string
                        } else if unichar < 0x0020 || unichar > 0xD7FF {
                                Debug.log("Unexpected UCS-16 value: %@", type: .warning, argsList: unichar.hexString)
                                return nil
                        } else {
                                string += "\(UnicodeScalar(unichar)!)"
                        }
                }
                /* Debug.log("\"%@\", %@", type: .info, argsList: string, data) */
                return string
        }
}
