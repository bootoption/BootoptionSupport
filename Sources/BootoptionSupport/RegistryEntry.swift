/*
 * RegistryEntry.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import IOKit

open class RegistryEntry {
        public let entry: io_registry_entry_t
        
        public func createCFProperty(forKey key: String) -> CFTypeRef? {
                return IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        
        public init?(fromPath path: String) {
                entry = IORegistryEntryFromPath(kIOMasterPortDefault, path)
                guard entry != 0 else {
                        return nil
                }
        }
        
        public init?(parentOf child: io_registry_entry_t) {
                var entry = io_registry_entry_t()
                IORegistryEntryGetParentEntry(child, kIOServicePlane, &entry)
                if entry == 0 {
                        return nil
                }
                self.entry = entry
        }
        
        public init?(IOMediaWithMountPoint mountPoint: CFString) {
                guard let session: DASession = DASessionCreate(kCFAllocatorDefault) else {
                        return nil
                }
                guard let url: CFURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, mountPoint, CFURLPathStyle(rawValue: 0)!, true) else {
                        return nil
                }
                guard let disk: DADisk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url) else {
                        return nil
                }
                entry = DADiskCopyIOMedia(disk)
        }
        
        public init?(IOMediaWithBSDName bsdName: String) {
                guard let session: DASession = DASessionCreate(kCFAllocatorDefault) else {
                        return nil
                }
                guard let disk: DADisk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, bsdName) else {
                        return nil
                }
                entry = DADiskCopyIOMedia(disk)
        }
        
        public init?(ancestorOf descendant: io_registry_entry_t, matchingIOClassName match: String) {
                var entry = descendant
                while entry != 0 {
                        IORegistryEntryGetParentEntry(entry, kIOServicePlane, &entry)
                        guard let className = IORegistryEntryCreateCFProperty(entry, kIOClassKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else {
                                continue
                        }
                        if className == match {
                                break
                        }
                }
                guard entry != 0 else {
                        return nil
                }
                self.entry = entry
        }
}
