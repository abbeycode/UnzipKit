//
//  ModesTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"


@interface ModesTests : UZKArchiveTestCase
@end

@implementation ModesTests


- (void)testModes_WriteWhileReading
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    NSError *readError = nil;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSError *writeError = nil;
        [archive writeData:fileData filePath:@"newPath.txt" error:&writeError];
        XCTAssertNotNil(writeError, @"Write operation during a read succeeded");
        XCTAssertEqual(writeError.code, UZKErrorCodeMixedModeAccess, @"Wrong error code returned");
    } error:&readError];
    
    XCTAssertNil(readError, @"readError was also non-nil");
}

- (void)testModes_NestedReads
{
    NSArray *expectedFiles = [self.nonZipTestFilePaths.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSError *performOnFilesError = nil;
    __block NSInteger i = 0;
    
    [archive performOnFilesInArchive:^(UZKFileInfo *fileInfo, BOOL *stop) {
        NSString *expectedFilename = expectedFiles[i++];
        
        NSError *extractError = nil;
        NSData *extractedData = [archive extractDataFromFile:expectedFilename
                                                       error:&extractError];
        
        XCTAssertNil(extractError, @"Error in extractData:error:");
        
        NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
        
        XCTAssertNotNil(extractedData, @"No data extracted");
        XCTAssertTrue([expectedFileData isEqualToData:extractedData], @"Extracted data doesn't match original file");
        
        extractError = nil;
        NSData *dataFromFileInfo = [archive extractData:fileInfo
                                                  error:&extractError];
        XCTAssertNil(extractError, @"Error extracting data by file info");
        XCTAssertTrue([expectedFileData isEqualToData:dataFromFileInfo], @"Extracted data from file info doesn't match original file");
    } error:&performOnFilesError];
    
    XCTAssertNil(performOnFilesError, @"Error iterating through archive");
}

- (void)testModes_ReadWhileWriting
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    NSError *writeError = nil;
    
    [archive writeIntoBuffer:@"newFile.zip"
                       error:&writeError
                       block:
     ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
         NSError *readError = nil;
         [archive listFilenames:&readError];
         XCTAssertNotNil(readError, @"Read operation during a read succeeded");
         XCTAssertEqual(readError.code, UZKErrorCodeMixedModeAccess, @"Wrong error code returned");
         
         return YES;
     }];
    
    XCTAssertNil(writeError, @"writeError was also non-nil");
}

- (void)testModes_NestedWrites
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    NSError *outerWriteError = nil;
    
    [archive writeIntoBuffer:@"newFile.zip"
                       error:&outerWriteError
                       block:
     ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
         NSError *innerWriteError = nil;
         [archive writeIntoBuffer:@"newFile.zip"
                            error:&innerWriteError
                            block:^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {return YES;}];
                  XCTAssertNotNil(innerWriteError, @"Nested write operation succeeded");
         XCTAssertEqual(innerWriteError.code, UZKErrorCodeFileWrite, @"Wrong error code returned");
         
         return YES;
     }];
    
    XCTAssertNil(outerWriteError, @"outerWriteError was also non-nil");
}


@end
