/*
 * Debug.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit

public struct Debug {
        private static let pid = getpid()
        
        public static func log(_ message: String, type: LogType, file: String = #file, function: String = #function, argsList: Any ...) {
                #if DEBUG
                var cVarArgArray: [CVarArg] = []
                
                for arg in argsList {
                        switch arg {
                        case let data as Data:
                                let debugString = "<" + data.hexString + ">"
                                cVarArgArray.append(debugString as CVarArg)
                        default:
                                cVarArgArray.append(String(describing: arg) as CVarArg)
                        }
                }
                
                var color: String
                
                switch type {
                case .info:
                        color = Debug.ANSI.green
                case .error, .fault:
                        color = Debug.ANSI.red
                default:
                        color = Debug.ANSI.yellow
                }
                
                let message = String(format: "%@%d %@ %@ • %@%@", color, pid, NSString(string: file).lastPathComponent, function, String(format: message, arguments: cVarArgArray), Debug.ANSI.reset)

                FileHandle.standardError.write(string: message)
                #endif
        }
        
        private static func efiInfo() {
                #if DEBUG
                let efi = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/efi")
                
                if let firmwareVendor = IORegistryEntryCreateCFProperty(efi, "firmware-vendor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data {
                        log("firmware-vendor: %@", type: .info, argsList: String(UCS2Data: firmwareVendor) ?? firmwareVendor)
                }
                
                if let firmwareRevision = IORegistryEntryCreateCFProperty(efi, "firmware-revision" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data {
                        log("firmware-revision: %@", type: .info, argsList: firmwareRevision)
                }
                #endif
        }
        
        public static func initialize(versionString: String) {
                guard FirmwareVariables.default.dataValue(forVariable: "EmuVariableUefiPresent") == nil else {
                        FileHandle.standardError.write(string: "EmuVariableUefiPresent found in options")
                        exit(1)
                }
                
                #if DEBUG
                if let term = ProcessInfo.processInfo.environment["TERM"], term.contains("color") {
                        Debug.ANSI.green = "\u{001B}[0;32m"
                        Debug.ANSI.yellow = "\u{001B}[0;33m"
                        Debug.ANSI.red = "\u{001B}[0;31m"
                        Debug.ANSI.reset = "\u{001B}[0;0m"
                }
                
                Debug.log("Version %@", type: .info, argsList: versionString)
                Debug.efiInfo()                
                #endif
        }
        
        private struct ANSI {
                static var green = ""
                static var yellow = ""
                static var red = ""
                static var reset = ""
        }
        
        public enum LogType {
                case info
                case warning
                case error
                case fault
        }
}
