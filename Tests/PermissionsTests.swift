//
//  PermissionsTests.swift
//  UnzipKitTests
//
//  Created by Dov Frankel on 6/24/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import XCTest

class PermissionsTests: UZKArchiveTestCase {
    
    #if os(OSX)
    func testReadFileInfo() {
        let permissionLevelsToTest: [Int16] = [
            0o777,
            0o707,
            0o770,
            0o477,
            0o666,
            0o606,
            0o660,
            0o466,
        ]
        
        let fileURLs: [URL] = permissionLevelsToTest.map {
            let textFile = self.emptyTextFile(ofLength: 20)!
            try! FileManager.default.setAttributes([.posixPermissions: $0],
                                                   ofItemAtPath: textFile.path)
            return textFile
        }
        
        let archiveURL = self.archive(withFiles: fileURLs)!
        let archive = try! UZKArchive(url: archiveURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expectedPermissions = zip(
            fileURLs.map { $0.lastPathComponent },
            permissionLevelsToTest
            )
            .reduce(into: [String:Int16]()) { result, pair in
                result[pair.0] = pair.1
        }
        let actualPermissions = fileInfo.reduce([String: Int16]()) {
            var resultDict = $0
            resultDict[$1.filename] = $1.posixPermissions
            return resultDict
            }
        
        XCTAssertEqual(actualPermissions, expectedPermissions)
    }
    
    func testExtraction() {
        let permissionLevelsToTest: [Int16] = [
            0o777,
            0o707,
            0o770,
            0o477,
            0o666,
            0o606,
            0o660,
            0o466,
        ]
        
        let fileURLs: [URL] = permissionLevelsToTest.map {
            let textFile = self.emptyTextFile(ofLength: 20)!
            try! FileManager.default.setAttributes([.posixPermissions: $0],
                                                   ofItemAtPath: textFile.path)
            return textFile
        }
        
        let archiveURL = self.archive(withFiles: fileURLs)!
        let archive = try! UZKArchive(url: archiveURL)
        
        let extractDirectory = self.randomDirectory(withPrefix: "PermissionsTest")!
        let extractURL = self.tempDirectory.appendingPathComponent(extractDirectory)
        
        try! archive.extractFiles(to: extractURL.path, overwrite: false)
        NSLog("Extracted to \(extractURL.path)")
        
        let expectedPermissions = zip(
            fileURLs.map { extractURL.appendingPathComponent($0.lastPathComponent).path },
            permissionLevelsToTest
        )
        
        for (path, expectedPermissionLevel) in expectedPermissions {
            let actualPermissions = try! FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as! NSNumber
            XCTAssertEqual(actualPermissions.int16Value, expectedPermissionLevel, "Permissions mismatch for \(path)")
        }
    }
    #endif

    func testWriteData_Default() {
        let testArchiveURL = tempDirectory.appendingPathComponent("PermissionsTestWriteData.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let writeArchive = try! UZKArchive(url: testArchiveURL)
        
        try! writeArchive.write(testFileData, filePath: testFilename)
        
        let readArchive = try! UZKArchive(url: testArchiveURL)
        let fileList = try! readArchive.listFileInfo()
        
        let writtenFileInfo = fileList.first { $0.filename == testFilename }
        let actualPermissions = writtenFileInfo!.posixPermissions
        
        XCTAssertEqual(actualPermissions, 0o644)
    }
    
    func testWriteData_NonDefault() {
        let testArchiveURL = tempDirectory.appendingPathComponent("PermissionsTestWriteData.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let writeArchive = try! UZKArchive(url: testArchiveURL)
        
        let expectedPermissions: Int16 = 0o742
        
        try! writeArchive.write(testFileData, filePath: testFilename, fileDate: nil, posixPermissions: expectedPermissions,
                                compressionMethod: .default, password: nil, overwrite: true)
        
        let readArchive = try! UZKArchive(url: testArchiveURL)
        let fileList = try! readArchive.listFileInfo()
        
        let writtenFileInfo = fileList.first { $0.filename == testFilename }
        let actualPermissions = writtenFileInfo!.posixPermissions
        
        XCTAssertEqual(actualPermissions, expectedPermissions)
    }

    func testWriteIntoBuffer_Default() {
        let testArchiveURL = tempDirectory.appendingPathComponent("PermissionsTestWriteBufferedData.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let writeArchive = try! UZKArchive(url: testArchiveURL)
        try! writeArchive.write(intoBuffer: testFilename) { (writeDataHandler, error) in
            testFileData.withUnsafeBytes({ buffer in
                writeDataHandler(buffer, UInt32(testFileData.count))
            })
        }
        
        let readArchive = try! UZKArchive(url: testArchiveURL)
        let fileList = try! readArchive.listFileInfo()
        
        let writtenFileInfo = fileList.first { $0.filename == testFilename }
        let actualPermissions = writtenFileInfo!.posixPermissions
        
        XCTAssertEqual(actualPermissions, 0o644)
    }

    func testWriteIntoBuffer_NonDefault() {
        let testArchiveURL = tempDirectory.appendingPathComponent("PermissionsTestWriteBufferedData_CustomPermissions.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let expectedPermissions: Int16 = 0o764
        
        let writeArchive = try! UZKArchive(url: testArchiveURL)
        try! writeArchive.write(intoBuffer: testFilename, fileDate: nil, posixPermissions: expectedPermissions,
                                compressionMethod: .default, overwrite: false, crc: 0, password: nil)
        { (writeDataHandler, error) in
            testFileData.withUnsafeBytes({ buffer in
                writeDataHandler(buffer, UInt32(testFileData.count))
            })
        }
        
        let readArchive = try! UZKArchive(url: testArchiveURL)
        let fileList = try! readArchive.listFileInfo()
        
        let writtenFileInfo = fileList.first { $0.filename == testFilename }
        let actualPermissions = writtenFileInfo!.posixPermissions
        
        XCTAssertEqual(actualPermissions, expectedPermissions)
    }

}
