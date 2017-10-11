//
//  ExtractDataTests_Swift.swift
//  UnzipKit
//
//  Created by Dov Frankel on 2/11/16.
//  Copyright (c) 2016 Abbey Code. All rights reserved.
//

import UnzipKit

class ExtractDataTests_Swift: UZKArchiveTestCase {

    func testExtractData_NoPassword() {
        let testArchives = ["Test Archive (Password).zip"]
        let testFileURLs = (self.testFileURLs as NSDictionary) as! [String: URL]
        
        for testArchiveName in testArchives {
            var thrownError: Error?
            
            do {
                let archive = try UZKArchive(url: testFileURLs[testArchiveName]!)
                try archive.extractData(fromFile: "Test File A.txt")
            } catch let error {
                thrownError = error
            }
            
            XCTAssertNotNil(thrownError, "No error thrown for archive \(testArchiveName)")

            guard let thrownNSError = thrownError as NSError? else {
                XCTFail("Error returned is not an NSError (\(testArchiveName))")
                continue
            }
            
            XCTAssertEqual(thrownNSError.code, UZKErrorCode.invalidPassword.rawValue,
                "Unexpected error code returned for \(testArchiveName)");
        }
    }
    
    func testExtractData_InvalidArchive() {
        let testArchives = ["Test File A.txt"]
        let testFileURLs = (self.testFileURLs as NSDictionary) as! [String: URL]

        for testArchiveName in testArchives {
            var thrownError: Error?
            
            do {
                let archive = try UZKArchive(url: testFileURLs[testArchiveName]!)
                try archive.extractData(fromFile: "Test File A.txt")
            } catch let error {
                thrownError = error
            }
            
            XCTAssertNotNil(thrownError, "No error thrown for archive \(testArchiveName)")
            
            guard let thrownNSError = thrownError as NSError? else {
                XCTFail("Error returned is not an NSError (\(testArchiveName))")
                continue
            }
            
            XCTAssertEqual(thrownNSError.code, UZKErrorCode.badZipFile.rawValue,
                "Unexpected error code returned for \(testArchiveName)");
        }
    }
    
}
