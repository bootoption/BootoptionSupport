/*
 * FirmwareVariablesError.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public enum FirmwareVariablesError: Error, CustomStringConvertible {
        case set(variable: String)
        case sync(variable: String)
        case delete(variable: String)
        case invalidVariableName(string: String)
        case notFound(variable: String)
        case unusedBootNumberDisoveryFailure
        
        public var description: String {
                if FirmwareVariables.default.NVRAMProtectionsEnabled {
                        switch self {
                        case .set(variable: let name):
                                let shortName = name.split(separator: ":").last!
                                return "failed to set '\(shortName)', NVRAM protections may be enabled - see csrutil(8)"
                        default:
                                break
                        }
                }
                
                switch self {
                case .set(variable: let name):
                        return "failed to set '\(name)' firmware variable"
                case .sync(variable: let name):
                        return "failed to sync '\(name)' firmware variable"
                case .delete(variable: let name):
                        return "failed to delete '\(name)' firmware variable"
                case .invalidVariableName(string: let string):
                        return "invalid variable name '\(string)'"
                case .notFound(variable: let name):
                        return "variable '\(name)' not found"
                case .unusedBootNumberDisoveryFailure:
                        return "unused boot number discovery failure"
                }
        }
}
