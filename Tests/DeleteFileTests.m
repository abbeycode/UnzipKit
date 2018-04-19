//
//  DeleteFileTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface DeleteFileTests : UZKArchiveTestCase
@end

@implementation DeleteFileTests


- (void)testDeleteFile_FirstFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[0];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:password error:nil];
        
        NSError *deleteError = nil;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSURL *expectedURL = self.testFileURLs[expectedFilename];
             NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedURL];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}

- (void)testDeleteFile_SecondFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[1];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:password error:nil];
        
        NSError *deleteError = nil;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSURL *expectedURL = self.testFileURLs[expectedFilename];
             NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedURL];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}

- (void)testDeleteFile_ThirdFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[2];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:password error:nil];
        
        NSError *deleteError = nil;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}


@end
