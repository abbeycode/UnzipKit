//
//  UZKArchiveTestCase.h
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <XCTest/XCTest.h>


@interface UZKArchiveTestCase : XCTestCase

@property BOOL testFailed;

@property (retain) NSURL *tempDirectory;
@property (retain) NSMutableDictionary<NSString*, NSURL*> *testFileURLs;
@property (retain) NSMutableDictionary *unicodeFileURLs;
@property (retain) NSSet *nonZipTestFilePaths;
@property (retain) NSSet *nonZipUnicodeFilePaths;
@property (retain) NSURL *corruptArchive;


// Helper Methods

+ (NSDateFormatter *)dateFormatter;

- (NSURL *)urlOfTestFile:(NSString *)filename;

- (NSString *)randomDirectoryName;
- (NSString *)randomDirectoryWithPrefix:(NSString *)prefix;

- (NSURL *)emptyTextFileOfLength:(NSUInteger)fileSize;

#if !TARGET_OS_IPHONE
- (NSInteger)numberOfOpenFileHandles;
- (NSURL *)archiveWithFiles:(NSArray<NSURL*> *)fileURLs;
- (NSURL *)archiveWithFiles:(NSArray<NSURL*> *)fileURLs password:(NSString *)password;
- (BOOL)extractArchive:(NSURL *)url password:(NSString *)password;
- (NSURL *)largeArchive;
#endif

- (NSUInteger)crcOfFile:(NSURL *)url;
- (NSUInteger)crcOfTestFile:(NSString *)filename;

@end

