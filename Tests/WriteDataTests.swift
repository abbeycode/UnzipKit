//
//  WriteDataTests.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

import Cocoa
import XCTest

class WriteDataTests: UZKArchiveTestCase {

    func testWriteData() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("WriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in enumerate(testFilePaths) {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var readError: NSError? = nil
        var index = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index++;
            }, error: &readError)
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sorted(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("UnicodeWriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in enumerate(testFilePaths) {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var readError: NSError? = nil
        var index = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index++;
            }, error: &readError)
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in enumerate(testFilePaths) {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var readError: NSError? = nil
        var index = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index++;
            }, error: &readError)
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        var reverseWriteError: NSError? = nil
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result = archive.writeData(testFileData[x], filePath: testFilePaths[i],
                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &reverseWriteError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        
        var reverseReadError: NSError? = nil
        var forwardIndex = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex

            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex++;
            }, error: &reverseReadError)
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sorted(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in enumerate(testFilePaths) {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var readError: NSError? = nil
        var index = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index++;
            }, error: &readError)
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        var reverseWriteError: NSError? = nil
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result = archive.writeData(testFileData[x], filePath: testFilePaths[i],
                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &reverseWriteError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        
        var reverseReadError: NSError? = nil
        var forwardIndex = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex++;
            }, error: &reverseReadError)
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_NoOverwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in enumerate(testFilePaths) {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result = archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                compressionMethod: .Default, password: nil, overwrite: false, progress: nil, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var readError: NSError? = nil
        var index = 0
        
        archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index++;
            }, error: &readError)
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        
        var reverseWriteError: NSError? = nil
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result = archive.writeData(testFileData[x], filePath: testFilePaths[i],
                fileDate: testDates[x], compressionMethod: .Default, password: nil, overwrite: false,
                progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &reverseWriteError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        
        var listError: NSError? = nil
        let newFileList = archive.listFileInfo(&listError)
        XCTAssertNil(listError, "Error reading a re-written archive")
        
        // This is the most we can guarantee, the number of files in the directory
        XCTAssertEqual(newFileList.count, testFilePaths.count * 2, "Files not appended correctly")
    }
    
    func testWriteData_MultipleWrites() {
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("MultipleDataWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! NSURL
        let testFileData = NSData(contentsOfURL: testFileURL)
        
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var lastFileSize: UInt64 = 0
        
        for i in 0..<100 {
            var writeError: NSError? = nil
            
            let result = archive.writeData(testFileData, filePath: testFilename, fileDate: nil,
                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                    #if DEBUG
                        NSLog("Compressing data: %f%% complete", percentCompressed)
                    #endif
                }, error: &writeError)
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFileURL): \(writeError)")
            
            var fileSizeError: NSError? = nil
            let fm = NSFileManager.defaultManager()
            let fileAttributes = fm.attributesOfItemAtPath(testArchiveURL.path!, error: &fileSizeError) as! [String:AnyObject]
            let fileSize = fileAttributes[NSFileSize] as! NSNumber
            
            if lastFileSize > 0 {
                XCTAssertEqual(lastFileSize, fileSize.unsignedLongLongValue, "File changed size between writes")
            }
            
            lastFileSize = fileSize.unsignedLongLongValue
        }
    }
    
    func testWriteData_DefaultDate() {
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("DefaultDateWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! NSURL
        let testFileData = NSData(contentsOfURL: testFileURL)
        
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        let result = archive.writeData(testFileData, filePath: testFilename, fileDate: nil,
            compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                #if DEBUG
                    NSLog("Compressing data: %f%% complete", percentCompressed)
                #endif
            }, error: &writeError)
        
        XCTAssertTrue(result, "Error writing archive data")
        XCTAssertNil(writeError, "Error writing to file \(testFileURL): \(writeError)")
        
        var listError: NSError? = nil
        let fileList = archive.listFileInfo(&listError) as! [UZKFileInfo]
        let writtenFileInfo = fileList.first!
        
        let expectedDate = NSDate().timeIntervalSinceReferenceDate
        let actualDate = writtenFileInfo.timestamp.timeIntervalSinceReferenceDate
        
        XCTAssertEqualWithAccuracy(actualDate, expectedDate, 30, "Incorrect default date value written to file")
    }
    
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
        
        // Read with UnzipKit
        
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
        
        // Read with the unzip command line tool
        let success = extractArchive(testArchiveURL, password: password)
        XCTAssertTrue(success, "Failed to extract the archive on the command line")
    }
    
}
