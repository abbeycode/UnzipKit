//
//  FileSystemTests.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/7/17.
//  Copyright © 2017 Abbey Code. All rights reserved.
//

import XCTest
import UnzipKit

class FileSystemTests: UZKArchiveTestCase {
    
    let allFileSystems = [
        FileSystem.HFS,
        FileSystem.APFS,
    ]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    #if os(OSX)

    func testTypicalFilename() {
        guard #available(macOS 10.12, *) else {
            NSLog("Skipping test on OS version without APFS")
            return
        }
        
        for fileSystem in allFileSystems {
            NSLog("Testing ASCII filename with \(fileSystem)")
            let testArchiveURL = self.testFileURLs["Test Archive.zip"] as! URL
            let archiveName = testArchiveURL.lastPathComponent
            NSLog("Original ZIP file: \(testArchiveURL)")
            
            // Write that zip file to contents of a DMG and mount it
            let tempDirURL = URL(fileURLWithPath: self.randomDirectoryName())
            let dmgSourceFolderURL = tempDirURL.appendingPathComponent("DMGSource")
            try! FileManager.default.createDirectory(at: dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
            try! FileManager.default.copyItem(at: testArchiveURL, to: dmgSourceFolderURL.appendingPathComponent(archiveName))
            let dmgURL = tempDirURL.appendingPathComponent("FileSystemTests-testTypicalFilename_\(fileSystem).dmg")
            let mountPoint = createAndMountDMG(path: dmgURL, source: dmgSourceFolderURL, fileSystem: fileSystem)!
            defer {
                unmountDMG(URL: mountPoint)
            }
            
            let volumeArchiveURL = mountPoint.appendingPathComponent(archiveName)
            NSLog("path: \(volumeArchiveURL)")
            
            let archive = try! UZKArchive(url: volumeArchiveURL)
            
            let extractFolderURL = tempDirURL.appendingPathComponent("Extraction")
            try! FileManager.default.createDirectory(at: extractFolderURL, withIntermediateDirectories: true, attributes: [:])
            
            do {
                try archive.extractFiles(to: extractFolderURL.path, overwrite: false, progress: nil)
            } catch let err {
                XCTFail("Failed to extract from \(fileSystem): \(err)")
            }
        }
    }
    
    func testNonCanonicalFilename() {
        guard #available(macOS 10.12, *) else {
            NSLog("Skipping test on OS version without APFS")
            return
        }
        
        for fileSystem in allFileSystems {
            NSLog("Testing Non-Canonical filename with \(fileSystem)")
            let testArchiveURL = self.testFileURLs["Test Archive.zip"] as! URL
            NSLog("Original ZIP file: \(testArchiveURL)")
            
            var nonCanonicalArchiveName = "\u{212B}rchive.zip"
            NSLog("Non-canonical name: \(nonCanonicalArchiveName)")
            
            // Write that zip file to contents of a DMG and mount it
            let tempDirURL = URL(fileURLWithPath: self.randomDirectoryName())
            let dmgSourceFolderURL = tempDirURL.appendingPathComponent("DMGSource")
            try! FileManager.default.createDirectory(at: dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
            try! FileManager.default.copyItem(at: testArchiveURL, to: dmgSourceFolderURL.appendingPathComponent(nonCanonicalArchiveName))
            let dmgURL = tempDirURL.appendingPathComponent("FileSystemTests-testTypicalFilename_\(fileSystem).dmg")
            let mountPoint = createAndMountDMG(path: dmgURL, source: dmgSourceFolderURL, fileSystem: fileSystem)!
            defer {
                unmountDMG(URL: mountPoint)
            }
            
            let canonicalArchiveName = nonCanonicalArchiveName.decomposedStringWithCanonicalMapping
            let volumeArchiveURL = mountPoint.appendingPathComponent(canonicalArchiveName)
            NSLog("Path in \(fileSystem) volume: \(volumeArchiveURL)")
            
            let archive = try! UZKArchive(url: volumeArchiveURL)
            
            let extractFolderURL = tempDirURL.appendingPathComponent("Extraction")
            try! FileManager.default.createDirectory(at: extractFolderURL, withIntermediateDirectories: true, attributes: [:])
            
            do {
                try archive.extractFiles(to: extractFolderURL.path, overwrite: false, progress: nil)
            } catch let err {
                XCTFail("Failed to extract from \(fileSystem): \(err)")
            }
        }
    }

    #endif

}
