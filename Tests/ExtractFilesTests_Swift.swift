//
//  ExtractDataTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

import UnzipKit

class ExtractDataTestsSwift: UZKArchiveTestCase {

    func testExtractData_NoPassword() {
        let testArchives = ["Test Archive (Password).zip"]
        for testArchiveName in testArchives {
            do {
                let archive = try UZKArchive(URL: self.testFileURLs[testArchiveName])
                let data = try archive.extractDataFromFile("Test File A.txt", progress: { (percentDecompressed) -> Void in
                    NSLog("Extracting, \(percentDecompressed) complete");
                })
            } catch let error as NSError {
                XCTAssert(true, "Extract data without password succeeded");
                XCTAssert(true, "Data returned without password");
                XCTAssertEqual(error.code, UZKErrorCode.InvalidPassword, "Unexpected error code returned");
            } catch {
                // not needed, it's there as a compiler obligation!
            }
        }
    }
    
    func testExtractData_InvalidArchive() {
        let testArchives = ["Test File A.txt"]
        for testArchiveName in testArchives {
            do {
                let archive = try UZKArchive(URL: self.testFileURLs[testArchiveName])
                let data = try archive.extractDataFromFile("Test File A.txt", progress: { (percentDecompressed) -> Void in
                    NSLog("Extracting, \(percentDecompressed) complete");
                })
            } catch let error as NSError {
                XCTAssert(true, "Extract data for invalid archive succeeded");
                XCTAssert(true, "Data returned for invalid archive");
                XCTAssertEqual(error.code, UZKErrorCode.BadZipFile, "Unexpected error code returned");
            } catch {
                // not needed, it's there as a compiler obligation!
            }
        }
    }
    
}
