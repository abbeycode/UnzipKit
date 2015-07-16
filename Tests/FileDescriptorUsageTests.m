//
//  FileDescriptorUsageTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
@import UnzipKit;

@interface FileDescriptorUsageTests : UZKArchiveTestCase
@end

@implementation FileDescriptorUsageTests


- (void)testFileDescriptorUsage
{
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveOriginalURL = self.testFileURLs[testArchiveName];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < 1000; i++) {
        NSString *tempDir = [self randomDirectoryName];
        NSURL *tempDirURL = [self.tempDirectory URLByAppendingPathComponent:tempDir];
        NSURL *testArchiveCopyURL = [tempDirURL URLByAppendingPathComponent:testArchiveName];
        
        NSError *error = nil;
        [fm createDirectoryAtURL:tempDirURL
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&error];
        
        XCTAssertNil(error, @"Error creating temp directory: %@", tempDirURL);
        
        [fm copyItemAtURL:testArchiveOriginalURL toURL:testArchiveCopyURL error:&error];
        XCTAssertNil(error, @"Error copying test archive \n from: %@ \n\n   to: %@", testArchiveOriginalURL, testArchiveCopyURL);
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveCopyURL];
        
        NSArray *fileList = [archive listFilenames:&error];
        XCTAssertNotNil(fileList);
        
        for (NSString *fileName in fileList) {
            NSData *fileData = [archive extractDataFromFile:fileName
                                                   progress:nil
                                                      error:&error];
            XCTAssertNotNil(fileData);
            XCTAssertNil(error);
        }
    }
    
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}

- (void)testFileDescriptorUsage_ExtractInsidePerformOnFiles
{
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveOriginalURL = self.testFileURLs[testArchiveName];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < 1000; i++) {
        NSString *tempDir = [self randomDirectoryName];
        NSURL *tempDirURL = [self.tempDirectory URLByAppendingPathComponent:tempDir];
        NSURL *testArchiveCopyURL = [tempDirURL URLByAppendingPathComponent:testArchiveName];
        
        NSError *error = nil;
        [fm createDirectoryAtURL:tempDirURL
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&error];
        
        XCTAssertNil(error, @"Error creating temp directory: %@", tempDirURL);
        
        [fm copyItemAtURL:testArchiveOriginalURL toURL:testArchiveCopyURL error:&error];
        XCTAssertNil(error, @"Error copying test archive \n from: %@ \n\n   to: %@", testArchiveOriginalURL, testArchiveCopyURL);
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveCopyURL];
        
        NSError *performOnFilesError = nil;
        BOOL performOnFilesResult =  [archive performOnFilesInArchive:^(UZKFileInfo *fileInfo, BOOL *stop) {
            NSError *extractError = nil;
            NSData *fileData = [archive extractData:fileInfo progress:nil error:&extractError];
            XCTAssertNotNil(fileData, @"No data extracted");
            XCTAssertNil(extractError, @"Failed to extract file");
        } error:&performOnFilesError];
        XCTAssertTrue(performOnFilesResult, @"Failed to performOnFilesInArchive");
        XCTAssertNil(performOnFilesError, @"Error during performOnFilesInArchive");
    }
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}

- (void)testFileDescriptorUsage_WriteIntoArchive
{
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    NSURL *testArchiveOriginalURL = [self largeArchive];
    NSString *testArchiveName = testArchiveOriginalURL.lastPathComponent;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < 100; i++) {
        NSString *tempDir = [self randomDirectoryName];
        NSURL *tempDirURL = [self.tempDirectory URLByAppendingPathComponent:tempDir];
        NSURL *testArchiveCopyURL = [tempDirURL URLByAppendingPathComponent:testArchiveName];
        
        NSError *error = nil;
        [fm createDirectoryAtURL:tempDirURL
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&error];
        
        XCTAssertNil(error, @"Error creating temp directory: %@", tempDirURL);
        
        [fm copyItemAtURL:testArchiveOriginalURL toURL:testArchiveCopyURL error:&error];
        XCTAssertNil(error, @"Error copying test archive \n from: %@ \n\n   to: %@", testArchiveOriginalURL, testArchiveCopyURL);
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveCopyURL];
        
        NSArray *fileList = [archive listFilenames:&error];
        XCTAssertNotNil(fileList);
        
        for (NSString *fileName in fileList) {
            NSData *fileData = [archive extractDataFromFile:fileName
                                                   progress:nil
                                                      error:&error];
            XCTAssertNotNil(fileData);
            XCTAssertNil(error);
        }
        
        for (int x = 0; x < 50; x++) {
            NSError *writeError = nil;
            NSString *fileContents = [NSString stringWithFormat:@"This is a string %d", x];
            NSData *newFileData = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
            NSString *fileName = fileList.lastObject;
            BOOL writeResult = [archive writeData:newFileData
                                         filePath:fileName
                                         fileDate:[NSDate date]
                                compressionMethod:UZKCompressionMethodDefault
                                         password:nil
                                        overwrite:YES
                                         progress:nil
                                            error:&writeError];
            XCTAssertTrue(writeResult, @"Failed to write to archive (attempt %d)", x);
            XCTAssertNil(writeError, @"Error writing to archive (attempt %d)", x);
            
            NSError *extractError = nil;
            NSData *extractedData = [archive extractDataFromFile:fileName
                                                        progress:nil
                                                           error:&extractError];
            XCTAssertEqualObjects(extractedData, newFileData, @"Incorrect data written to file (attempt %d)", x);
            XCTAssertNil(extractError, @"Error extracting from archive (attempt %d)", x);
        }
    }
    
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}


@end
