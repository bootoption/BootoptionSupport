/*
 * LoadOptionAttributes.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct LoadOptionAttributes {
        public var intValue: UInt32
        
        public var data: Data {
                return intValue.toData()
        }
        
        public var active: Bool {
                get {
                        return intValue & 0x1 == 0x1
                }
                
                set {
                        intValue = newValue ? intValue | 0x1 : intValue & 0xFFFFFFFE
                }
        }
        
        public var hidden: Bool {
                get {
                        return intValue & 0x8 == 0x8
                }
                
                set {
                        intValue = newValue ? intValue | 0x8 : intValue & 0xFFFFFFF7
                }
        }
        
        init() {
                intValue = 1
        }
        
        init(_ intValue: UInt32) {
                self.intValue = intValue
        }
}
