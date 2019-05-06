/*
 * Buffer.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public class Buffer {
        private(set) var data: Data
        
        private(set) var offset: Int = 0
        
        var count: Int {
                return data.count
        }
        
        var remaining: Int {
                return data.count - offset
        }    
        
        init(_ data: Data) {
                self.data = data
        }
        
        func read<T>() -> T where T: FixedWidthInteger {
                let size = MemoryLayout<T>.size
                let bytes = data.subdata(in: offset..<offset + size)
                let value: T = bytes.withUnsafeBytes {
                        (pointer: UnsafePointer<T>) -> T in
                        return pointer.pointee
                }
                offset += size
                return value
        }
        
        func read(count: Int) -> Data {
                let bytes = self.data.subdata(in: offset..<offset + count)
                offset += count
                return bytes
        }
        
        func read() -> MicrosoftGUID? {
                let data = read(count: 16)
                return MicrosoftGUID(data: data)
        }
        
        func readRemaining() -> Data {
                let bytes = self.data.subdata(in: offset..<data.count)
                offset = count
                return bytes
        }
        
        func seek(toOffset offset: Int) {
                self.offset = offset > count ? count : offset < 0 ? 0 : offset
        }
}
