/*
 * MicrosoftGUID.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct MicrosoftGUID: Equatable {
        private var data1: UInt32
        private var data2: UInt16
        private var data3: UInt16
        private var data4: Array<UInt8>
        
        public var uuidString: String {
                var components = [String]()
                components.append(String(format: "%08X", data1))
                components.append(String(format: "%04X", data2))
                components.append(String(format: "%04X", data3))
                components.append(data4[0...1].map { String(format: "%02X", $0) }.joined())
                components.append(data4[2...7].map { String(format: "%02X", $0) }.joined())
                return components.joined(separator: "-")
        }
        
        public func data() -> Data {
                var buffer = Data()
                var mutableData1 = data1
                var mutableData2 = data2
                var mutableData3 = data3
                buffer.append(Data(buffer: UnsafeBufferPointer<UInt32>(start: &mutableData1, count: 1)))
                buffer.append(Data(buffer: UnsafeBufferPointer<UInt16>(start: &mutableData2, count: 1)))
                buffer.append(Data(buffer: UnsafeBufferPointer<UInt16>(start: &mutableData3, count: 1)))
                buffer.append(Data(data4))
                return buffer
        }
        
        public mutating func bytes() -> [UInt8] {
                return [UInt8](data())
        }
        
        public init?(data: Data) {
                guard data.count == 16 else {
                        return nil
                }
                data1 = data[0...3].withUnsafeBytes {
                        (pointer: UnsafePointer<UInt32>) -> UInt32 in
                        return pointer.pointee
                }
                data2 = data[4...5].withUnsafeBytes {
                        (pointer: UnsafePointer<UInt16>) -> UInt16 in
                        return pointer.pointee
                }
                data3 = data[6...7].withUnsafeBytes {
                        (pointer: UnsafePointer<UInt16>) -> UInt16 in
                        return pointer.pointee
                }
                data4 = Array<UInt8>(data[8...15])
        }
        
        public init?(bytes: [UInt8]) {
                self.init(data: Data(bytes))
        }
        
        public init?(uuid: UUID) {
                let bytes = uuid.uuid                
                let data1: [UInt8] = [bytes.0, bytes.1, bytes.2, bytes.3].reversed()
                let data2: [UInt8] = [bytes.4, bytes.5].reversed()
                let data3: [UInt8] = [bytes.6, bytes.7].reversed()
                let data4: [UInt8] = [bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15]
                self.init(bytes: data1 + data2 + data3 + data4)
        }
        
        public init?(uuidString: String) {
                guard let uuid = UUID(uuidString: uuidString) else {
                        return nil
                }
                self.init(uuid: uuid)
        }
        
        public init?() {
                self.init(uuid: UUID())
        }
        
        public static func == (a: MicrosoftGUID, b: MicrosoftGUID) -> Bool {
                return a.data1 == b.data1 && a.data2 == b.data2 && a.data3 == b.data3 && a.data4 == b.data4
        }
}
