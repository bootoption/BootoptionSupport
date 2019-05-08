/*
 * FirmwareVariables.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit

open class FirmwareVariables {
        private var options: io_registry_entry_t
        
        private let appleBootGUID = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
        
        private let efiGlobalGUID = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
        
        public static let `default` = FirmwareVariables()        
        
        private init() {
                options = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/options")
        }
        
        public func createCFProperty(forKey key: String) -> CFTypeRef? {
                return IORegistryEntryCreateCFProperty(options, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
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
                        Debug.log("Did not call IORegistryEntrySetCFProperty(:::) for unimplemented type %@", type: .error, argsList: String(describing: type(of: value)))
                        break
                }
                
                switch result {
                case KERN_SUCCESS:
                        return
                default:
                        throw FirmwareVariablesError.set(variable: name)
                }
        }
        
        public func value<T>(forVariable name: String, GUID: UUID? = nil) -> T? {
                var keyValue = ""
                if let uuidString = GUID?.uuidString, uuidString != appleBootGUID {
                        keyValue = uuidString + ":"
                }
                keyValue += name
                return createCFProperty(forKey: keyValue) as? T
        }
        
        public func dataValue(forVariable name: String, GUID: UUID? = nil) -> Data? {
                var keyValue = ""
                if let uuidString = GUID?.uuidString, uuidString != appleBootGUID {
                        keyValue = uuidString + ":"
                }
                keyValue += name
                return createCFProperty(forKey: keyValue) as? Data
        }
        
        open func setValue(forVariable name: String, GUID: UUID? = nil, value: Any) throws {
                var keyValue = ""
                if let uuidString = GUID?.uuidString, uuidString != appleBootGUID {
                        keyValue = uuidString + ":"
                }
                keyValue += name
                try setCFProperty(value, forKey: keyValue)
                try syncNow(keyValue)
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

public extension FirmwareVariables {
        func value<T>(forGlobalVariable name: String) -> T? {
                let result: T? = value(forVariable: name, GUID: UUID(uuidString: efiGlobalGUID))
                return result
        }
        
        func dataValue(forGlobalVariable name: String) -> Data? {
                return dataValue(forVariable: name, GUID: UUID(uuidString: efiGlobalGUID))
        }
        
        func setValue(forGlobalVariable name: String, value: Any) throws {
                try setValue(forVariable: name, GUID: UUID(uuidString: efiGlobalGUID), value: value)
        }
        
        func delete(globalVariable name: String) throws {
                try delete(variable: name, GUID: UUID(uuidString: efiGlobalGUID))
        }
}
