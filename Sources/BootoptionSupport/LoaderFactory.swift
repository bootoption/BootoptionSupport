/*
 * LoaderFactory.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit.storage

public class LoaderFactory {
        static public let `default` = LoaderFactory()
        
        private init() {}
        
        private var loaders: [String: Loader] = [:]
        
        public func setLoader(path: String, loader: Loader) {
                loaders.updateValue(loader, forKey: path)
        }
        
        public func makeLoader(path: String) throws -> Loader {               
                if loaders.index(forKey: path) != nil, let loader = loaders[path] {
                        return loader
                }
               
                try assertFileHasMagic(path)
                
                guard let mountPoint = mountPoint(forPath: path) else {
                        throw BootoptionError.internal(errorMessage: "failed to get a mount point from the loader path", file: #file, function: #function)
                }
                
                guard let ioMedia = RegistryEntry(IOMediaWithMountPoint: mountPoint as CFString) else {
                        throw BootoptionError.internal(errorMessage: "failed to create IOMedia object from mount point", file: #file, function: #function)
                }
                
                guard let parent = RegistryEntry(parentOf: ioMedia.entry) else {
                        throw BootoptionError.internal(errorMessage: "failed to create parent entry (1)", file: #file, function: #function)
                }
                
                guard let ioClass = parent.createCFProperty(forKey: kIOClassKey) as? String else {
                        throw BootoptionError.internal(errorMessage: "failed to create property for kIOClassKey", file: #file, function: #function)
                }
                
                switch ioClass {
                case HardDrivePartitionFormat.MBR.ioClass, HardDrivePartitionFormat.GUID.ioClass:
                        guard let parent = RegistryEntry(parentOf: parent.entry) else {
                                throw BootoptionError.internal(errorMessage: "failed to create parent entry (2)", file: #file, function: #function)
                        }
                        
                        guard parent.createCFProperty(forKey: kIOMediaWholeKey) as? Bool == true else {
                                throw BootoptionError.internal(errorMessage: "failed to create property for kIOMediaWholeKey", file: #file, function: #function)
                        }
                        
                        guard let ioMediaContent = parent.createCFProperty(forKey: kIOMediaContentKey) as? String else {
                                throw BootoptionError.internal(errorMessage: "failed to create property for kIOMediaContentKey", file: #file, function: #function)
                        }
                        
                        switch ioMediaContent {
                        case HardDrivePartitionFormat.MBR.ioMediaContent:
                                return Loader(path: path, mountPoint: mountPoint, ioMedia: ioMedia, ioMediaWhole: parent, scheme: HardDrivePartitionFormat.MBR)
                        case HardDrivePartitionFormat.GUID.ioMediaContent:
                                return Loader(path: path, mountPoint: mountPoint, ioMedia: ioMedia, ioMediaWhole: parent, scheme: HardDrivePartitionFormat.GUID)
                        default:
                                throw BootoptionError.internal(errorMessage: "failed to obtain whole disk IOMedia entry, value for \(kIOMediaContentKey) was \(String(describing: ioMediaContent))", file: #file, function: #function)
                        }
                        
                default:
                        throw BootoptionError.internal(errorMessage: "parent IOReg node's class of \(ioClass) for volume '\(mountPoint)' is not supported", file: #file, function: #function)
                }
        }
        
        private func mountPoint(forPath path: String) -> String? {
                guard let urls: [URL] = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil) else {
                        return nil
                }
                
                let mountPoints: [String] = urls.map { $0.path }
                
                for mountPoint in (mountPoints.sorted { $0.count > $1.count }) {
                        if let range = path.uppercased().range(of: mountPoint.uppercased()), range.lowerBound == path.startIndex {
                                return mountPoint
                        }
                }
                
                return nil
        }
        
        private func assertFileHasMagic(_ path: String) throws {
                let fileHandle = FileHandle.init(forReadingAtPath: path)
                
                guard let data = fileHandle?.readData(ofLength: 2) else {
                        throw BootoptionError.file(errorMessage: "'\(path)' could not be read")
                }
                
                guard [UInt8](data) == [0x4d, 0x5a] else {
                        throw BootoptionError.file(errorMessage: "'\(path)' is not an EFI loader")
                }
                
                Debug.log("%@", type: .info, argsList: data)
        }
}
