/*
 * Loader.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit.storage

public enum PartitionScheme {
        case GUID
        case FDisk
        var ioClass: String {
                switch self {
                case .GUID:
                        return "IOGUIDPartitionScheme"
                case .FDisk:
                        return "IOFDiskPartitionScheme"
                }
        }
}

public class LoaderManager {
        static public let `default` = LoaderManager()
        
        private init() {
        }
        
        private var loaders: [String: Loader] = [:]
        
        public func setLoader(path: String, loader: Loader) {
                loaders.updateValue(loader, forKey: path)
        }
        
        public func getLoader(path: String) throws -> Loader {
                if loaders.index(forKey: path) != nil {
                        if let loader = loaders[path] {
                                /* Debug.log("Returning previously initialized Loader", type: .info) */
                                return loader
                        } else {
                                throw BootoptionError.internal(message: "failed to return Loader instance", Location())
                        }
                } else {
                        /* Debug.log("Initializing new Loader", type: .info) */
                        try assertFileExistsAtPath(path)
                        try assertFileHasMagic(path)
                        guard let mountPointUrl = mountedVolumeURL(forPath: path) else {
                                throw BootoptionError.internal(message: "failed to get a mounted volume URL from loader path", Location())
                        }
                        let mountPoint = mountPointUrl.path
                        guard let ioMedia = RegistryEntry(IOMediaWithMountPoint: mountPointUrl.path as CFString) else {
                                throw BootoptionError.internal(message: "failed to create IOMedia object from mount point", Location())
                        }
                        guard let parent = RegistryEntry(parentOf: ioMedia.entry) else {
                                throw BootoptionError.internal(message: "failed to create parent entry (1)", Location())
                        }
                        guard let ioClass = parent.createCFProperty(forKey: kIOClassKey) as? String else {
                                throw BootoptionError.internal(message: "failed to create property for kIOClassKey", Location())
                        }
                        switch ioClass {
                        case PartitionScheme.GUID.ioClass, PartitionScheme.FDisk.ioClass:
                                guard let parent = RegistryEntry(parentOf: parent.entry) else {
                                        throw BootoptionError.internal(message: "failed to create parent entry (2)", Location())
                                }
                                
                                guard parent.createCFProperty(forKey: kIOMediaWholeKey) as? Bool == true else {
                                        throw BootoptionError.internal(message: "failed to create property for kIOMediaWholeKey", Location())
                                }
                                guard let value = parent.createCFProperty(forKey: kIOMediaContentKey) as? String else {
                                        throw BootoptionError.internal(message: "failed to create property for kIOMediaContentKey", Location())
                                }
                                switch value {
                                case "GUID_partition_scheme":
                                        return Loader(path: path, mountPoint: mountPoint, ioMedia: ioMedia, ioMediaWhole: parent, scheme: PartitionScheme.GUID)
                                case "FDisk_partition_scheme":
                                        return Loader(path: path, mountPoint: mountPoint, ioMedia: ioMedia, ioMediaWhole: parent, scheme: PartitionScheme.FDisk)
                                default:
                                        throw BootoptionError.internal(message: "failed to obtain whole disk IOMedia entry, value for \(kIOMediaContentKey) was \(String(describing: value))", Location())
                                }
                        default:
                                throw BootoptionError.internal(message: "the volume's parent class of \(ioClass) is not supported", Location())
                        }
                }
        }
        
        private func mountedVolumeURL(forPath path: String) -> URL? {
                let mountedVolumeURLs: [URL] = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil)!
                var pathComponents = URL(fileURLWithPath: path).pathComponents
                pathComponents.removeFirst()
                var chosen: URL?
                while pathComponents.count > 0, chosen == nil {
                        pathComponents.removeLast()
                        let path = "/" + pathComponents.joined(separator: "/")
                        for volume in mountedVolumeURLs {
                                if path.uppercased() == volume.path.uppercased() {
                                        chosen = volume
                                        break
                                }
                        }
                }
                Debug.log("Chosen volume URL: %@", type: .info, argsList: chosen as Any)
                return chosen
        }
        
        private func assertFileExistsAtPath(_ path: String) throws {
                var isDirectory = ObjCBool(false)
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
                        throw BootoptionError.file(message: "file not found at path '\(path)'")
                }
                if isDirectory.boolValue == true {
                        throw BootoptionError.file(message: "'\(path)' is a directory")
                }
        }
        
        private func assertFileHasMagic(_ path: String) throws {
                let fileHandle = FileHandle.init(forReadingAtPath: path)
                if let data = fileHandle?.readData(ofLength: 2) {
                        guard [UInt8](data) == [0x4d, 0x5a] else {
                                throw BootoptionError.file(message: "'\(path)' is not an EFI loader")
                        }
                        Debug.log("%@", type: .info, argsList: data)
                } else {
                        Debug.log("Failed to read bytes from loader path", type: .error)
                }
        }
}

final public class Loader {
        public let path: String
        public let mountPoint: String
        public let ioMedia: RegistryEntry
        public let ioMediaWhole: RegistryEntry
        public let partitionScheme: PartitionScheme
        
        fileprivate init(path: String, mountPoint: String, ioMedia: RegistryEntry, ioMediaWhole: RegistryEntry, scheme: PartitionScheme) {
                self.path = path
                self.mountPoint = mountPoint
                self.ioMedia = ioMedia
                self.ioMediaWhole = ioMediaWhole
                self.partitionScheme = scheme
                LoaderManager.default.setLoader(path: path, loader: self)
                Debug.log("%@ initialized", type: .info, argsList: type(of: self))
        }
}
