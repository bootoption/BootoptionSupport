/*
 * BootNumber.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public typealias BootNumber = UInt16

public extension UInt16 {
        init(variableName: String) throws {
                var string = variableName.uppercased()
                string = string.replacingOccurrences(of: "0X", with: "")                
                string = string.replacingOccurrences(of: "BOOT", with: "")
                
                guard Set("ABCDEF1234567890").isSuperset(of: string) else {
                        throw FirmwareVariablesError.invalidVariableName(string: variableName)
                }
                
                guard string.count < 5 else {
                        throw FirmwareVariablesError.invalidVariableName(string: variableName)
                }
                
                guard let uint16 = UInt16(string, radix: 16) else {
                        throw FirmwareVariablesError.invalidVariableName(string: variableName)
                }
                
                self = uint16
        }
        
        var variableName: String {
                return String(format: "Boot%04X", self)
        }
}
