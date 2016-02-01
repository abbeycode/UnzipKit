//
//  ExtractBufferedDataTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import <DTPerformanceSession/DTSignalFlag.h>

#import "UZKArchiveTestCase.h"
@import UnzipKit;

@interface ExtractBufferedDataTests : UZKArchiveTestCase
@end

@implementation ExtractBufferedDataTests


- (void)testExtractBufferedData
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    NSString *extractedFile = @"Test File B.jpg";
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    NSError *error = nil;
    NSMutableData *reconstructedFile = [NSMutableData data];
    BOOL success = [archive extractBufferedDataFromFile:extractedFile
                                                  error:&error
                                                 action:
                    ^(NSData *dataChunk, CGFloat percentDecompressed) {
#if DEBUG
                        NSLog(@"Decompressed: %f%%", percentDecompressed);
#endif
                        [reconstructedFile appendBytes:dataChunk.bytes
                                                length:dataChunk.length];
                    }];
    
    XCTAssertTrue(success, @"Failed to read buffered data");
    XCTAssertNil(error, @"Error reading buffered data");
    XCTAssertGreaterThan(reconstructedFile.length, (NSUInteger)0, @"No data returned");
    
    NSData *originalFile = [NSData dataWithContentsOfURL:self.testFileURLs[extractedFile]];
    XCTAssertTrue([originalFile isEqualToData:reconstructedFile],
                  @"File extracted in buffer not returned correctly");
}

#if !TARGET_OS_IPHONE
- (void)testExtractBufferedData_VeryLarge
{
    DTSendSignalFlag("Begin creating text file", DT_START_SIGNAL, TRUE);
    NSURL *largeTextFile = [self emptyTextFileOfLength:100000000]; // Increase for a more dramatic test
    XCTAssertNotNil(largeTextFile, @"No large text file URL returned");
    DTSendSignalFlag("End creating text file", DT_END_SIGNAL, TRUE);
    
    DTSendSignalFlag("Begin archiving data", DT_START_SIGNAL, TRUE);
    NSURL *archiveURL = [self archiveWithFiles:@[largeTextFile]];
    XCTAssertNotNil(archiveURL, @"No archived large text file URL returned");
    DTSendSignalFlag("Begin archiving data", DT_END_SIGNAL, TRUE);
    
    NSURL *deflatedFileURL = [self.tempDirectory URLByAppendingPathComponent:@"DeflatedTextFile.txt"];
    BOOL createSuccess = [[NSFileManager defaultManager] createFileAtPath:deflatedFileURL.path
                                                                 contents:nil
                                                               attributes:nil];
    XCTAssertTrue(createSuccess, @"Failed to create empty deflate file");
    
    NSError *handleError = nil;
    NSFileHandle *deflated = [NSFileHandle fileHandleForWritingToURL:deflatedFileURL
                                                               error:&handleError];
    XCTAssertNil(handleError, @"Error creating a file handle");
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    DTSendSignalFlag("Begin extracting buffered data", DT_START_SIGNAL, TRUE);
    
    NSError *error = nil;
    BOOL success = [archive extractBufferedDataFromFile:largeTextFile.lastPathComponent
                                                  error:&error
                                                 action:
                    ^(NSData *dataChunk, CGFloat percentDecompressed) {
# if DEBUG
                        NSLog(@"Decompressed: %f%%", percentDecompressed);
# endif
                        [deflated writeData:dataChunk];
                    }];
    
    DTSendSignalFlag("End extracting buffered data", DT_END_SIGNAL, TRUE);
    
    XCTAssertTrue(success, @"Failed to read buffered data");
    XCTAssertNil(error, @"Error reading buffered data");
    
    [deflated closeFile];
    
    NSData *deflatedData = [NSData dataWithContentsOfURL:deflatedFileURL];
    NSData *fileData = [NSData dataWithContentsOfURL:largeTextFile];
    
    XCTAssertTrue([fileData isEqualToData:deflatedData], @"Data didn't restore correctly");
}
#endif


@end
