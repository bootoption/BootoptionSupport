/*
 * LoadOptionDescription.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct LoadOptionDescription {
        public var data: Data
        
        public var string: String {
                get {
                        guard let string = String(UCS2Data: data) else {
                                fatalError("LoadOptionDescription.string should not be nil")
                        }
                        
                        return string
                }
                
                set {
                        guard let data = newValue.toUCS2Data() else {
                                fatalError("EFI string data should not be nil")
                        }
                        
                        self.data = data
                }
        }
}
