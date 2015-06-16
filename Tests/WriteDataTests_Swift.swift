//
//  WriteDataTests_Swift.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

import Cocoa
import XCTest

class WriteDataTests_Swift: UZKArchiveTestCase {

    func testWriteData_PasswordProtected() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(<)
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("SwiftWriteDataTest.zip")
        let password = "111111"
    
        let writeArchive = UZKArchive.zipArchiveAtPath(testArchiveURL.path, password: password)
        
        var writeError: NSError? = nil
        
        for testFilePath in testFilePaths {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = writeArchive.writeData(fileData!, filePath: testFilePath, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data at path \(testFilePath)")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        let readArchive = UZKArchive.zipArchiveAtPath(testArchiveURL.path, password: password)
        XCTAssertTrue(readArchive.isPasswordProtected(), "Archive is not marked as password-protected")
        
        var readError: NSError? = nil
        var index = 0
        
        readArchive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            ++index
        }, error: &readError)
        
        XCTAssertEqual(index, testFilePaths.count, "Not all files enumerated")
    }
    
}
