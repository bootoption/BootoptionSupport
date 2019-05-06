/*
 * Loader.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

public struct Loader {
        public let path: String
        public let mountPoint: String
        public let ioMedia: RegistryEntry
        public let ioMediaWhole: RegistryEntry
        public let partitionFormat: HardDrivePartitionFormat
        
        var filesystemPath: String {
                let substring = path.stringFromSubSequence(startIndexOffsetBy: mountPoint.count)
                let components = substring.split(separator: "/").filter({ !$0.isEmpty })
                let filesystemPath = "\\" + components.joined(separator: "\\")
                Debug.log("Loader filesystem mount point: %@", type: .info, argsList: mountPoint)
                Debug.log("Computed filesystem path: %@", type: .info, argsList: filesystemPath)
                return filesystemPath
        }
        
        internal init(path: String, mountPoint: String, ioMedia: RegistryEntry, ioMediaWhole: RegistryEntry, scheme: HardDrivePartitionFormat) {
                self.path = path
                self.mountPoint = mountPoint
                self.ioMedia = ioMedia
                self.ioMediaWhole = ioMediaWhole
                self.partitionFormat = scheme
                LoaderFactory.default.setLoader(path: path, loader: self)
                Debug.log("%@ initialized", type: .info, argsList: type(of: self))
        }
}
