//
//  ListFileInfoTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface ListFileInfoTests : UZKArchiveTestCase
@end

@implementation ListFileInfoTests


- (void)testListFileInfo {
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test Archive.zip"] error:nil];
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSDate *expectedDate = [[UZKArchiveTestCase dateFormatter] dateFromString:@"3/22/2014 11:17 PM"];
    NSDictionary *expectedCompressionMethods = @{@"Test File A.txt": @(UZKCompressionMethodNone),
                                                 @"Test File B.jpg": @(UZKCompressionMethodDefault),
                                                 @"Test File C.m4a": @(UZKCompressionMethodDefault),};
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFileInfo");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count, @"Incorrect number of files listed in archive");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSUInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        
        // Test Filename
        NSString *expectedFilename = expectedFiles[i];
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename");
        
        // Test CRC
        NSUInteger expectedFileCRC = [self crcOfTestFile:expectedFilename];
        XCTAssertEqual(fileInfo.CRC, expectedFileCRC, @"Incorrect CRC checksum");
        
        // Test Last Modify Date
        NSTimeInterval archiveFileTimeInterval = [fileInfo.timestamp timeIntervalSinceReferenceDate];
        NSTimeInterval expectedFileTimeInterval = [expectedDate timeIntervalSinceReferenceDate];
        XCTAssertEqualWithAccuracy(archiveFileTimeInterval, expectedFileTimeInterval, 60, @"Incorrect file timestamp (more than 60 seconds off)");
        
        // Test Uncompressed Size
        NSError *attributesError = nil;
        NSString *expectedFilePath = [[self urlOfTestFile:expectedFilename] path];
        NSDictionary *expectedFileAttributes = [fm attributesOfItemAtPath:expectedFilePath
                                                                    error:&attributesError];
        XCTAssertNil(attributesError, @"Error getting file attributes of %@", expectedFilename);
        
        unsigned long long expectedFileSize = expectedFileAttributes.fileSize;
        XCTAssertEqual(fileInfo.uncompressedSize, expectedFileSize, @"Incorrect uncompressed file size");
        
        // Test Compression method
        UZKCompressionMethod expectedCompressionMethod = ((NSNumber *)expectedCompressionMethods[fileInfo.filename]).integerValue;
        XCTAssertEqual(fileInfo.compressionMethod, expectedCompressionMethod, @"Incorrect compression method");
    }
}

- (void)testListFileInfo_Unicode
{
    NSSet *expectedFileSet = self.nonZipUnicodeFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFileInfo");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSUInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFiles[i], @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_WinZip
{
    NSURL *testArchiveURL = self.testFileURLs[@"L'incertain.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    NSArray *expectedFiles = @[@"Acribor‚a - T01 - L'incertain/Test File A.txt",
                               @"Acribor‚a - T01 - L'incertain/Test File B.jpg",
                               @"Acribor‚a - T01 - L'incertain/Test File C.m4a",
                               @"Acribor‚a - T01 - L'incertain"];
    NSArray *isDirectoryValues = @[@NO,
                                   @NO,
                                   @NO,
                                   @YES];
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFiles.count, @"Incorrect number of files listed in archive");
    
    for (NSUInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = (UZKFileInfo *)filesInArchive[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFiles[i], @"Incorrect filename listed");
        
        BOOL expectedIsDirectory = ((NSNumber *)isDirectoryValues[i]).boolValue;
        XCTAssertEqual(fileInfo.isDirectory, expectedIsDirectory, @"Incorrect isDirectory value listed");
    }
}

- (void)testListFileInfo_Password
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:@"password" error:nil];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSUInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_NoPasswordGiven {
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSUInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_InvalidArchive
{
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test File A.txt"] error:nil];
    
    NSError *error = nil;
    NSArray *files = [archive listFileInfo:&error];
    
    XCTAssertNotNil(error, @"List files of invalid archive succeeded");
    XCTAssertNil(files, @"List returned for invalid archive");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
}


@end
