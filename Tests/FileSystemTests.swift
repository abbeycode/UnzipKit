//
//  FileSystemTests.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/7/17.
//  Copyright © 2017 Abbey Code. All rights reserved.
//

import XCTest

class FileSystemTests: UZKArchiveTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTypicalFilename_APFS() {
        guard #available(macOS 10.12, *) else {
            NSLog("Skipping test on OS version without APFS")
            return
        }
        
        let testArchiveURL = self.testFileURLs["Test Archive.zip"] as! URL
        let archiveName = testArchiveURL.lastPathComponent
        NSLog("Original ZIP file: \(testArchiveURL)")
        
        // Write that zip file to contents of a DMG and mount it
        let tempDirURL = URL(fileURLWithPath: self.randomDirectoryName())
        let dmgSourceFolderURL = tempDirURL.appendingPathComponent("DMGSource")
        try! FileManager.default.createDirectory(at: dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
        try! FileManager.default.copyItem(at: testArchiveURL, to: dmgSourceFolderURL.appendingPathComponent(archiveName))
        let dmgURL = tempDirURL.appendingPathComponent("FileSystemTests-testTypicalFilename_APFS.dmg")
        let mountPoint = createAndMountDMG(path: dmgURL, source: dmgSourceFolderURL, fileSystem: .APFS)!
        NSLog("Disk image: \(dmgURL.path)")
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
            NSLog("Failed to extract: \(err)")
            XCTFail()
        }
    }
    
    func testNonCanonicalFilename_APFS() {
        guard #available(macOS 10.12, *) else {
            NSLog("Skipping test on OS version without APFS")
            return
        }
        
        let testArchiveURL = self.testFileURLs["Test Archive.zip"] as! URL
        NSLog("Original ZIP file: \(testArchiveURL)")

        var archiveName = "\u{212B}rchive.zip".decomposedStringWithCanonicalMapping
        archiveName.unicodeScalars.remove(at: archiveName.unicodeScalars.startIndex)
        
        // Write that zip file to contents of a DMG and mount it
        let tempDirURL = URL(fileURLWithPath: self.randomDirectoryName())
        let dmgSourceFolderURL = tempDirURL.appendingPathComponent("DMGSource")
        try! FileManager.default.createDirectory(at: dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
        try! FileManager.default.copyItem(at: testArchiveURL, to: dmgSourceFolderURL.appendingPathComponent(archiveName))
        let dmgURL = tempDirURL.appendingPathComponent("FileSystemTests-testTypicalFilename_APFS.dmg")
        let mountPoint = createAndMountDMG(path: dmgURL, source: dmgSourceFolderURL, fileSystem: .APFS)!
        NSLog("Disk image: \(dmgURL.path)")
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
            NSLog("Failed to extract: \(err)")
            XCTFail()
        }
    }

}
