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
        let testFileURLs = (self.testFileURLs as NSDictionary) as! [String: NSURL]
        
        for testArchiveName in testArchives {
            var thrownError: ErrorType?
            
            do {
                let archive = try UZKArchive(URL: testFileURLs[testArchiveName]!)
                try archive.extractDataFromFile("Test File A.txt", progress: nil)
            } catch let error {
                thrownError = error
            }
            
            XCTAssertNotNil(thrownError, "No error thrown for archive \(testArchiveName)")

            guard let thrownNSError = thrownError as? NSError else {
                XCTFail("Error returned is not an NSError (\(testArchiveName))")
                continue
            }
            
            XCTAssertEqual(thrownNSError.code, UZKErrorCode.InvalidPassword.rawValue,
                "Unexpected error code returned for \(testArchiveName)");
        }
    }
    
    func testExtractData_InvalidArchive() {
        let testArchives = ["Test File A.txt"]
        let testFileURLs = (self.testFileURLs as NSDictionary) as! [String: NSURL]

        for testArchiveName in testArchives {
            var thrownError: ErrorType?
            
            do {
                let archive = try UZKArchive(URL: testFileURLs[testArchiveName]!)
                try archive.extractDataFromFile("Test File A.txt", progress: nil)
            } catch let error {
                thrownError = error
            }
            
            XCTAssertNotNil(thrownError, "No error thrown for archive \(testArchiveName)")
            
            guard let thrownNSError = thrownError as? NSError else {
                XCTFail("Error returned is not an NSError (\(testArchiveName))")
                continue
            }
            
            XCTAssertEqual(thrownNSError.code, UZKErrorCode.BadZipFile.rawValue,
                "Unexpected error code returned for \(testArchiveName)");
        }
    }
    
}
