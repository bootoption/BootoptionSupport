/*
 * BootoptionError.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public enum BootoptionError: Error, CustomStringConvertible {
        case usage(helpName: String?, errorMessage: String?, usageMessage: String?)
        case mustBeRoot
        case file(errorMessage: String)
        case `internal`(errorMessage: String, file: NSString, function: String)
        case foundNil(description: String, file: NSString, function: String)
        
        public var description: String {
                switch self {
                case .usage(helpName: let helpName, errorMessage: let errorMessage, usageMessage: let usageMessage):
                        switch (errorMessage, usageMessage) {
                        case (.some, .none):
                                return "\(helpName ?? "error"): \(errorMessage!)"
                        case (.none, .some):
                                return usageMessage!
                        case (.some, .some):
                                return "\(helpName ?? "error"): \(errorMessage!)" + "\n" + usageMessage!
                        case (.none, .none):
                                return "undefined"
                        }
                case .mustBeRoot:
                        return "permission denied"
                case .file(errorMessage: let errorMessage):
                        return errorMessage
                case .internal(errorMessage: let errorMessage, file: let file, function: let function):
                        return "\(errorMessage) [(): \(function), file: \(file.lastPathComponent)]"
                case .foundNil(description: let description, file: let file, function: let function):
                        return "'\(description)' should not be nil here [(): \(function), file: \(file.lastPathComponent)]"
                }
        }
}

