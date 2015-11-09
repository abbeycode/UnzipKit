//
//  UZKArchiveTestCase.m
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"

#import "unzip.h"

static NSDateFormatter *testFileInfoDateFormatter;



@implementation UZKArchiveTestCase



#pragma mark - Setup/Teardown


- (void)setUp {
    [super setUp];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testFileInfoDateFormatter = [[NSDateFormatter alloc] init];
        testFileInfoDateFormatter.dateFormat = @"M/dd/yyyy h:mm a";
        testFileInfoDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    });
    
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *uniqueName = [self randomDirectoryName];
    NSError *error = nil;
    
    NSArray *testFiles = @[@"Test Archive.zip",
                           @"Test Archive (Password).zip",
                           @"L'incertain.zip",
                           @"Aces.zip",
                           @"Comments Archive.zip",
                           @"Empty Archive.zip",
                           @"Spanned Archive.zip.001",
                           @"Test File A.txt",
                           @"Test File B.jpg",
                           @"Test File C.m4a"];
    
    NSArray *unicodeFiles = @[@"Ⓣest Ⓐrchive.zip",
                              @"Test File Ⓐ.txt",
                              @"Test File Ⓑ.jpg",
                              @"Test File Ⓒ.m4a"];
    
    NSString *tempDirSubtree = [@"UnzipKitTest" stringByAppendingPathComponent:uniqueName];
    
    self.testFailed = NO;
    self.testFileURLs = [[NSMutableDictionary alloc] init];
    self.unicodeFileURLs = [[NSMutableDictionary alloc] init];
    self.tempDirectory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempDirSubtree]
                                    isDirectory:YES];
    
    NSLog(@"Temp directory: %@", self.tempDirectory);
    
    [fm createDirectoryAtURL:self.tempDirectory
 withIntermediateDirectories:YES
                  attributes:nil
                       error:&error];
    
    XCTAssertNil(error, @"Failed to create temp directory: %@", self.tempDirectory);
    
    NSMutableArray *filesToCopy = [NSMutableArray arrayWithArray:testFiles];
    [filesToCopy addObjectsFromArray:unicodeFiles];
    
    for (NSString *file in filesToCopy) {
        NSURL *testFileURL = [self urlOfTestFile:file];
        BOOL testFileExists = [fm fileExistsAtPath:(NSString* _Nonnull)testFileURL.path];
        XCTAssertTrue(testFileExists, @"%@ not found", file);
        
        NSURL *destinationURL = [self.tempDirectory URLByAppendingPathComponent:file isDirectory:NO];
        
        NSError *error = nil;
        if (file.pathComponents.count > 1) {
            [fm createDirectoryAtPath:(NSString* _Nonnull)destinationURL.URLByDeletingLastPathComponent.path
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];
            XCTAssertNil(error, @"Failed to create directories for file %@", file);
        }
        
        [fm copyItemAtURL:testFileURL
                    toURL:destinationURL
                    error:&error];
        
        XCTAssertNil(error, @"Failed to copy temp file %@ from %@ to %@",
                     file, testFileURL, destinationURL);
        
        if ([testFiles containsObject:file]) {
            self.testFileURLs[file] = destinationURL;
        }
        else if ([unicodeFiles containsObject:file]) {
            self.unicodeFileURLs[file] = destinationURL;
        }
    }
    
    self.nonZipTestFilePaths = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return [key rangeOfString:@"zip"].location == NSNotFound;
    }];
    
    self.nonZipUnicodeFilePaths = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return [key rangeOfString:@"zip"].location == NSNotFound;
    }];
    
    // Make a "corrupt" zip file
    NSURL *m4aFileURL = [self urlOfTestFile:@"Test File C.m4a"];
    self.corruptArchive = [self.tempDirectory URLByAppendingPathComponent:@"corrupt.zip"];
    [fm copyItemAtURL:m4aFileURL
                toURL:self.corruptArchive
                error:&error];
}

- (void)tearDown {
    if (!self.testFailed) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:self.tempDirectory error:&error];
        
        XCTAssertNil(error, @"Error deleting temp directory");
    }
    
    [super tearDown];
}



#pragma mark - Helper Methods


