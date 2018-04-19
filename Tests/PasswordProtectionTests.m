//
//  PasswordProtectionTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface PasswordProtectionTests : UZKArchiveTestCase
@end

@implementation PasswordProtectionTests



#pragma mark - Is Password-Protected


- (void)testIsPasswordProtected_PasswordRequired_AllFiles
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    XCTAssertTrue(archive.isPasswordProtected, @"isPasswordProtected = NO for password-protected archive");
}

- (void)testIsPasswordProtected_PasswordRequired_LastFileOnly
{
    NSArray *testFiles = [self.nonZipTestFilePaths.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"testIsPasswordProtected_PasswordRequired_LastFileOnly.zip"];
    
    UZKArchive *writeArchive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        NSString *password = nil;
        
        if (idx == testFiles.count - 1) {
            password = @"111111";
        }
        
        BOOL result = [writeArchive writeData:fileData
                                     filePath:testFile
                                     fileDate:nil
                            compressionMethod:UZKCompressionMethodDefault
                                     password:password
                                        error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    UZKArchive *readArchive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    XCTAssertTrue(readArchive.isPasswordProtected, @"isPasswordProtected = NO for password-protected archive");
}

- (void)testIsPasswordProtected_PasswordNotRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    XCTAssertFalse(archive.isPasswordProtected, @"isPasswordProtected = YES for password-protected archive");
}



#pragma mark - Validate Password


- (void)testValidatePassword_PasswordRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    XCTAssertFalse(archive.validatePassword, @"validatePassword = YES when no password supplied");
    
    archive.password = @"wrong";
    XCTAssertFalse(archive.validatePassword, @"validatePassword = YES when wrong password supplied");
    
    archive.password = @"password";
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when correct password supplied");
}

- (void)testValidatePassword_PasswordNotRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:nil];
    
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when no password supplied");
    
    archive.password = @"password";
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when password supplied");
}

#if !TARGET_OS_IPHONE
- (void)testValidatePassword_LargeFile
{
    NSString *password = @"12345-luggage";
    
    NSArray<NSURL*> *urls = @[[self emptyTextFileOfLength:400000]];
    NSURL *archiveURL = [self archiveWithFiles:urls password:password];

    NSError *error = nil;
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:archiveURL error:&error];
    
    XCTAssertNotNil(archive, @"Archive not initialized");
    XCTAssertNil(error, @"Error initializing archive: %@", error);
    
    BOOL passwordValidated = [archive validatePassword];
    XCTAssertFalse(passwordValidated, @"Expected password to be reported as incorrect");
}
#endif

@end
