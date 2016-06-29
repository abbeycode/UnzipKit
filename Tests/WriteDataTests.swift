//
//  WriteDataTests.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import XCTest
import UnzipKit

class WriteDataTests: UZKArchiveTestCase {

    func testWriteData() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().dateFromString("12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().dateFromString("12/22/2014 11:54 PM")]
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("WriteDataTest.zip")
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
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
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
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
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePaths[x]) with data of " +
                    "file \(testFilePaths[i]): \(error)")
            }
        }
        
        var forwardIndex = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex += 1;
        })
        
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
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: unicodeFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePaths[x]) with data of " +
                    "file \(testFilePaths[i]): \(error)")
            }
        }
        
        var forwardIndex = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex += 1;
        })
        
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
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerate() {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try archive.writeData(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                compressionMethod: .Default, password: nil, overwrite: false, progress: nil)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.writeData(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .Default, password: nil, overwrite: false,
                                progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePaths[x]) with data of " +
                    "file \(testFilePaths[i]): \(error)")
            }
        }
        
        let newFileList = try! archive.listFileInfo()
        
        // This is the most we can guarantee, the number of files in the directory
        XCTAssertEqual(newFileList.count, testFilePaths.count * 2, "Files not appended correctly")
    }
    
    func testWriteData_MultipleWrites() {
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("MultipleDataWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! NSURL
        let testFileData = NSData(contentsOfURL: testFileURL)!
        
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        var lastFileSize: UInt64 = 0
        
        for _ in 0..<100 {
            do {
                try archive.writeData(testFileData, filePath: testFilename, fileDate: nil,
                                compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFileURL): \(error)")
            }
            
            let fm = NSFileManager.defaultManager()
            let fileAttributes = try! fm.attributesOfItemAtPath(testArchiveURL.path!) 
            let fileSize = fileAttributes[NSFileSize] as! NSNumber
            
            if lastFileSize > 0 {
                XCTAssertEqual(lastFileSize, fileSize.unsignedLongLongValue, "File changed size between writes")
            }
            
            lastFileSize = fileSize.unsignedLongLongValue
        }
    }
    
    func testWriteData_ManyFiles_MemoryUsage_ForProfiling() {
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("ManyFilesMemoryUsageTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! NSURL
        let testFileData = NSData(contentsOfURL: testFileURL)!
        
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        for i in 1...1000 {
            do {
                try archive.writeData(testFileData, filePath: "File \(i).txt", fileDate: nil,
                                compressionMethod: .Default, password: nil, overwrite: true, progress: nil)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFileURL): \(error)")
            }
        }
    }
    
    func testWriteData_DefaultDate() {
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("DefaultDateWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! NSURL
        let testFileData = NSData(contentsOfURL: testFileURL)!
        
        let archive = try! UZKArchive(URL: testArchiveURL)
        
        do {
            try archive.writeData(testFileData, filePath: testFilename, fileDate: nil,
                        compressionMethod: .Default, password: nil, progress: { (percentCompressed) -> Void in
                            #if DEBUG
                                NSLog("Compressing data: %f%% complete", percentCompressed)
                            #endif
                        })
        } catch let error as NSError {
            XCTFail("Error writing to file \(testFileURL): \(error)")
        }
        
        let fileList = try! archive.listFileInfo()
        let writtenFileInfo = fileList.first!
        
        let expectedDate = NSDate().timeIntervalSinceReferenceDate
        let actualDate = writtenFileInfo.timestamp.timeIntervalSinceReferenceDate
        
        XCTAssertEqualWithAccuracy(actualDate, expectedDate, accuracy: 30, "Incorrect default date value written to file")
    }
    
    #if os(OSX)
    func testWriteData_PasswordProtected() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sort(<)
        var testFileData = [NSData]()
        
        let testArchiveURL = tempDirectory.URLByAppendingPathComponent("SwiftWriteDataTest.zip")
        let password = "111111"
        
        let writeArchive = try! UZKArchive(path: testArchiveURL.path!, password: password)
        
        for testFilePath in testFilePaths {
            let fileData = NSData(contentsOfURL: testFileURLs[testFilePath] as! NSURL)
            testFileData.append(fileData!)
            
            do {
                try writeArchive.writeData(fileData!, filePath: testFilePath)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        // Read with UnzipKit
        
        let readArchive = try! UZKArchive(path: testArchiveURL.path!, password: password)
        XCTAssertTrue(readArchive.isPasswordProtected(), "Archive is not marked as password-protected")
        
        var index = 0
        
        try! readArchive.performOnDataInArchive({ (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, UnsafePointer<Bytef>(expectedData.bytes), uInt(expectedData.length))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.CRC, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssertEqual(index, testFilePaths.count, "Not all files enumerated")
        
        // Read with the unzip command line tool
        let success = extractArchive(testArchiveURL, password: password)
        XCTAssertTrue(success, "Failed to extract the archive on the command line")
    }
    
    func testWriteData_ExternalVolume() {
        // Create a simple zip file
        let tempDirURL = NSURL(fileURLWithPath: self.randomDirectoryName())
        let textFileName = "testWriteData_ExternalVolume.txt"
        let textFileURL = tempDirURL.URLByAppendingPathComponent(textFileName)
        try! NSFileManager.defaultManager().createDirectoryAtURL(tempDirURL, withIntermediateDirectories: true, attributes: [:])
        try! "This is the original text".writeToURL(textFileURL, atomically: false, encoding: NSUTF8StringEncoding)
        let tempZipFileURL = self.archiveWithFiles([textFileURL])
        NSLog("Original ZIP file: \(tempZipFileURL.path!)")
        
        // Write that zip file to contents of a DMG
        let dmgSourceFolderURL = tempDirURL.URLByAppendingPathComponent("DMGSource")
        try! NSFileManager.defaultManager().createDirectoryAtURL(dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
        try! NSFileManager.defaultManager().copyItemAtURL(tempZipFileURL, toURL: dmgSourceFolderURL.URLByAppendingPathComponent(tempZipFileURL.lastPathComponent!))
        let dmgURL = tempDirURL.URLByAppendingPathComponent("testWriteData_ExternalVolume.dmg")
        createDMG(path: dmgURL, source: dmgSourceFolderURL)
        NSLog("Disk image: \(dmgURL.path!)")
        
        // Mount the DMG
        let mountPoint = mountDMG(dmgURL)!
        
        // Update a file from the archive with overwrite=YES
        let externalVolumeZipURL = NSURL(fileURLWithPath: mountPoint).URLByAppendingPathComponent(tempZipFileURL.lastPathComponent!)
        let archive = try! UZKArchive(URL: externalVolumeZipURL)
        let newTextData = "This is the new text".dataUsingEncoding(NSUTF8StringEncoding)
        var writeSuccessful = true
        do {
            try archive.writeData(newTextData!, filePath: textFileName, fileDate: nil,
                                  compressionMethod: UZKCompressionMethod.Default, password: nil,
                                  overwrite: true, progress: nil)
        } catch let error {
            NSLog("Error writing data to archive on external volume: \(error)")
            writeSuccessful = false
        }
        
        unmountDMG(mountPoint)
        
        XCTAssertTrue(writeSuccessful, "Failed to update archive on external volume")
    }
    
    func createDMG(path dmgURL: NSURL, source: NSURL) {
        let task = NSTask()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["create",
                          "-fs", "HFS+",
                          "-volname", dmgURL.URLByDeletingPathExtension!.lastPathComponent!,
                          "-srcfolder", source.path!,
                          dmgURL.path!]

        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            NSLog("Failed to create DMG: \(dmgURL.path!)");
        }
    }
    
    func mountDMG(dmgURL: NSURL) -> String? {
        let task = NSTask()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["attach", "-plist", dmgURL.path!]
        
        let outputPipe = NSPipe()
        task.standardOutput = outputPipe
        
        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            NSLog("Failed to attach DMG: \(dmgURL.path!)");
            return nil
        }
        
        let readHandle = outputPipe.fileHandleForReading
        let outputData = readHandle.readDataToEndOfFile()
        let outputPlist = try! NSPropertyListSerialization.propertyListWithData(outputData,
                                                                                options: .Immutable,
                                                                                format: nil)

        let entities = outputPlist["system-entities"] as AnyObject as! [[String:AnyObject]]
        let hfsEntry = entities.filter{ $0["content-hint"] as! String == "Apple_HFS" }.first!
        let mountPoint = hfsEntry["mount-point"] as! String
        
        return mountPoint
    }
    
    func unmountDMG(mountPoint: String) {
        let task = NSTask()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["detach", mountPoint]
        
        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            NSLog("Failed to unmount DMG: \(unmountDMG)");
        }
    }

    #endif
    
}
