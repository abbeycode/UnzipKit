//
//  WriteBufferedDataTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "zip.h"
#import "UnzipKit.h"

@interface WriteBufferedDataTests : UZKArchiveTestCase
@end

@implementation WriteBufferedDataTests


- (void)testWriteInfoBuffer
{
    NSArray *testFiles = [self.nonZipTestFilePaths.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[[UZKArchiveTestCase dateFormatter] dateFromString:@"12/20/2014 9:35 AM"],
                           [[UZKArchiveTestCase dateFormatter] dateFromString:@"12/21/2014 10:00 AM"],
                           [[UZKArchiveTestCase dateFormatter] dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteIntoBufferTest.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    unsigned int bufferSize = 1024; //Arbitrary
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        NSError *writeError = nil;
        const void *bytes = fileData.bytes;
        
        BOOL result = [archive writeIntoBuffer:testFile
                                      fileDate:testDates[idx]
                             compressionMethod:UZKCompressionMethodDefault
                                     overwrite:YES
                                         error:&writeError
                                         block:
                       ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                           for (NSUInteger i = 0; i <= fileData.length; i += bufferSize) {
                               unsigned int size = (unsigned int)MIN(fileData.length - i, bufferSize);
                               BOOL writeSuccess = writeData(&bytes[i], size);
                               XCTAssertTrue(writeSuccess, @"Failed to write buffered data");
                           }
                           
                           return YES;
                       }];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        unsigned long expectedCRC = crc32(0, expectedData.bytes, (unsigned int)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
}

- (void)testWriteInfoBuffer_Failure
{
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteIntoBufferTest_Failure.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSInteger errorCode = 718;
    
    NSError *writeError = nil;
    
    BOOL result = [archive writeIntoBuffer:@"Test File A.txt"
                                  fileDate:[[UZKArchiveTestCase dateFormatter] dateFromString:@"12/20/2014 9:35 AM"]
                         compressionMethod:UZKCompressionMethodDefault
                                 overwrite:YES
                                     error:&writeError
                                     block:
                   ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                       NSError *bufferError = [NSError errorWithDomain:@"UnzipKitUnitTest"
                                                                  code:errorCode
                                                              userInfo:@{}];
                       *actionError = bufferError;
                       
                       return NO;
                   }];
    
    XCTAssertFalse(result, @"Success returned during failure writing archive data");
    XCTAssertNotNil(writeError, @"No error after failure writing to archive");
    XCTAssertEqual(writeError.code, errorCode, @"Wrong error code returned");
}

#if !TARGET_OS_IPHONE
- (void)testWriteInfoBuffer_PasswordGiven
{
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"testWriteInfoBuffer_PasswordGiven.zip"];
    
    NSString *password = @"a password";
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:password error:nil];
    
    NSError *writeError = nil;
    
    unsigned int bufferSize = 1024; //Arbitrary
    
    NSString *testFile = @"Test File A.txt";
    NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
    
    const void *bytes = fileData.bytes;
    
    BOOL result = [archive writeIntoBuffer:testFile
                                  fileDate:nil
                         compressionMethod:UZKCompressionMethodDefault
                                 overwrite:YES
                                       CRC:841856539
                                     error:&writeError
                                     block:
                   ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                       for (NSUInteger i = 0; i <= fileData.length; i += bufferSize) {
                           unsigned int size = (unsigned int)MIN(fileData.length - i, bufferSize);
                           BOOL writeSuccess = writeData(&bytes[i], size);
                           XCTAssertTrue(writeSuccess, @"Failed to write buffered data");
                       }
                       
                       return YES;
                   }];
    
    XCTAssertTrue(result, @"Error writing archive data");
    XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    
    BOOL extractSuccess = [self extractArchive:testArchiveURL
                                      password:password];
    
    XCTAssertTrue(extractSuccess, @"Failed to extract archive (encryption is incorrect)");
}
#endif

- (void)testWriteInfoBuffer_PasswordGiven_NoCRC
{
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"testWriteInfoBuffer_PasswordGiven_NoCRC.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:@"a password" error:nil];
    
    NSError *writeError = nil;
    
    XCTAssertThrows([archive writeIntoBuffer:@"Test File A.txt"
                                    fileDate:[[UZKArchiveTestCase dateFormatter] dateFromString:@"12/20/2014 9:35 AM"]
                           compressionMethod:UZKCompressionMethodDefault
                                   overwrite:YES
                                       error:&writeError
                                       block:
                     ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                         return YES;
                     }],
                    @"No assertion failed when streaming an encypted file with no CRC given");
}

- (void)testWriteInfoBuffer_PasswordGiven_MismatchedCRC
{
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"testWriteInfoBuffer_PasswordGiven_MismatchedCRC.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:@"a password" error:nil];
    
    NSError *writeError = nil;
    
    unsigned int bufferSize = 1024; //Arbitrary
    
    NSString *testFile = @"Test File A.txt";
    NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
    
    const void *bytes = fileData.bytes;
    
    BOOL result = [archive writeIntoBuffer:testFile
                                  fileDate:nil
                         compressionMethod:UZKCompressionMethodDefault
                                 overwrite:YES
                                       CRC:3
                                     error:&writeError
                                     block:
                   ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                       for (NSUInteger i = 0; i <= fileData.length; i += bufferSize) {
                           unsigned int size = (unsigned int)MIN(fileData.length - i, bufferSize);
                           BOOL writeSuccess = writeData(&bytes[i], size);
                           XCTAssertTrue(writeSuccess, @"Failed to write buffered data");
                       }
                       
                       return YES;
                   }];
    
    XCTAssertFalse(result, @"No error writing archive data");
    XCTAssertNotNil(writeError, @"No error writing to file");
    XCTAssertEqual(writeError.code, UZKErrorCodePreCRCMismatch, @"Wrong error code returned for CRC mismatch");
    XCTAssertTrue([writeError.localizedRecoverySuggestion containsString:@"0000000003"], @"Bad CRC not included in message");
    XCTAssertTrue([writeError.localizedRecoverySuggestion containsString:@"0841856539"], @"Good CRC not included in message");
}


@end
