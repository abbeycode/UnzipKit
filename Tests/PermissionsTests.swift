//
//  PermissionsTests.swift
//  UnzipKitTests
//
//  Created by Dov Frankel on 6/24/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import XCTest

class PermissionsTests: UZKArchiveTestCase {

    func testReadFileInfo() {
        let archive = try! UZKArchive(url: self.testFileURLs!.value(forKey: "Test Permissions Archive.zip") as! URL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expectedPermissions: [String: Int16] = [
            "test/1.txt": 0o700,
            "test/paging.m4a": 0o664
        ]
        let actualPermissions = fileInfo.reduce([String: Int16]()) {
            var resultDict = $0
            resultDict[$1.filename] = $1.posixPermissions.int16Value
            return resultDict
            }
            .filter { expectedPermissions.keys.contains($0.key) }
        
        XCTAssertEqual(actualPermissions, expectedPermissions)
    }
    
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
    
    func testWriteData_NonDefault() {
        let testArchiveURL = tempDirectory.appendingPathComponent("PermissionsTestWriteData.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)

        let writeArchive = try! UZKArchive(url: testArchiveURL)

        let expectedPermissions: Int16 = 0o700

        try! writeArchive.write(testFileData, filePath: testFilename, fileDate: nil, posixPermissions: UInt(expectedPermissions),
                           compressionMethod: .default, password: nil, overwrite: true)

        let readArchive = try! UZKArchive(url: testArchiveURL)
        let fileList = try! readArchive.listFileInfo()
        
        let writtenFileInfo = fileList.first { $0.filename == testFilename }
        let actualPermissions = writtenFileInfo!.posixPermissions.int16Value

        XCTAssertEqual(actualPermissions, expectedPermissions)
    }

}
