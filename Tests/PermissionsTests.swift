//
//  PermissionsTests.swift
//  UnzipKitTests
//
//  Created by Dov Frankel on 6/24/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import XCTest

class PermissionsTests: UZKArchiveTestCase {

    func testExtraction() {
        let archive = try! UZKArchive(url: self.testFileURLs!.value(forKey: "Test Permissions Archive.zip") as! URL)
        
        let extractDirectory = self.randomDirectory(withPrefix: "PermissionsTest")!
        let extractURL = self.tempDirectory.appendingPathComponent(extractDirectory)
        
        try! archive.extractFiles(to: extractURL.path, overwrite: false)
        let file700 = extractURL.appendingPathComponent("test/1.txt")
        let file664 = extractURL.appendingPathComponent("test/paging.m4a")
        
        NSLog("Extracted to \(extractURL.path)")
        
        let file700Permissions = try! FileManager.default.attributesOfItem(atPath: file700.path)[.posixPermissions] as! NSNumber
        XCTAssertEqual(file700Permissions.int16Value, 0o700)
        
        let file664Permissions = try! FileManager.default.attributesOfItem(atPath: file664.path)[.posixPermissions] as! NSNumber
        XCTAssertEqual(file664Permissions.int16Value, 0o664)
    }

}
