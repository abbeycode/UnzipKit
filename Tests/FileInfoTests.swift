//
//  FileInfoTests.swift
//  UnzipKitTests
//
//  Created by Dov Frankel on 7/25/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

import XCTest

class FileInfoTests: UZKArchiveTestCase {
    
    func testIsDirectory_NoDirectories() {
        let testArchiveName = "Test Archive.zip"
        let testFileURL = self.testFileURLs[testArchiveName] as! URL
        let archive = try! UZKArchive(url: testFileURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [false, false, false]
        let actual = fileInfo.map { $0.isDirectory }
        
        XCTAssertEqual(actual, expected)
    }
    
    func testIsDirectory_ContainsDirectories() {
        let testArchiveName = "Test Archive (Directories).zip"
        let testFileURL = self.testFileURLs[testArchiveName] as! URL
        let archive = try! UZKArchive(url: testFileURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [
            "Folder A": true,
            "Folder A/Test File A.txt": false,
            "Test File B.txt": false,
            "X Folder": true,
            "X Folder/Test File C.txt": false
        ]
        let actual = fileInfo.reduce(into: Dictionary<String, Bool>()) {
            $0[$1.filename] = $1.isDirectory
        }
        
        XCTAssertEqual(actual, expected)
    }
    
    func testIsSymbolicLink_NoSymLinks() {
        let testArchiveName = "Test Archive.zip"
        let testFileURL = self.testFileURLs[testArchiveName] as! URL
        let archive = try! UZKArchive(url: testFileURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [false, false, false]
        let actual = fileInfo.map { $0.isSymbolicLink }
        
        XCTAssertEqual(actual, expected)
    }
    
    #if os(OSX)
    func testIsSymbolicLink_ContainsSymLinks() {
        let textFileURL = self.emptyTextFile(ofLength: 20)!
        let symLinkURL = textFileURL.deletingLastPathComponent()
            .appendingPathComponent(textFileURL
                .lastPathComponent
                .replacingOccurrences(of: ".txt", with: "-Link.txt"))
        
        try! FileManager.default.createSymbolicLink(at: symLinkURL, withDestinationURL: textFileURL)
        
        let archiveURL = self.archive(withFiles: [textFileURL, symLinkURL], zipOptions: ["--symlinks"])!
        let archive = try! UZKArchive(url: archiveURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [
            textFileURL.lastPathComponent: false,
            symLinkURL.lastPathComponent: true,
        ]
        let actual = fileInfo.reduce(into: Dictionary<String, Bool>()) {
            $0[$1.filename] = $1.isDirectory
        }

        XCTAssertEqual(actual, expected)
    }
    #endif

}
