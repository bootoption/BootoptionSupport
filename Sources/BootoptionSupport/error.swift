/*
 * error.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct Location {
        let file: String
        let line: String
        let function: String
        
        public init(file: String = #file, line: Int = #line, function: String = #function) {
                self.file = file
                self.line = String(line)
                self.function = function
        }
}

fileprivate func join(_ message: String, withLocation location: Location) -> String {
        var strings = [String]()
        strings.append(message)
        strings.append("(" + location.file + ")")
        strings.append("line:")
        strings.append(location.line)
        strings.append("function:")
        strings.append(location.function)
        return strings.joined(separator: " ")
}

public enum BootoptionError: Error {
        case mustBeRoot
        case usage(errorMessage: String, usageMessage: String)
        case file(message: String)
        case `internal`(message: String, Location)
        case foundNil(id: String, Location)
        case devicePath(message: String, Location)
        
        public var string: String {
                switch self {
                case .mustBeRoot:
                        return "permission denied"
                case .usage(errorMessage: let errorMessage, usageMessage: let usageMessage):
                        if !errorMessage.isEmpty {
                                return errorMessage + "\n" + usageMessage
                        } else {
                                return usageMessage
                        }
                case .file(message: let message):
                        return message
                case .internal(message: let message, let location), .devicePath(message: let message, let location):
                        return join(message, withLocation: location)
                case .foundNil(id: let id, let location):
                        return join(id + " should not be nil here", withLocation: location)

                }
        }
}

public enum FirmwareVariablesError: Error {
        case set(variable: String)
        case sync(variable: String)
        case delete(variable: String)
        case notFound(variable: String)
        
        public var string: String {
                switch self {
                case .set(variable: let name):
                        return "error setting \(name) firmware variable"
                case .sync(variable: let name):
                        return "error syncing \(name) firmware variable"
                case .delete(variable: let name):
                        return "error deleting \(name) firmware variable"
                case .notFound(variable: let name):
                        return "variable \(name) not found"
                }
        }
}
