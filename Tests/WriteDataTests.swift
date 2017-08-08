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
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(by: <)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().date(from: "12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/22/2014 11:54 PM")]
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("WriteDataTest.zip")
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerated() {
            let fileData = try? Data(contentsOf: testFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try archive.write(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                  compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sorted(by: <)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().date(from: "12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/22/2014 11:54 PM")]
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("UnicodeWriteDataTest.zip")
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerated() {
            let fileData = try? Data(contentsOf: unicodeFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try archive.write(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                  compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(by: <)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().date(from: "12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/22/2014 11:54 PM")]
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("RewriteDataTest.zip")
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerated() {
            let fileData = try? Data(contentsOf: testFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try archive.write(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                  compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.write(testFileData[x], filePath: testFilePaths[i],
                                  fileDate: testDates[x], compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
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
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_Overwrite_Unicode() {
        let testFilePaths = [String](nonZipUnicodeFilePaths as! Set<String>).sorted(by: <)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().date(from: "12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/22/2014 11:54 PM")]
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("RewriteDataTest.zip")
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerated() {
            let fileData = try? Data(contentsOf: unicodeFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try archive.write(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                  compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        NSLog("Testing a second write, by reversing the contents and timestamps of the files from the first run")
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.write(testFileData[x], filePath: testFilePaths[i],
                                fileDate: testDates[x], compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
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
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            XCTAssertEqual(fileInfo.filename, testFilePaths[forwardIndex], "Incorrect filename in archive");
            
            let reverseIndex = testFilePaths.count - 1 - forwardIndex
            
            let expectedData = testFileData[reverseIndex]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.timestamp, testDates[reverseIndex]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            forwardIndex += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
    }
    
    func testWriteData_NoOverwrite() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(by: <)
        let testDates = [
            UZKArchiveTestCase.dateFormatter().date(from: "12/20/2014 9:35 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/21/2014 10:00 AM"),
            UZKArchiveTestCase.dateFormatter().date(from: "12/22/2014 11:54 PM")]
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("RewriteDataTest.zip")
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for (index, testFilePath) in testFilePaths.enumerated() {
            let fileData = try? Data(contentsOf: testFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try archive.write(fileData!, filePath: testFilePath, fileDate: testDates[index],
                                  compressionMethod: .default, password: nil, overwrite: false, progress: nil)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        var index = 0
        
        try! archive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.timestamp, testDates[index]!, "Incorrect timestamp in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
            XCTAssertEqual(fileData, expectedData, "Data extracted doesn't match what was written")
            
            index += 1;
        })
        
        XCTAssert(index > 0, "No data iterated through")
        
        // Now write the files' contents to the zip in reverse
        
        for i in 0..<testFilePaths.count {
            let x = testFilePaths.count - 1 - i
            
            do {
                try archive.write(testFileData[x], filePath: testFilePaths[i],
                                  fileDate: testDates[x], compressionMethod: .default, password: nil, overwrite: false,
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
        let testArchiveURL = tempDirectory.appendingPathComponent("MultipleDataWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let archive = try! UZKArchive(url: testArchiveURL)
        
        var lastFileSize: UInt64 = 0
        
        for _ in 0..<100 {
            do {
                try archive.write(testFileData, filePath: testFilename, fileDate: nil,
                                  compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                    #if DEBUG
                                        NSLog("Compressing data: %f%% complete", percentCompressed)
                                    #endif
                })
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFileURL): \(error)")
            }
            
            let fm = FileManager.default
            let fileAttributes = try! fm.attributesOfItem(atPath: testArchiveURL.path) 
            let fileSize = fileAttributes[FileAttributeKey.size] as! NSNumber
            
            if lastFileSize > 0 {
                XCTAssertEqual(lastFileSize, fileSize.uint64Value, "File changed size between writes")
            }
            
            lastFileSize = fileSize.uint64Value
        }
    }
    
    func testWriteData_ManyFiles_MemoryUsage_ForProfiling() {
        let testArchiveURL = tempDirectory.appendingPathComponent("ManyFilesMemoryUsageTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let archive = try! UZKArchive(url: testArchiveURL)
        
        for i in 1...1000 {
            do {
                try archive.write(testFileData, filePath: "File \(i).txt", fileDate: nil,
                                  compressionMethod: .default, password: nil, overwrite: true, progress: nil)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFileURL): \(error)")
            }
        }
    }
    
    func testWriteData_DefaultDate() {
        let testArchiveURL = tempDirectory.appendingPathComponent("DefaultDateWriteTest.zip")
        let testFilename = nonZipTestFilePaths.first as! String
        let testFileURL = testFileURLs[testFilename] as! URL
        let testFileData = try! Data(contentsOf: testFileURL)
        
        let archive = try! UZKArchive(url: testArchiveURL)
        
        do {
            try archive.write(testFileData, filePath: testFilename, fileDate: nil,
                              compressionMethod: .default, password: nil, progress: { (percentCompressed) -> Void in
                                #if DEBUG
                                    NSLog("Compressing data: %f%% complete", percentCompressed)
                                #endif
            })
        } catch let error as NSError {
            XCTFail("Error writing to file \(testFileURL): \(error)")
        }
        
        let fileList = try! archive.listFileInfo()
        let writtenFileInfo = fileList.first!
        
        let expectedDate = Date().timeIntervalSinceReferenceDate
        let actualDate = writtenFileInfo.timestamp.timeIntervalSinceReferenceDate
        
        XCTAssertEqualWithAccuracy(actualDate, expectedDate, accuracy: 30, "Incorrect default date value written to file")
    }
    
    #if os(OSX)
    func testWriteData_PasswordProtected() {
        let testFilePaths = [String](nonZipTestFilePaths as! Set<String>).sorted(by: <)
        var testFileData = [Data]()
        
        let testArchiveURL = tempDirectory.appendingPathComponent("SwiftWriteDataTest.zip")
        let password = "111111"
        
        let writeArchive = try! UZKArchive(path: testArchiveURL.path, password: password)
        
        for testFilePath in testFilePaths {
            let fileData = try? Data(contentsOf: testFileURLs[testFilePath] as! URL)
            testFileData.append(fileData!)
            
            do {
                try writeArchive.write(fileData!, filePath: testFilePath)
            } catch let error as NSError {
                XCTFail("Error writing to file \(testFilePath): \(error)")
            }
        }
        
        // Read with UnzipKit
        
        let readArchive = try! UZKArchive(path: testArchiveURL.path, password: password)
        XCTAssertTrue(readArchive.isPasswordProtected(), "Archive is not marked as password-protected")
        
        var index = 0
        
        try! readArchive.performOnData(inArchive: { (fileInfo, fileData, stop) -> Void in
            let expectedData = testFileData[index]
            let expectedCRC = crc32(0, (expectedData as NSData).bytes.bindMemory(to: Bytef.self, capacity: expectedData.count), uInt(expectedData.count))
            
            XCTAssertEqual(fileInfo.filename, testFilePaths[index], "Incorrect filename in archive")
            XCTAssertEqual(fileInfo.crc, expectedCRC, "CRC of extracted data doesn't match what was written")
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
        let tempDirURL = URL(fileURLWithPath: self.randomDirectoryName())
        let textFileName = "testWriteData_ExternalVolume.txt"
        let textFileURL = tempDirURL.appendingPathComponent(textFileName)
        try! FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true, attributes: [:])
        try! "This is the original text".write(to: textFileURL, atomically: false, encoding: String.Encoding.utf8)
        let tempZipFileURL = self.archive(withFiles: [textFileURL])
        NSLog("Original ZIP file: \(String(describing: tempZipFileURL?.path))")
        
        // Write that zip file to contents of a DMG and mount it
        let dmgSourceFolderURL = tempDirURL.appendingPathComponent("DMGSource")
        try! FileManager.default.createDirectory(at: dmgSourceFolderURL, withIntermediateDirectories: true, attributes: [:])
        try! FileManager.default.copyItem(at: tempZipFileURL!, to: dmgSourceFolderURL.appendingPathComponent(tempZipFileURL!.lastPathComponent))
        let dmgURL = tempDirURL.appendingPathComponent("testWriteData_ExternalVolume.dmg")
        let mountPoint = createAndMountDMG(path: dmgURL, source: dmgSourceFolderURL)!
        NSLog("Disk image: \(dmgURL.path)")
        defer {
            unmountDMG(mountPoint)
        }

        // Update a file from the archive with overwrite=YES
        let externalVolumeZipURL = URL(fileURLWithPath: mountPoint).appendingPathComponent(tempZipFileURL!.lastPathComponent)
        let archive = try! UZKArchive(url: externalVolumeZipURL)
        let newText = "This is the new text"
        let newTextData = newText.data(using: String.Encoding.utf8)
        var writeSuccessful = true
        do {
            try archive.write(newTextData!, filePath: textFileName, fileDate: nil,
                                  compressionMethod: UZKCompressionMethod.default, password: nil,
                                  overwrite: true, progress: nil)
        } catch let error {
            NSLog("Error writing data to archive on external volume: \(error)")
            writeSuccessful = false
        }
        
        XCTAssertTrue(writeSuccessful, "Failed to update archive on external volume")
        
        let archivedFileData = try! archive.extractData(fromFile: textFileName, progress: nil)
        XCTAssertNotNil(archivedFileData, "No data extracted from file in archive on external volume")
        
        let archivedText = NSString(data: archivedFileData, encoding: String.Encoding.utf8.rawValue)!
        XCTAssertEqual(archivedText as String, newText, "Incorrect text extracted from archive on external volume")
    }
    
    func createAndMountDMG(path dmgURL: URL, source: URL) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/hdiutil"
        task.arguments = ["create",
                          "-fs", "HFS+",
                          "-format", "UDRW",
                          "-volname", dmgURL.deletingPathExtension().lastPathComponent,
                          "-srcfolder", source.path,
                          "-attach", "-plist",
                          dmgURL.path]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe

        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            NSLog("Failed to create and mount DMG: \(dmgURL.path)");
            return nil
        }
        
        let readHandle = outputPipe.fileHandleForReading
        let outputData = readHandle.readDataToEndOfFile()
        let outputPlist = try! PropertyListSerialization.propertyList(from: outputData,
                                                                      options: [],
                                                                      format: nil)
            as! [String: Any]
        
        let entities = outputPlist["system-entities"] as! [[String:AnyObject]]
        let hfsEntry = entities.filter{ $0["content-hint"] as! String == "Apple_HFS" }.first!
        let mountPoint = hfsEntry["mount-point"] as! String
        
        return mountPoint
    }
    //TODO: Make the volume read/write
    
    func unmountDMG(_ mountPoint: String) {
        let task = Process()
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
