//
//  ZipFileArgs.swift
//  UnzipKit
//
//  Created by Dov Frankel on 8/1/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import Foundation

// Not a struct because of Objective-C compatibility
public class ZipWriteArgs {
    
    
    // MARK: - Required
    
    /// The full path and filename of the file to be written
    public var fullFilePath: String
    
    
    // MARK: - Optional
    
    /// The UZKCompressionMethod to use (Default, None, Fastest, Best)
    public var compressionMethod = UZKCompressionMethod.default
    
    /**
     The CRC-32 checksum for the data being written. Only required
     if encrypting the file, otherwise it will be calculated automatically
     */
    public var crc: UInt32?

    /**
     If true, and the file exists, delete it before writing. If false, append
     the data into the archive without removing it first (legacy Objective-Zip
     behavior). Turn this off to gain speed at the expense of creating bloated
     archives. Defaults to true
     */
    public var overwriteIfInArchive = true
    
    /// Override the password associated with the rest of the archive (not a recommended practice)
    public var password: String? = nil
    
    /**
     The desired POSIX permissions of the archived file (e.g. 0o644 in Swift
     or 0644U in Objective-C). Defaults to 644 (Read/Write for owner,
     read-only for group and others)
     */
    public var permissions = 0o644
    
    /// The timestamp of the file to be written
    public var timestamp: Date?
    
    
    // MARK: - Initializer
    
    public init(_ fullFilePath: String) {
        self.fullFilePath = fullFilePath
    }
    
}
