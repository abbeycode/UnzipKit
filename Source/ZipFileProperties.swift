//
//  ZipFileArgs.swift
//  UnzipKit
//
//  Created by Dov Frankel on 8/1/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import Foundation

// Not a struct because of Objective-C compatibility
@objc public class ZipFileProperties: NSObject {
    
    
    // MARK: - Required
    
    /// The full path and filename of the file to be written
    @objc public var fullFilePath: String
    
    
    // MARK: - Optional/Defaulted
    
    /// The UZKCompressionMethod to use (Default, None, Fastest, Best)
    @objc public var compressionMethod = UZKCompressionMethod.default
    
    /**
     The CRC-32 checksum for the data being written. Only required
     if encrypting the file, otherwise it will be calculated automatically
     */
    @objc public var crc: UInt = 0

    /**
     If true, and the file exists, delete it before writing. If false, append
     the data into the archive without removing it first (legacy Objective-Zip
     behavior). Turn this off to gain speed at the expense of creating bloated
     archives. Defaults to true
     */
    @objc public var overwriteIfInArchive = true
    
    /// Override the password associated with the rest of the archive (not a recommended practice)
    @objc public var password: String? = nil
    
    /**
     The desired POSIX permissions of the archived file (e.g. 0o644 in Swift
     or 0644U in Objective-C). Defaults to 644 (Read/Write for owner,
     read-only for group and others)
     */
    @objc public var permissions: Int16 = 0o644
    
    /// The timestamp of the file to be written
    @objc public var timestamp: Date?
    
    
    // MARK: - Initializer
    
    @objc public init(_ fullFilePath: String) {
        self.fullFilePath = fullFilePath
    }
    
    
    // MARK: - Overrides
    
    public override var description: String {
        let crcStr = String(crc, radix: 16).uppercased()
        let password = self.password != nil ? "<SPECIFIED>" : "none"
        let permissionStr = String(permissions, radix: 8).uppercased()

        return """
            { fullFilePath: \(fullFilePath), compressionMethod: \(compressionMethod.rawValue), crc: \(crcStr),
            overwriteIfInArchive: \(overwriteIfInArchive), password: \(password),
            permissions: \(permissionStr), timestamp: \(timestamp?.description ?? "none") }
            """.replacingOccurrences(of: "\n", with: " ");
    }

}
