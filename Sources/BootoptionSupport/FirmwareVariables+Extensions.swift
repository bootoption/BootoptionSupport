/*
 * FirmwareVariables+Extensions.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Darwin

public extension FirmwareVariables {
        func getBootOrder() -> [BootNumber] {
                var bootOrder = [BootNumber]()
                guard var data = dataValue(forGlobalVariable: "BootOrder") else {
                        Debug.log("BootOrder NVRAM variable not found", type: .warning)
                        return bootOrder
                }
                while !data.isEmpty {
                        bootOrder.append(data.remove16())
                }
                Debug.log("%@", type: .info, argsList: bootOrder.map { $0.variableName })
                return bootOrder
        }
        
        func setBootOrder(adding bootNumber: BootNumber, atIndex index: Int = 0) throws {
                guard dataValue(forGlobalVariable: bootNumber.variableName) != nil else {
                        Debug.log("Couldn't get %@ data, cancelling add to boot order", type: .error, argsList: bootNumber.variableName)
                        return
                }
                var bootOrder = getBootOrder()
                if bootOrder.contains(bootNumber) {
                        Debug.log("BootOrder already contains %@, cancelling add to boot order", type: .warning, argsList: bootNumber.variableName)
                        return
                }
                if bootOrder.indices.contains(index) {
                        bootOrder.insert(bootNumber, at: index)
                } else {
                        bootOrder.append(bootNumber)
                }
                try setBootOrder(array: bootOrder)
        }
        
        func setBootOrder(removing bootNumber: BootNumber) throws {
                var bootOrder = getBootOrder()
                bootOrder.removeAll(where: { $0 == bootNumber })
                try setBootOrder(array: bootOrder)
        }
        
        func setBootOrder(array: [BootNumber]) throws {
                var data = Data()
                var uniqueValues = Set<BootNumber>()
                for bootNumber in array {
                        guard !uniqueValues.contains(bootNumber) else {
                                Debug.log("Ignoring repeated instance of boot number: %@", type: .warning, argsList: bootNumber.variableName)
                                continue
                        }
                        uniqueValues.insert(bootNumber)
                        data.append(bootNumber)
                }
                try setValue(forGlobalVariable: "BootOrder", value: data)
                Debug.log("BootOrder NVRAM variable was set", type: .info)
        }
        
        func setRebootToFirmwareUI() throws {
                var osIndications: UInt64
                if let value = dataValue(forGlobalVariable: "OsIndications")?.toUInt64() {
                        osIndications = value | 0x1
                } else {
                        osIndications = 0x1
                }
                try setValue(forGlobalVariable: "OsIndications", value: osIndications.toData())
                Debug.log("NVRAM OsIndications was set", type: .info)
        }
        
        func discoverUnusedBootNumber() throws -> BootNumber {
                for bootNumber: BootNumber in 0x0000 ..< 0x007F {
                        guard dataValue(forGlobalVariable: bootNumber.variableName) == nil else {
                                continue
                        }
                        Debug.log("Unused boot number discovered: %@", type: .info, argsList: bootNumber.variableName)
                        return bootNumber
                }
                Debug.log("Unused boot number discovery failed", type: .error)
                throw FirmwareVariablesError.unusedBootNumberDisoveryFailure
        }
        
        func setNewLoadOption(data: Data, addingToBootOrder: Bool) throws -> BootNumber {
                let newBootNumber = try discoverUnusedBootNumber()
                try setValue(forGlobalVariable: newBootNumber.variableName, value: data)
                try setBootOrder(adding: newBootNumber, atIndex: 0)
                return newBootNumber
        }
        
        var NVRAMProtectionsEnabled: Bool {
                return 64 & (dataValue(forVariable: "csr-active-config")?.toUInt32() ?? 0) == 0
        }
}
