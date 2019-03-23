/*
 * FirmwareVariables.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit

open class FirmwareVariables {
        private var options: io_registry_entry_t
        
        public static let `default` = FirmwareVariables()        
        
        private init() {
                options = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/options")
        }
        
        open func setValue(forGlobalVariable name: String, value: Any) throws {
                let key = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C:" + name
                try setCFProperty(value, forKey: key)
                try syncNow(key)
        }
        
        open func setValue(forVariable name: String, GUID: UUID? = nil, value: Any) throws {
                var key = ""
                if let uuidString = GUID?.uuidString {
                        key = uuidString + ":"
                }
                key += name
                try setCFProperty(value, forKey: key)
                try syncNow(key)
        }
        
        public func createCFProperty(forKey key: String) -> CFTypeRef? {
                return IORegistryEntryCreateCFProperty(options, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }

        
        public func dataValue(forGlobalVariable name: String) -> Data? {
                let key = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C:" + name
                guard let data = createCFProperty(forKey: key) as? Data else {
                        return nil
                }
                return data
        }
        
        public func dataValue(forVariable name: String, GUID: UUID? = nil) -> Data? {
                var key = ""
                if let uuidString = GUID?.uuidString {
                        key = uuidString + ":"
                }
                key += name
                guard let data = createCFProperty(forKey: key) as? Data else {
                        return nil
                }
                return data
        }
        
        public func stringValue(forGlobalVariable name: String) -> String? {
                let key = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C:" + name
                guard let string = createCFProperty(forKey: key) as? String else {
                        return nil
                }
                return string

        }
        
        public func stringValue(forVariable name: String, GUID: UUID? = nil) -> String? {
                var key = ""
                if let uuidString = GUID?.uuidString {
                        key = uuidString + ":"
                }
                key += name
                guard let string = createCFProperty(forKey: key) as? String else {
                        return nil
                }
                return string
        }
        
        public func delete(globalVariable name: String) throws {
                let variable = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C:" + name
                let result = IORegistryEntrySetCFProperty(options, kIONVRAMDeletePropertyKey as CFString, variable as CFString)
                switch result {
                case KERN_SUCCESS:
                        return
                default:
                        throw FirmwareVariablesError.delete(variable: name)
                }
        }
        
        public func delete(variable name: String, GUID: UUID? = nil) throws {
                var variable = ""
                if let uuidString = GUID?.uuidString {
                        variable = uuidString + ":"
                }
                variable += name
                let result = IORegistryEntrySetCFProperty(options, kIONVRAMDeletePropertyKey as CFString, variable as CFString)
                switch result {
                case KERN_SUCCESS:
                        return
                default:
                        throw FirmwareVariablesError.delete(variable: name)
                }
        }
        
        private func setCFProperty(_ value: Any, forKey name: String) throws {
                var result = KERN_NOT_SUPPORTED
                switch value {
                case is Bool:
                        if let bool = value as? Bool {
                                result = IORegistryEntrySetCFProperty(options, name as CFString, bool as CFBoolean)
                        }
                case is String:
                        if let string = value as? String {
                                result = IORegistryEntrySetCFProperty(options, name as CFString, string as CFString)
                        }
                case is NSNumber:
                        if let number = value as? NSNumber {
                                result = IORegistryEntrySetCFProperty(options, name as CFString, number as CFNumber)
                        }
                case is Data:
                        if let data = value as? Data {
                                result = IORegistryEntrySetCFProperty(options, name as CFString, data as CFData)
                        }
                default:
                        Debug.log("Failed to cast value for IORegistryEntrySetCFProperty", type: .error)
                        break
                }
                switch result {
                case KERN_SUCCESS:
                        return
                default:
                        throw FirmwareVariablesError.set(variable: name)
                }
        }
        
        private func syncNow(_ name: String) throws {
                let result = IORegistryEntrySetCFProperty(options, kIONVRAMSyncNowPropertyKey as CFString, name as CFString)
                switch result {
                case KERN_SUCCESS:
                        return
                default:
                        throw FirmwareVariablesError.sync(variable: name)
                }
        }
}
