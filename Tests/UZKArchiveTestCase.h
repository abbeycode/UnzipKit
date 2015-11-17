//
//  UZKArchiveTestCase.h
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "zip.h"


@interface UZKArchiveTestCase : XCTestCase

@property BOOL testFailed;

@property NSURL *tempDirectory;
@property NSMutableDictionary *testFileURLs;
@property NSMutableDictionary *unicodeFileURLs;
@property NSSet *nonZipTestFilePaths;
@property NSSet *nonZipUnicodeFilePaths;
@property NSURL *corruptArchive;


// Helper Methods

+ (NSDateFormatter *)dateFormatter;

- (NSURL *)urlOfTestFile:(NSString *)filename;

- (NSString *)randomDirectoryName;
- (NSString *)randomDirectoryWithPrefix:(NSString *)prefix;

- (NSInteger)numberOfOpenFileHandles;

- (NSURL *)emptyTextFileOfLength:(NSUInteger)fileSize;
- (NSURL *)archiveWithFiles:(NSArray *)fileURLs;
- (BOOL)extractArchive:(NSURL *)url password:(NSString *)password;
- (NSURL *)largeArchive;

- (NSUInteger)crcOfTestFile:(NSString *)filename;

@end

