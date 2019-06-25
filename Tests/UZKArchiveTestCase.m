//
//  UZKArchiveTestCase.m
//  UnzipKit
//
//  Created by Dov Frankel on 6/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"

#import "unzip.h"
#import "UnzipKitMacros.h"

static NSDateFormatter *testFileInfoDateFormatter;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#if UNIFIED_LOGGING_SUPPORTED
os_log_t unzipkit_log;
BOOL unzipkitIsAtLeast10_13SDK;
#endif
#pragma clang diagnostic pop


@implementation UZKArchiveTestCase



#pragma mark - Setup/Teardown

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UZKLogInit();
    });
}

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
    
    NSArray *testFiles = @[
                           @"Test Archive.zip",
                           @"Test Archive (Password).zip",
                           @"L'incertain.zip",
                           @"Aces.zip",
                           @"Comments Archive.zip",
                           @"Empty Archive.zip",
                           @"Spanned Archive.zip.001",
                           @"Test File A.txt",
                           @"Test File B.jpg",
                           @"Test File C.m4a",
                           @"NotAZip-PK-ContentsUnknown",
                           @"Modified CRC Archive.zip",
                           ];
    
    NSArray *unicodeFiles = @[
                              @"Ⓣest Ⓐrchive.zip",
                              @"Test File Ⓐ.txt",
                              @"Test File Ⓑ.jpg",
                              @"Test File Ⓒ.m4a",
                              ];
    
    NSString *tempDirSubtree = [@"UnzipKitTest" stringByAppendingPathComponent:uniqueName];
    
    self.testFailed = NO;
    self.testFileURLs = [[NSMutableDictionary alloc] init];
    self.unicodeFileURLs = [[NSMutableDictionary alloc] init];
    self.tempDirectory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempDirSubtree]
                                    isDirectory:YES];
    
    UZKLog("Temp directory: %@", self.tempDirectory);
    
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
        return [key.lowercaseString rangeOfString:@"zip"].location == NSNotFound;
    }];
    
    self.nonZipUnicodeFilePaths = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return [key.lowercaseString rangeOfString:@"zip"].location == NSNotFound;
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
    
    NSData *emptyByte = [@"\x01" dataUsingEncoding:NSUTF8StringEncoding];
    
    [fileHandle writeData:emptyByte];
    [fileHandle seekToFileOffset:fileSize];
    [fileHandle writeData:emptyByte];
    [fileHandle closeFile];
    
    return resultURL;
}

#if !TARGET_OS_IPHONE

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
    
//    UZKLog("LSOF output:\n%@", lsofOutput);
    
    NSInteger result = [lsofOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].count;
//    UZKLog("LSOF result: %ld", result);
    
    return result;
}

- (NSURL *)archiveWithFiles:(NSArray *)fileURLs
{
    return [self archiveWithFiles:fileURLs password:nil];
}

- (NSURL *)archiveWithFiles:(NSArray *)fileURLs password:(NSString *)password
{
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    return [self archiveWithFiles:fileURLs password:password name:uniqueString];
}

- (NSURL *)archiveWithFiles:(NSArray *)fileURLs password:(NSString *)password name:(NSString *)name
{
    NSURL *archiveURL = [[self.tempDirectory URLByAppendingPathComponent:name]
                         URLByAppendingPathExtension:@"zip"];
    NSFileHandle *consoleOutputHandle = nil;
    
    if (fileURLs.count > 100) {
        NSURL *consoleOutputFile = [archiveURL URLByAppendingPathExtension:@"filewriteoutput.txt"];
        [[NSFileManager defaultManager] createFileAtPath:(NSString *__nonnull)consoleOutputFile.path
                                                contents:nil
                                              attributes:nil];

        consoleOutputHandle = [NSFileHandle fileHandleForWritingAtPath:consoleOutputFile.path];
        
        UZKLog("Writing zip command output to: %@", consoleOutputFile.path);
    }
    
    const NSUInteger maxFilesPerCall = 1500;
    NSArray *filePaths = (NSArray *__nonnull)[fileURLs valueForKeyPath:@"path"];
    
    NSUInteger startIndex = 0;
    NSUInteger pathsRemaining = filePaths.count;
    
    while (startIndex < filePaths.count) {
        @autoreleasepool {
            NSMutableArray<NSString*> *zipArgs = [NSMutableArray arrayWithArray:
                                                  @[@"-j", archiveURL.path]];
            
            if (password) {
                [zipArgs addObjectsFromArray:@[@"-P", password]];
            }
            
            NSRange currentRange = NSMakeRange(startIndex, MIN(pathsRemaining, maxFilesPerCall));
            NSArray *pathArrayChunk = [filePaths subarrayWithRange:currentRange];
            
            [zipArgs addObjectsFromArray:pathArrayChunk];
            
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/usr/bin/zip";
            task.arguments = zipArgs;
            task.standardOutput = consoleOutputHandle;
            
            UZKLog("Compressing files %lu-%lu of %lu", startIndex + 1, startIndex + pathArrayChunk.count, filePaths.count);

            [task launch];
            [task waitUntilExit];
            
            if (task.terminationStatus != 0) {
                if (startIndex == 0) {
                    UZKLog("Failed to create zip archive");
                } else {
                    UZKLog("Failed to add files to zip archive");
                }
                return nil;
            }
            
            pathsRemaining -= currentRange.length;
            startIndex += currentRange.length;
        }
    }

    if (consoleOutputHandle) {
        [consoleOutputHandle closeFile];
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
        UZKLog("Failed to extract zip archive");
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
                                           password:nil
                                               name:[NSString stringWithFormat:@"Large Archive %ld", archiveNumber++]];
    return largeArchiveURL;
}

#endif

- (NSUInteger)crcOfFile:(NSURL *)url
{
    NSData *fileContents = [[NSFileManager defaultManager] contentsAtPath:url.path];
    return crc32(0, fileContents.bytes, (uInt)fileContents.length);
}

- (NSUInteger)crcOfTestFile:(NSString *)filename
{
    NSURL *fileURL = [self urlOfTestFile:filename];
    return [self crcOfFile:fileURL];
}


@end