+ (NSDateFormatter *)dateFormatter {
    return testFileInfoDateFormatter;
}

- (NSURL *)urlOfTestFile:(NSString *)filename
{
    NSString *baseDirectory = @"Test Data";
    NSString *subPath = filename.stringByDeletingLastPathComponent;
    NSString *bundleSubdir = [baseDirectory stringByAppendingPathComponent:subPath];
    
    return [[NSBundle bundleForClass:[self class]] URLForResource:filename.lastPathComponent
                                                    withExtension:nil
                                                     subdirectory:bundleSubdir];
}

- (NSString *)randomDirectoryName
{
    NSString *globallyUnique = [[NSProcessInfo processInfo] globallyUniqueString];
    NSRange firstHyphen = [globallyUnique rangeOfString:@"-"];
    return [globallyUnique substringToIndex:firstHyphen.location];
}

- (NSString *)randomDirectoryWithPrefix:(NSString *)prefix
{
    return [NSString stringWithFormat:@"%@ %@", prefix, [self randomDirectoryName]];
}

- (NSInteger)numberOfOpenFileHandles {
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/sbin/lsof";
    task.arguments = @[@"-P", @"-n", @"-p", [NSString stringWithFormat:@"%d", pid]];
    task.standardOutput = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *lsofOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
//    NSLog(@"LSOF output:\n%@", lsofOutput);
    
    NSInteger result = [lsofOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].count;
//    NSLog(@"LSOF result: %ld", result);
    
    return result;
}

- (NSURL *)emptyTextFileOfLength:(NSUInteger)fileSize
{
    NSURL *resultURL = [self.tempDirectory URLByAppendingPathComponent:
                        [NSString stringWithFormat:@"%@.txt", [[NSProcessInfo processInfo] globallyUniqueString]]];
    
    [[NSFileManager defaultManager] createFileAtPath:(NSString *__nonnull)resultURL.path
                                            contents:nil
                                          attributes:nil];
    
    NSError *error = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:resultURL
                                                                 error:&error];
    XCTAssertNil(error, @"Error creating file handle for URL: %@", resultURL);
    
    [fileHandle seekToFileOffset:fileSize];
    [fileHandle writeData:(NSData *__nonnull)[@"\x00" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
    
    return resultURL;
}

- (NSURL *)archiveWithFiles:(NSArray *)fileURLs
{
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    return [self archiveWithFiles:fileURLs name:uniqueString];
}

- (NSURL *)archiveWithFiles:(NSArray *)fileURLs name:(NSString *)name
{
    NSURL *archiveURL = [[self.tempDirectory URLByAppendingPathComponent:name]
                         URLByAppendingPathExtension:@"zip"];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/zip";
    task.arguments = [@[@"-j", archiveURL.path] arrayByAddingObjectsFromArray:(NSArray *__nonnull)[fileURLs valueForKeyPath:@"path"]];
    
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus != 0) {
        NSLog(@"Failed to create zip archive");
        return nil;
    }
    
    return archiveURL;
}

- (BOOL)extractArchive:(NSURL *)url password:(NSString *)password
{
    NSMutableArray *args = [NSMutableArray array];
    if (password) {
        [args addObjectsFromArray:@[@"-P", password]];
    }
    
    [args addObjectsFromArray:@[url.path, @"-d", url.path.stringByDeletingPathExtension]];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = args;
    
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus != 0) {
        NSLog(@"Failed to extract zip archive");
        return NO;
    }
    
    return YES;
}

- (NSURL *)largeArchive
{
    NSMutableArray *emptyFiles = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [emptyFiles addObject:[self emptyTextFileOfLength:20000000]];
    }
    
    static NSInteger archiveNumber = 1;
    NSURL *largeArchiveURL = [self archiveWithFiles:emptyFiles
                                               name:[NSString stringWithFormat:@"Large Archive %ld", archiveNumber++]];
    return largeArchiveURL;
}

- (NSUInteger)crcOfTestFile:(NSString *)filename
{
    NSURL *fileURL = [self urlOfTestFile:filename];
    NSData *fileContents = [[NSFileManager defaultManager] contentsAtPath:fileURL.path];
    return crc32(0, fileContents.bytes, (uInt)fileContents.length);
}


@end