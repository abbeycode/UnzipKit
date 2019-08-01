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
    
    func testIsDirectory_ContainsDirectories_DOS() {
        let testArchiveName = "Test Archive (DOS Directories).zip"
        let testFileURL = self.testFileURLs[testArchiveName] as! URL
        let archive = try! UZKArchive(url: testFileURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [
            "FOLDERA": true,
            "FOLDERA/TESTFILE.TXT": false,
            "TESTFILE.TXT": false,
            "XFOLDER": true,
            "XFOLDER/TESTFILE.TXT": false
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
    func testIsSymbolicLink_ContainsSymLinkFile() {
        let textFileURL = self.emptyTextFile(ofLength: 20)!
        let symLinkURL = textFileURL.deletingLastPathComponent()
            .appendingPathComponent(textFileURL
                .lastPathComponent
                .replacingOccurrences(of: ".txt", with: "-Link.txt"))
        
        try! FileManager.default.createSymbolicLink(at: symLinkURL, withDestinationURL: textFileURL)
        
        let archiveURL = self.archive(withFiles: [textFileURL, symLinkURL],
                                      zipOptions: ["--junk-paths", "--symlinks"])!
        let archive = try! UZKArchive(url: archiveURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected = [
            textFileURL.lastPathComponent: false,
            symLinkURL.lastPathComponent: true,
        ]
        let actual = fileInfo.reduce(into: Dictionary<String, Bool>()) {
            $0[$1.filename] = $1.isSymbolicLink
        }

        XCTAssertEqual(actual, expected)
    }
    
    func testIsDirectory_ContainsSymLinkFileAndDir() {
        struct FileInfo: Equatable, CustomStringConvertible {
            var description: String {
                return "FileInfo(isLink: \(isLink), isDir: \(isDir))"
            }
            
            let isLink: Bool
            let isDir: Bool
            
            static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
                return lhs.isLink == rhs.isLink && lhs.isLink == rhs.isLink
            }
        }
        
        let testArchiveName = "Test Archive (SymLink Directory).zip"
        let testFileURL = self.testFileURLs[testArchiveName] as! URL
        let archive = try! UZKArchive(url: testFileURL)
        
        let fileInfo = try! archive.listFileInfo()
        
        let expected: Dictionary<String, FileInfo> = [
            "testDir": FileInfo(isLink: false, isDir: true),
            "testDir/testFile2.md": FileInfo(isLink: false, isDir: false),
            "testDirLink": FileInfo(isLink: true, isDir: false),
            "testFile.md": FileInfo(isLink: false, isDir: false),
            "testFileLink.md": FileInfo(isLink: true, isDir: false)
        ]
        let actual = fileInfo.reduce(into: Dictionary<String, FileInfo>()) {
            $0[$1.filename!] = FileInfo(isLink: $1.isSymbolicLink, isDir: $1.isDirectory)
        }

        XCTAssertEqual(actual, expected)
    }
    #endif

}
