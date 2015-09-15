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
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("WriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        //var readError: NSError? = nil
        var index = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                index++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("UnicodeWriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        var index = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                index++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        

        var index = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                index++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        var reverseWriteError: NSError? = nil
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result: Bool
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                reverseWriteError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        
        var forwardIndex = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
                let reverseIndex = testFilePaths.count - 1 - forwardIndex

                let expectedData = testFileData[reverseIndex]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                forwardIndex++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        

        var index = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                index++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        var reverseWriteError: NSError? = nil
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result: Bool
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                reverseWriteError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        

        var forwardIndex = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
                let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
                let expectedData = testFileData[reverseIndex]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                forwardIndex++;
                })
        } catch {

        }
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_NoOverwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("RewriteDataTest.zip")
        let archive = UZKArchive.zipArchiveAtURL(testArchiveURL)
        
        var writeError: NSError? = nil
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, overwrite: false, progress: nil)
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        

        var index = 0
        
        do {
            try archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                index++;
                })
        } catch {
            
        }
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        
        var reverseWriteError : NSError?
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            let result: Bool
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, overwrite: false,
                                progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                reverseWriteError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(reverseWriteError, "Error writing to file \(testFilePaths[x]) with data of " +
                "file \(testFilePaths[i]): \(reverseWriteError)")
        }
        
        var listError: NSError? = nil
        let newFileList: [AnyObject]!
        do {
            newFileList = try archive.listFileInfo()
        } catch let error as NSError {
            listError = error
            newFileList = nil
        }
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
        
        for _ in 0..<100 {
            var writeError: NSError? = nil
            
            let result: Bool
            do {
                try archive.writeData(testFileData!, filePath: testFilename, fileDate: nil,
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data")
            XCTAssertNil(writeError, "Error writing to file \(testFileURL): \(writeError)")
            
            let fm = NSFileManager.defaultManager()
            let fileAttributes = (try! fm.attributesOfItemAtPath(testArchiveURL.path!)) 
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
        
        let result: Bool
        do {
            try archive.writeData(testFileData!, filePath: testFilename, fileDate: nil,
                        compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                            #if DEBUG
                                NSLog("Compressing data: %f%% complete", percentCompressed)
                            #endif
                        })
            result = true
        } catch let error as NSError {
            writeError = error
            result = false
        }
        
        XCTAssertTrue(result, "Error writing archive data")
        XCTAssertNil(writeError, "Error writing to file \(testFileURL): \(writeError)")
        
        let fileList = (try! archive.listFileInfo()) as! [UZKFileInfo]
        let writtenFileInfo = fileList.first!
        
        let expectedDate = NSDate().timeIntervalSinceReferenceDate
        let actualDate = writtenFileInfo.timestamp.timeIntervalSinceReferenceDate
        
        XCTAssertEqualWithAccuracy(actualDate, expectedDate, accuracy: 30, "Incorrect default date value written to file")
    }
    
    func testWriteData_PasswordProtected() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("SwiftWriteDataTest.zip")
        let password = "111111"
        
        let writeArchive = UZKArchive.zipArchiveAtPath(testArchiveURL.path!, password: password)
        
        var writeError: NSError? = nil
        
        for testFilePath in testFilePaths {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            let result: Bool
            do {
                try writeArchive.writeData(fileData!, filePath: testFilePath)
                result = true
            } catch let error as NSError {
                writeError = error
                result = false
            }
            
            XCTAssertTrue(result, "Error writing archive data at path \(testFilePath)")
            XCTAssertNil(writeError, "Error writing to file \(testFilePath): \(writeError)")
        }
        
        // Read with UnzipKit
        
        let readArchive = UZKArchive.zipArchiveAtPath(testArchiveURL.path!, password: password)
        XCTAssertTrue(readArchive.isPasswordProtected(), "Archive is not marked as password-protected")
        
        var index = 0
        
        do {
            try readArchive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
                let expectedData = testFileData[index]
                let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
                XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
                XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
                XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
                ++index
                })
        } catch {
            
        }
        
        XCTAssertEqual(index, testFilePaths.count, "Not all files enumerated")
        
        // Read with the unzip command line tool
        let success = extractArchive(testArchiveURL, password: password)
        XCTAssertTrue(success, "Failed to extract the archive on the command line")
    }
    
}
