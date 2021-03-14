//
//  ExtractBufferedDataTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

@import UnzipKit;

@import os.log;
@import os.signpost;

#import "UZKArchiveTestCase.h"
#import "UnzipKitMacros.h"


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
                        UZKLogDebug("Decompressed: %f%%", percentDecompressed);
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

#if !TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101200
- (void)testExtractBufferedData_VeryLarge
{
    os_log_t log = os_log_create("UnzipKit-testExtractBufferedData_VeryLarge", OS_LOG_CATEGORY_POINTS_OF_INTEREST);
    
    os_signpost_id_t createTextFileID = os_signpost_id_generate(log);
    os_signpost_interval_begin(log, createTextFileID, "Create Text File", "Start");
    NSURL *largeTextFile = [self emptyTextFileOfLength:100000000]; // Increase for a more dramatic test
    XCTAssertNotNil(largeTextFile, @"No large text file URL returned");
    os_signpost_interval_end(log, createTextFileID, "Create Text File", "End");

    os_signpost_id_t archiveDataID = os_signpost_id_generate(log);
    os_signpost_interval_begin(log, archiveDataID, "Archive Data", "Start");
    NSURL *archiveURL = [self archiveWithFiles:@[largeTextFile]];
    XCTAssertNotNil(archiveURL, @"No archived large text file URL returned");
    os_signpost_interval_end(log, archiveDataID, "Archive Data", "End");

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
    
    os_signpost_id_t extractDataID = os_signpost_id_generate(log);
    os_signpost_interval_begin(log, extractDataID, "Extract Data", "Start");

    NSError *error = nil;
    BOOL success = [archive extractBufferedDataFromFile:largeTextFile.lastPathComponent
                                                  error:&error
                                                 action:
                    ^(NSData *dataChunk, CGFloat percentDecompressed) {
# if DEBUG
                        UZKLogDebug("Decompressed: %f%%", percentDecompressed);
# endif
                        [deflated writeData:dataChunk];
                        os_signpost_event_emit(log, extractDataID, "Extracted chunk", "%f", percentDecompressed);
                    }];
    
    os_signpost_interval_end(log, extractDataID, "Extract Data", "End");

    XCTAssertTrue(success, @"Failed to read buffered data");
    XCTAssertNil(error, @"Error reading buffered data");
    
    [deflated closeFile];
    
    NSData *deflatedData = [NSData dataWithContentsOfURL:deflatedFileURL];
    NSData *fileData = [NSData dataWithContentsOfURL:largeTextFile];
    
    XCTAssertTrue([fileData isEqualToData:deflatedData], @"Data didn't restore correctly");
}
#endif


@end
