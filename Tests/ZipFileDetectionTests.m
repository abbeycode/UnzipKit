//
//  ZipFileDetectionTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface ZipFileDetectionTests : UZKArchiveTestCase
@end

@implementation ZipFileDetectionTests

#pragma mark - By Path

- (void)testPathIsAZip
{
    NSURL *url = self.testFileURLs[@"Test Archive.zip"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertTrue(pathIsZip, @"Zip file is not reported as a zip");
}

- (void)testPathIsAZip_EmptyZip
{
    NSURL *url = self.testFileURLs[@"Empty Archive.zip"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertTrue(pathIsZip, @"Empty Zip file is not reported as a zip");
}

- (void)testPathIsAZip_SpannedZip
{
    NSURL *url = self.testFileURLs[@"Spanned Archive.zip.001"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertTrue(pathIsZip, @"Spanned Zip file is not reported as a zip");
}

- (void)testPathIsAZip_NotAZip
{
    NSURL *url = self.testFileURLs[@"Test File B.jpg"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertFalse(pathIsZip, @"JPG file is reported as a zip");
}

- (void)testPathIsAZip_NotAZip_FirstBytesPK
{
    NSURL *url = self.testFileURLs[@"NotAZip-PK-ContentsUnknown"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertFalse(pathIsZip, @"JPG file is reported as a zip");
}

- (void)testPathIsAZip_SmallFile
{
    NSURL *url = [self emptyTextFileOfLength:1];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertFalse(pathIsZip, @"Small non-Zip file is reported as a zip");
}

- (void)testPathIsAZip_MissingFile
{
    NSURL *url = [self.testFileURLs[@"Test Archive.zip"] URLByAppendingPathExtension:@"missing"];
    NSString *path = url.path;
    BOOL pathIsZip = [UZKArchive pathIsAZip:path];
    XCTAssertFalse(pathIsZip, @"Missing file is reported as a zip");
}

#if !TARGET_OS_IPHONE
- (void)testPathIsAZip_FileHandleLeaks
{
    NSURL *smallFileURL = [self emptyTextFileOfLength:1];
    NSURL *jpgURL = self.testFileURLs[@"Test File B.jpg"];
    
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    for (NSInteger i = 0; i < 5000; i++) {
        BOOL smallFileIsZip = [UZKArchive pathIsAZip:(NSString *__nonnull)smallFileURL.path];
        XCTAssertFalse(smallFileIsZip, @"Small non-Zip file is reported as a zip");
        
        BOOL jpgIsZip = [UZKArchive pathIsAZip:(NSString *__nonnull)jpgURL.path];
        XCTAssertFalse(jpgIsZip, @"JPG file is reported as a zip");
        
        NSURL *zipURL = self.testFileURLs[@"Test Archive.zip"];
        BOOL zipFileIsZip = [UZKArchive pathIsAZip:(NSString *__nonnull)zipURL.path];
        XCTAssertTrue(zipFileIsZip, @"Zip file is not reported as a zip");
    }
    
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}
#endif

#pragma mark - By URL

- (void)testURLIsAZip
{
    NSURL *url = self.testFileURLs[@"Test Archive.zip"];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertTrue(urlIsZip, @"Zip file is not reported as a zip");
}

- (void)testURLIsAZip_EmptyZip
{
    NSURL *url = self.testFileURLs[@"Empty Archive.zip"];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertTrue(urlIsZip, @"Empty Zip file is not reported as a zip");
}

- (void)testSpannedIsAZip_SpannedZip
{
    NSURL *url = self.testFileURLs[@"Spanned Archive.zip.001"];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertTrue(urlIsZip, @"Spanned Zip file is not reported as a zip");
}

- (void)testURLIsAZip_NotAZip
{
    NSURL *url = self.testFileURLs[@"Test File B.jpg"];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertFalse(urlIsZip, @"JPG file is reported as a zip");
}

- (void)testURLIsAZip_SmallFile
{
    NSURL *url = [self emptyTextFileOfLength:1];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertFalse(urlIsZip, @"Small non-Zip file is reported as a zip");
}

- (void)testURLIsAZip_MissingFile
{
    NSURL *url = [self.testFileURLs[@"Test Archive.zip"] URLByAppendingPathExtension:@"missing"];
    BOOL urlIsZip = [UZKArchive urlIsAZip:url];
    XCTAssertFalse(urlIsZip, @"Missing file is reported as a zip");
}

#if !TARGET_OS_IPHONE
- (void)testURLIsAZip_FileHandleLeaks
{
    NSURL *smallFileURL = [self emptyTextFileOfLength:1];
    NSURL *jpgURL = self.testFileURLs[@"Test File B.jpg"];
    
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    for (NSInteger i = 0; i < 5000; i++) {
        BOOL smallFileIsZip = [UZKArchive urlIsAZip:smallFileURL];
        XCTAssertFalse(smallFileIsZip, @"Small non-Zip file is reported as a zip");
        
        BOOL jpgIsZip = [UZKArchive urlIsAZip:jpgURL];
        XCTAssertFalse(jpgIsZip, @"JPG file is reported as a zip");
        
        NSURL *zipURL = self.testFileURLs[@"Test Archive.zip"];
        BOOL zipFileIsZip = [UZKArchive urlIsAZip:zipURL];
        XCTAssertTrue(zipFileIsZip, @"Zip file is not reported as a zip");
    }
    
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}
#endif

@end
