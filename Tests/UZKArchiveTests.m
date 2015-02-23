//
//  UZKArchiveTests.m
//  UZKArchiveTests
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <DTPerformanceSession/DTSignalFlag.h>

@import UnzipKit;


@interface UZKArchiveTests : XCTestCase

@property BOOL testFailed;

@property NSURL *tempDirectory;
@property NSMutableDictionary *testFileURLs;
@property NSMutableDictionary *unicodeFileURLs;
@property NSURL *corruptArchive;

@end

static NSDateFormatter *testFileInfoDateFormatter;

@implementation UZKArchiveTests



#pragma mark - Test Management


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
        BOOL testFileExists = [fm fileExistsAtPath:testFileURL.path];
        XCTAssertTrue(testFileExists, @"%@ not found", file);
        
        NSURL *destinationURL = [self.tempDirectory URLByAppendingPathComponent:file isDirectory:NO];
        
        NSError *error = nil;
        if (file.pathComponents.count > 1) {
            [fm createDirectoryAtPath:destinationURL.URLByDeletingLastPathComponent.path
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



#pragma mark - Test Cases


#pragma mark Archive File


- (void)testFileURL {
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
        
        NSURL *resolvedURL = archive.fileURL.URLByResolvingSymlinksInPath;
        XCTAssertNotNil(resolvedURL, @"Nil URL returned for valid archive");
        XCTAssertTrue([testArchiveURL isEqual:resolvedURL], @"Resolved URL doesn't match original");
    }
}

- (void)testFilename {
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
        
        NSString *resolvedFilename = archive.filename;
        XCTAssertNotNil(resolvedFilename, @"Nil filename returned for valid archive");
        
        // Testing by suffix, since the original points to /private/var, but the resolved one
        // points straight to /var. They're equivalent, but not character-for-character equal
        XCTAssertTrue([resolvedFilename hasSuffix:testArchiveURL.path],
                      @"Resolved filename doesn't match original");
    }
}


#pragma mark List Filenames


- (void)testListFilenames
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
        
        NSError *error = nil;
        NSArray *filesInArchive = [archive listFilenames:&error];
        
        XCTAssertNil(error, @"Error returned by listFilenames");
        XCTAssertNotNil(filesInArchive, @"No list of files returned");
        XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                       @"Incorrect number of files listed in archive");
        
        for (NSInteger i = 0; i < filesInArchive.count; i++) {
            NSString *archiveFilename = filesInArchive[i];
            NSString *expectedFilename = expectedFiles[i];
            
            XCTAssertEqualObjects(archiveFilename, expectedFilename, @"Incorrect filename listed");
        }
    }
}

- (void)testListFilenames_Unicode
{
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFilenames:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        NSString *archiveFilename = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(archiveFilename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFilenames_Password
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:@"password"];
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFilenames:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        NSString *archiveFilename = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(archiveFilename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFilenames_NoPasswordGiven
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFilenames:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        NSString *archiveFilename = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(archiveFilename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFilenames_InvalidArchive
{
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test File A.txt"]];
    
    NSError *error = nil;
    NSArray *files = [archive listFilenames:&error];
    
    XCTAssertNotNil(error, @"List files of invalid archive succeeded");
    XCTAssertNil(files, @"List returned for invalid archive");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
}


#pragma mark List File Info


- (void)testListFileInfo {
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test Archive.zip"]];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSDate *expectedDate = [testFileInfoDateFormatter dateFromString:@"3/22/2014 11:17 PM"];
    NSDictionary *expectedCompressionMethods = @{@"Test File A.txt": @(UZKCompressionMethodNone),
                                                 @"Test File B.jpg": @(UZKCompressionMethodDefault),
                                                 @"Test File C.m4a": @(UZKCompressionMethodDefault),};

    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFileInfo");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count, @"Incorrect number of files listed in archive");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        
        // Test Filename
        NSString *expectedFilename = expectedFiles[i];
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename");
        
        // Test CRC
        NSUInteger expectedFileCRC = [self crcOfTestFile:expectedFilename];
        XCTAssertEqual(fileInfo.CRC, expectedFileCRC, @"Incorrect CRC checksum");
        
        // Test Last Modify Date
        NSTimeInterval archiveFileTimeInterval = [fileInfo.timestamp timeIntervalSinceReferenceDate];
        NSTimeInterval expectedFileTimeInterval = [expectedDate timeIntervalSinceReferenceDate];
        XCTAssertEqualWithAccuracy(archiveFileTimeInterval, expectedFileTimeInterval, 60, @"Incorrect file timestamp (more than 60 seconds off)");
        
        // Test Uncompressed Size
        NSError *attributesError = nil;
        NSString *expectedFilePath = [[self urlOfTestFile:expectedFilename] path];
        NSDictionary *expectedFileAttributes = [fm attributesOfItemAtPath:expectedFilePath
                                                                    error:&attributesError];
        XCTAssertNil(attributesError, @"Error getting file attributes of %@", expectedFilename);
        
        long long expectedFileSize = expectedFileAttributes.fileSize;
        XCTAssertEqual(fileInfo.uncompressedSize, expectedFileSize, @"Incorrect uncompressed file size");
        
        // Test Compression method
        UZKCompressionMethod expectedCompressionMethod = ((NSNumber *)expectedCompressionMethods[fileInfo.filename]).integerValue;
        XCTAssertEqual(fileInfo.compressionMethod, expectedCompressionMethod, @"Incorrect compression method");
    }
}

- (void)testListFileInfo_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFileInfo");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFiles[i], @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_WinZip
{
    NSURL *testArchiveURL = self.testFileURLs[@"L'incertain.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    NSArray *expectedFiles = @[@"Acribor‚a - T01 - L'incertain/Test File A.txt",
                               @"Acribor‚a - T01 - L'incertain/Test File B.jpg",
                               @"Acribor‚a - T01 - L'incertain/Test File C.m4a",
                               @"Acribor‚a - T01 - L'incertain"];
    NSArray *isDirectoryValues = @[@NO,
                                   @NO,
                                   @NO,
                                   @YES];
    
    NSError *error = nil;
    NSArray *filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertNotNil(filesInArchive, @"No list of files returned");
    XCTAssertEqual(filesInArchive.count, expectedFiles.count, @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = (UZKFileInfo *)filesInArchive[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFiles[i], @"Incorrect filename listed");
        
        BOOL expectedIsDirectory = ((NSNumber *)isDirectoryValues[i]).boolValue;
        XCTAssertEqual(fileInfo.isDirectory, expectedIsDirectory, @"Incorrect isDirectory value listed");
    }
}

- (void)testListFileInfo_Password
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:@"password"];
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_NoPasswordGiven {
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSArray *filesInArchive = nil;
    NSError *error = nil;
    filesInArchive = [archive listFileInfo:&error];
    
    XCTAssertNil(error, @"Error returned by listFilenames");
    XCTAssertEqual(filesInArchive.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < filesInArchive.count; i++) {
        UZKFileInfo *fileInfo = filesInArchive[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Incorrect filename listed");
    }
}

- (void)testListFileInfo_InvalidArchive
{
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test File A.txt"]];
    
    NSError *error = nil;
    NSArray *files = [archive listFileInfo:&error];
    
    XCTAssertNotNil(error, @"List files of invalid archive succeeded");
    XCTAssertNil(files, @"List returned for invalid archive");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
}


#pragma mark Extract Files


- (void)testExtractFiles
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                      [testArchiveName stringByDeletingPathExtension]];
        NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
        
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        NSError *error = nil;
        BOOL success = [archive extractFilesTo:extractURL.path
                                     overwrite:NO
                                      progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                          NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                      }
                                         error:&error];
        
        XCTAssertNil(error, @"Error returned by extractFilesTo:overWrite:error:");
        XCTAssertTrue(success, @"Failed to extract %@ to %@", testArchiveName, extractURL);
        
        error = nil;
        NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                          error:&error];
        
        XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
        
        XCTAssertNotNil(extractedFiles, @"No list of files returned");
        XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                       @"Incorrect number of files listed in archive");
        
        for (NSInteger i = 0; i < extractedFiles.count; i++) {
            NSString *extractedFilename = extractedFiles[i];
            NSString *expectedFilename = expectedFiles[i];
            
            XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
            
            NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
            NSURL *expectedFileURL = self.testFileURLs[expectedFilename];
            
            NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
            NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
            
            XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
        }
    }
}

- (void)testExtractFiles_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *testArchiveName = @"Ⓣest Ⓐrchive.zip";
    NSURL *testArchiveURL = self.unicodeFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    XCTAssertNil(error, @"Error returned by extractFilesTo:overWrite:error:");
    XCTAssertTrue(success, @"Failed to extract %@ to %@", testArchiveName, extractURL);
    
    error = nil;
    NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                      error:&error];
    
    XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
    
    XCTAssertNotNil(extractedFiles, @"No list of files returned");
    XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < extractedFiles.count; i++) {
        NSString *extractedFilename = extractedFiles[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
        
        NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
        NSURL *expectedFileURL = self.unicodeFileURLs[expectedFilename];
        
        NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
        NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
        
        XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
    }
}

- (void)testExtractFiles_NoPasswordGiven
{
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test Archive (Password).zip"]];

    NSString *extractDirectory = [self randomDirectoryWithPrefix:archive.filename.stringByDeletingPathExtension];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
    
    XCTAssertFalse(success, @"Extract without password succeeded");
    XCTAssertEqual(error.code, UZKErrorCodeInvalidPassword, @"Unexpected error code returned");
    XCTAssertFalse(dirExists, @"Directory successfully created without password");
}

- (void)testExtractFiles_InvalidArchive
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test File A.txt"]];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:@"ExtractInvalidArchive"];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
    
    XCTAssertFalse(success, @"Extract invalid archive succeeded");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
    XCTAssertFalse(dirExists, @"Directory successfully created for invalid archive");
}

- (void)testExtractFiles_Aces
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Aces.zip"]];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:@"ExtractAcesArchive"];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    XCTAssertTrue(success, @"Extract Aces archive failed");
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                         enumeratorAtURL:extractURL
                                         includingPropertiesForKeys:nil
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             XCTFail(@"Error listing contents of directory %@: %@", url, error);
                                             return NO;
                                         }];
    
    NSArray *expectedFiles = @[
                               @"aces-dev-1.0",
                               @"aces-dev-1.0/CHANGELOG.md",
                               @"aces-dev-1.0/documents",
                               @"aces-dev-1.0/documents/README.md",
                               @"aces-dev-1.0/images",
                               @"aces-dev-1.0/images/README.md",
                               @"aces-dev-1.0/LICENSE.md",
                               @"aces-dev-1.0/README.md",
                               ];
    
    NSUInteger i = 0;

    for (NSURL *extractedURL in enumerator) {
        NSString *actualPath = extractedURL.path;
        NSString *expectedPath = expectedFiles[i++];
        XCTAssertTrue([actualPath hasSuffix:expectedPath], @"Unexpected file extracted: %@", actualPath);
    }
}


#pragma mark Extract Data


- (void)testExtractData
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *testArchiveName in testArchives) {
        
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        NSError *error = nil;
        NSArray *fileInfos = [archive listFileInfo:&error];
        XCTAssertNil(error, @"Error reading file info");
        
        for (NSInteger i = 0; i < expectedFiles.count; i++) {
            NSString *expectedFilename = expectedFiles[i];
            
            NSError *error = nil;
            NSData *extractedData = [archive extractDataFromFile:expectedFilename
                                                        progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                                            NSLog(@"Extracting, %f%% complete", percentDecompressed);
#endif
                                                        }
                                                           error:&error];
            
            XCTAssertNil(error, @"Error in extractData:error:");
            
            NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
            
            XCTAssertNotNil(extractedData, @"No data extracted (%@)", testArchiveName);
            XCTAssertTrue([expectedFileData isEqualToData:extractedData], @"Extracted data doesn't match original file (%@)", testArchiveName);
            
            error = nil;
            NSData *dataFromFileInfo = [archive extractData:fileInfos[i]
                                                   progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                                       NSLog(@"Extracting from file info, %f%% complete", percentDecompressed);
#endif
                                                   }
                                                      error:&error];
            XCTAssertNil(error, @"Error extracting data by file info (%@)", testArchiveName);
            XCTAssertTrue([expectedFileData isEqualToData:dataFromFileInfo], @"Extracted data from file info doesn't match original file (%@)", testArchiveName);
        }
    }
}

- (void)testExtractData_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    NSArray *fileInfos = [archive listFileInfo:&error];
    XCTAssertNil(error, @"Error reading file info");
    
    for (NSInteger i = 0; i < expectedFiles.count; i++) {
        NSString *expectedFilename = expectedFiles[i];
        
        NSError *error = nil;
        NSData *extractedData = [archive extractDataFromFile:expectedFilename
                                                    progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                                        NSLog(@"Extracting, %f%% complete", percentDecompressed);
#endif
                                                    }
                                                       error:&error];
        
        XCTAssertNil(error, @"Error in extractData:error:");
        
        NSData *expectedFileData = [NSData dataWithContentsOfURL:self.unicodeFileURLs[expectedFilename]];
        
        XCTAssertNotNil(extractedData, @"No data extracted");
        XCTAssertTrue([expectedFileData isEqualToData:extractedData], @"Extracted data doesn't match original file (%@)", expectedFilename);
        
        error = nil;
        NSData *dataFromFileInfo = [archive extractData:fileInfos[i]
                                               progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                                   NSLog(@"Extracting from file info, %f%% complete", percentDecompressed);
#endif
                                               }
                                                  error:&error];
        XCTAssertNil(error, @"Error extracting data by file info");
        XCTAssertTrue([expectedFileData isEqualToData:dataFromFileInfo], @"Extracted data from file info doesn't match original file (%@)", expectedFilename);
    }
}

- (void)testExtractData_NoPassword
{
    NSArray *testArchives = @[@"Test Archive (Password).zip"];
    
    for (NSString *testArchiveName in testArchives) {
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[testArchiveName]];
        
        NSError *error = nil;
        NSData *data = [archive extractDataFromFile:@"Test File A.txt"
                                           progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                               NSLog(@"Extracting, %f%% complete", percentDecompressed);
#endif
                                           }
                                              error:&error];
        
        XCTAssertNotNil(error, @"Extract data without password succeeded");
        XCTAssertNil(data, @"Data returned without password");
        XCTAssertEqual(error.code, UZKErrorCodeInvalidPassword, @"Unexpected error code returned");
    }
}

- (void)testExtractData_InvalidArchive
{
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test File A.txt"]];
    
    NSError *error = nil;
    NSData *data = [archive extractDataFromFile:@"Any file.txt"
                                       progress:^(CGFloat percentDecompressed) {
#if DEBUG
                                           NSLog(@"Extracting, %f%% complete", percentDecompressed);
#endif
                                       }
                                          error:&error];
    
    XCTAssertNotNil(error, @"Extract data for invalid archive succeeded");
    XCTAssertNil(data, @"Data returned for invalid archive");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
}


#pragma mark Perform on Files


- (void)testPerformOnFiles
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnFilesInArchive:
         ^(UZKFileInfo *fileInfo, BOOL *stop) {
             NSString *expectedFilename = expectedFiles[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, expectedFiles.count, @"Incorrect number of files encountered");
    }
}

- (void)testPerformOnFiles_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSUInteger fileIndex = 0;
    NSError *error = nil;
    
    [archive performOnFilesInArchive:
     ^(UZKFileInfo *fileInfo, BOOL *stop) {
         NSString *expectedFilename = expectedFiles[fileIndex++];
         XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
     } error:&error];
    
    XCTAssertNil(error, @"Error iterating through files");
    XCTAssertEqual(fileIndex, expectedFiles.count, @"Incorrect number of files encountered");
}


#pragma mark Perform on Data


- (void)testPerformOnData
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = expectedFiles[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, expectedFiles.count, @"Incorrect number of files encountered");
    }
}

- (void)testPerformOnData_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSURL *testArchiveURL = self.unicodeFileURLs[@"Ⓣest Ⓐrchive.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSUInteger fileIndex = 0;
    NSError *error = nil;
    
    [archive performOnDataInArchive:
     ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
         NSString *expectedFilename = expectedFiles[fileIndex++];
         XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
         
         NSData *expectedFileData = [NSData dataWithContentsOfURL:self.unicodeFileURLs[expectedFilename]];
         
         XCTAssertNotNil(fileData, @"No data extracted");
         XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
     } error:&error];
    
    XCTAssertNil(error, @"Error iterating through files");
    XCTAssertEqual(fileIndex, expectedFiles.count, @"Incorrect number of files encountered");
}

- (void)testPerformOnData_FileMoved
{
    NSURL *largeArchiveURL = [self largeArchive];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:largeArchiveURL];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1];
        
        NSURL *movedURL = [largeArchiveURL URLByAppendingPathExtension:@"unittest"];
        
        NSError *renameError = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm moveItemAtURL:largeArchiveURL toURL:movedURL error:&renameError];
        XCTAssertNil(renameError, @"Error renaming file: %@", renameError);
    });
    
    __block NSUInteger fileCount = 0;
    
    NSError *error = nil;
    BOOL success = [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        XCTAssertNotNil(fileData, @"Extracted file is nil: %@", fileInfo.filename);
        
        if (!fileInfo.isDirectory) {
            fileCount++;
            XCTAssertGreaterThan(fileData.length, 0, @"Extracted file is empty: %@", fileInfo.filename);
        }
    } error:&error];
    
    XCTAssertEqual(fileCount, 5, @"Not all files read");
    XCTAssertTrue(success, @"Failed to read files");
    XCTAssertNil(error, @"Error reading files: %@", error);
}

- (void)testPerformOnData_FileDeleted
{
    NSURL *largeArchiveURL = [self largeArchive];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:largeArchiveURL];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1];
        
        NSError *removeError = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL:largeArchiveURL error:&removeError];
        XCTAssertNil(removeError, @"Error removing file: %@", removeError);
    });
    
    __block NSUInteger fileCount = 0;
    
    NSError *error = nil;
    BOOL success = [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        XCTAssertNotNil(fileData, @"Extracted file is nil: %@", fileInfo.filename);
        
        if (!fileInfo.isDirectory) {
            fileCount++;
            XCTAssertGreaterThan(fileData.length, 0, @"Extracted file is empty: %@", fileInfo.filename);
        }
    } error:&error];
    
    XCTAssertEqual(fileCount, 5, @"Not all files read");
    XCTAssertTrue(success, @"Failed to read files");
    XCTAssertNil(error, @"Error reading files: %@", error);
}

- (void)testPerformOnData_FileMovedBeforeBegin
{
    NSURL *largeArchiveURL = [self largeArchive];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:largeArchiveURL];
    
    NSURL *movedURL = [largeArchiveURL URLByAppendingPathExtension:@"unittest"];
    
    NSError *renameError = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm moveItemAtURL:largeArchiveURL toURL:movedURL error:&renameError];
    XCTAssertNil(renameError, @"Error renaming file: %@", renameError);
    
    __block NSUInteger fileCount = 0;
    
    NSError *error = nil;
    BOOL success = [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        XCTAssertNotNil(fileData, @"Extracted file is nil: %@", fileInfo.filename);
        
        if (!fileInfo.isDirectory) {
            fileCount++;
            XCTAssertGreaterThan(fileData.length, 0, @"Extracted file is empty: %@", fileInfo.filename);
        }
    } error:&error];
    
    XCTAssertEqual(fileCount, 5, @"Not all files read");
    XCTAssertTrue(success, @"Failed to read files");
    XCTAssertNil(error, @"Error reading files: %@", error);
}


#pragma mark Extract Buffered Data


- (void)testExtractBufferedData
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    NSString *extractedFile = @"Test File B.jpg";
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
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
    XCTAssertGreaterThan(reconstructedFile.length, 0, @"No data returned");
    
    NSData *originalFile = [NSData dataWithContentsOfURL:self.testFileURLs[extractedFile]];
    XCTAssertTrue([originalFile isEqualToData:reconstructedFile],
                  @"File extracted in buffer not returned correctly");
}

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
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
    DTSendSignalFlag("Begin extracting buffered data", DT_START_SIGNAL, TRUE);
    
    NSError *error = nil;
    BOOL success = [archive extractBufferedDataFromFile:largeTextFile.lastPathComponent
                                                  error:&error
                                                 action:
                    ^(NSData *dataChunk, CGFloat percentDecompressed) {
#if DEBUG
                        NSLog(@"Decompressed: %f%%", percentDecompressed);
#endif
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


#pragma mark Is Password Protected


- (void)testIsPasswordProtected_PasswordRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
    XCTAssertTrue(archive.isPasswordProtected, @"isPasswordProtected = NO for password-protected archive");
}

- (void)testIsPasswordProtected_PasswordNotRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
    XCTAssertFalse(archive.isPasswordProtected, @"isPasswordProtected = YES for password-protected archive");
}


#pragma mark Validate Password


- (void)testValidatePassword_PasswordRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive (Password).zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
    XCTAssertFalse(archive.validatePassword, @"validatePassword = YES when no password supplied");
    
    archive.password = @"wrong";
    XCTAssertFalse(archive.validatePassword, @"validatePassword = YES when wrong password supplied");
    
    archive.password = @"password";
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when correct password supplied");
}

- (void)testValidatePassword_PasswordNotRequired
{
    NSURL *archiveURL = self.testFileURLs[@"Test Archive.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:archiveURL];
    
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when no password supplied");
    
    archive.password = @"password";
    XCTAssertTrue(archive.validatePassword, @"validatePassword = NO when password supplied");
}


#pragma mark Write Data


- (void)testWriteData
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteDataTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        BOOL result = [archive writeData:fileData
                                filePath:testFile
                                fileDate:testDates[idx]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
}

- (void)testWriteData_Unicode
{
    NSSet *testFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"UnicodeWriteDataTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.unicodeFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        BOOL result = [archive writeData:fileData
                                filePath:testFile
                                fileDate:testDates[idx]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
}

- (void)testWriteData_Overwrite
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"RewriteDataTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        BOOL result = [archive writeData:fileData
                                filePath:testFile
                                fileDate:testDates[idx]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
    
    // Now write the files' contents to the zip in reverse
    NSLog(@"Testing a second write, by reversing the contents and timestamps of the files from the first run");
    
    __block NSError *reverseWriteError = nil;
    
    for (NSUInteger i = 0; i < testFiles.count; i++) {
        NSUInteger x = testFiles.count - 1 - i;
        
        BOOL result = [archive writeData:testFileData[x]
                                filePath:testFiles[i]
                                fileDate:testDates[x]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&reverseWriteError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(reverseWriteError, @"Error writing to file %@ with data of file %@: %@",
                     testFiles[x], testFiles[i], reverseWriteError);
    }
    
    __block NSError *reverseReadError = nil;
    __block NSUInteger forwardIndex = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        XCTAssertEqualObjects(fileInfo.filename, testFiles[forwardIndex], @"Incorrect filename in archive");
        
        NSUInteger reverseIndex = testFiles.count - 1 - forwardIndex;
        
        NSData *expectedData = testFileData[reverseIndex];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[reverseIndex], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertTrue([fileData isEqualToData:expectedData], @"Data extracted doesn't match what was written");
        
        forwardIndex++;
    } error:&reverseReadError];
    
    XCTAssertNil(reverseReadError, @"Error reading a re-written archive");
}

- (void)testWriteData_Overwrite_Unicode
{
    NSSet *testFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"RewriteDataTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.unicodeFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        BOOL result = [archive writeData:fileData
                                filePath:testFile
                                fileDate:testDates[idx]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
    
    // Now write the files' contents to the zip in reverse
    NSLog(@"Testing a second write, by reversing the contents and timestamps of the files from the first run");
    
    __block NSError *reverseWriteError = nil;
    
    for (NSUInteger i = 0; i < testFiles.count; i++) {
        NSUInteger x = testFiles.count - 1 - i;
        
        BOOL result = [archive writeData:testFileData[x]
                                filePath:testFiles[i]
                                fileDate:testDates[x]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&reverseWriteError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(reverseWriteError, @"Error writing to file %@ with data of file %@: %@",
                     testFiles[x], testFiles[i], reverseWriteError);
    }
    
    __block NSError *reverseReadError = nil;
    __block NSUInteger forwardIndex = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        XCTAssertEqualObjects(fileInfo.filename, testFiles[forwardIndex], @"Incorrect filename in archive");
        
        NSUInteger reverseIndex = testFiles.count - 1 - forwardIndex;
        
        NSData *expectedData = testFileData[reverseIndex];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[reverseIndex], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertTrue([fileData isEqualToData:expectedData], @"Data extracted doesn't match what was written");
        
        forwardIndex++;
    } error:&reverseReadError];
    
    XCTAssertNil(reverseReadError, @"Error reading a re-written archive");
}

- (void)testWriteData_NoOverwrite
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"RewriteDataTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    __block NSError *writeError = nil;
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        BOOL result = [archive writeData:fileData
                                filePath:testFile
                                fileDate:testDates[idx]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                               overwrite:NO
                                progress:nil
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
    
    // Now write the files' contents to the zip in reverse. No writes should occur, with overwrite:NO
    
    __block NSError *reverseWriteError = nil;
    NSUInteger originalFileCount = testFiles.count;
    
    for (NSUInteger i = 0; i < originalFileCount; i++) {
        NSUInteger x = testFiles.count - 1 - i;
        
        BOOL result = [archive writeData:testFileData[x]
                                filePath:testFiles[i]
                                fileDate:testDates[x]
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                               overwrite:NO
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&reverseWriteError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(reverseWriteError, @"Error writing to file %@ with data of file %@: %@",
                     testFiles[x], testFiles[i], reverseWriteError);
    }
    
    __block NSError *listError = nil;
    
    NSArray *newFileList = [archive listFileInfo:&listError];
    XCTAssertNil(listError, @"Error reading a re-written archive");
    
    // This is the most we can guarantee, the number of files in the directory
    XCTAssertEqual(newFileList.count, testFiles.count * 2, @"Files not appended correctly");
}

- (void)testWriteData_MultipleWrites
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"MultipleDataWriteTest.zip"];
    NSString *testFilename = testFileSet.anyObject;
    NSURL *testFileURL = self.testFileURLs[testFilename];
    NSData *testFileData = [NSData dataWithContentsOfURL:testFileURL];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    unsigned long long lastFileSize = 0;
    
    for (NSUInteger i = 0; i < 100; i++) {
        NSError *writeError = nil;
        BOOL result = [archive writeData:testFileData
                                filePath:testFilename
                                fileDate:nil
                       compressionMethod:UZKCompressionMethodDefault
                                password:nil
                                progress:^(CGFloat percentCompressed) {
#if DEBUG
                                    NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                                }
                                   error:&writeError];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFileURL, writeError);
        
        NSError *fileSizeError = nil;
        NSNumber *fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:testArchiveURL.path
                                                                              error:&fileSizeError][NSFileSize];
        
        if (lastFileSize > 0) {
            XCTAssertEqual(lastFileSize, fileSize.longLongValue, @"File changed size between writes");
        }
        
        lastFileSize = fileSize.longLongValue;
    }
}

- (void)testWriteData_DefaultDate
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"DefaultDateWriteTest.zip"];
    NSString *testFilename = testFileSet.anyObject;
    NSURL *testFileURL = self.testFileURLs[testFilename];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *writeError = nil;
    BOOL result = [archive writeData:[NSData dataWithContentsOfURL:testFileURL]
                            filePath:testFilename
                            fileDate:nil
                   compressionMethod:UZKCompressionMethodDefault
                            password:nil
                            progress:^(CGFloat percentCompressed) {
#if DEBUG
                                NSLog(@"Compressing data: %f%% complete", percentCompressed);
#endif
                            }
                               error:&writeError];
    
    XCTAssertTrue(result, @"Error writing archive data");
    XCTAssertNil(writeError, @"Error writing to file %@: %@", testFileURL, writeError);
    
    NSError *listError = nil;
    NSArray *fileList = [archive listFileInfo:&listError];
    UZKFileInfo *writtenFileInfo = fileList.firstObject;
    
    NSTimeInterval actualDate = writtenFileInfo.timestamp.timeIntervalSinceReferenceDate;
    NSTimeInterval expectedDate = [NSDate date].timeIntervalSinceReferenceDate;
    
    XCTAssertEqualWithAccuracy(actualDate, expectedDate, 30, @"Incorrect default date value written to file");
}


#pragma mark Write Into Buffer


- (void)testWriteInfoBuffer
{
    NSSet *testFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *testFiles = [testFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSArray *testDates = @[[testFileInfoDateFormatter dateFromString:@"12/20/2014 9:35 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/21/2014 10:00 AM"],
                           [testFileInfoDateFormatter dateFromString:@"12/22/2014 11:54 PM"]];
    NSMutableArray *testFileData = [NSMutableArray arrayWithCapacity:testFiles.count];
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteIntoBufferTest.zip"];
    
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    unsigned int bufferSize = 1024; //Arbitrary
    
    [testFiles enumerateObjectsUsingBlock:^(NSString *testFile, NSUInteger idx, BOOL *stop) {
        NSData *fileData = [NSData dataWithContentsOfURL:self.testFileURLs[testFile]];
        [testFileData addObject:fileData];
        
        NSError *writeError = nil;
        uInt crc = (uInt)crc32(0, fileData.bytes, (uInt)fileData.length);
        const void *bytes = fileData.bytes;
        
        BOOL result = [archive writeIntoBuffer:testFile
                                           CRC:crc
                                      fileDate:testDates[idx]
                             compressionMethod:UZKCompressionMethodDefault
                                      password:nil
                                     overwrite:YES
                                         error:&writeError
                                         block:
                       ^(BOOL(^writeData)(const void *bytes, unsigned int length)) {
                           for (NSUInteger i = 0; i <= fileData.length; i += bufferSize) {
                               unsigned int size = (unsigned int)MIN(fileData.length - i, bufferSize);
                               BOOL writeSuccess = writeData(&bytes[i], size);
                               XCTAssertTrue(writeSuccess, @"Failed to write buffered data");
                           }
                       }];
        
        XCTAssertTrue(result, @"Error writing archive data");
        XCTAssertNil(writeError, @"Error writing to file %@: %@", testFile, writeError);
    }];
    
    __block NSError *readError = nil;
    __block NSUInteger idx = 0;
    
    [archive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
        NSData *expectedData = testFileData[idx];
        uLong expectedCRC = crc32(0, expectedData.bytes, (uInt)expectedData.length);
        
        XCTAssertEqualObjects(fileInfo.filename, testFiles[idx], @"Incorrect filename in archive");
        XCTAssertEqualObjects(fileInfo.timestamp, testDates[idx], @"Incorrect timestamp in archive");
        XCTAssertEqual(fileInfo.CRC, expectedCRC, @"CRC of extracted data doesn't match what was written");
        XCTAssertEqualObjects(fileData, expectedData, @"Data extracted doesn't match what was written");
        
        idx++;
    } error:&readError];
}


#pragma mark Delete File


- (void)testDeleteFile_FirstFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[0];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        NSError *deleteError;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}

- (void)testDeleteFile_SecondFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[1];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        NSError *deleteError;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}

- (void)testDeleteFile_ThirdFile
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"zip"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSString *fileToDelete = expectedFiles[2];
    
    NSMutableArray *newFileList = [NSMutableArray arrayWithArray:expectedFiles];
    [newFileList removeObject:fileToDelete];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL password:password];
        
        NSError *deleteError;
        BOOL result = [archive deleteFile:fileToDelete error:&deleteError];
        XCTAssertTrue(result, @"Failed to delete %@ from %@", fileToDelete, testArchiveName);
        XCTAssertNil(deleteError, @"Error deleting %@ from %@", fileToDelete, testArchiveName);
        
        __block NSUInteger fileIndex = 0;
        NSError *error = nil;
        
        [archive performOnDataInArchive:
         ^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
             NSString *expectedFilename = newFileList[fileIndex++];
             XCTAssertEqualObjects(fileInfo.filename, expectedFilename, @"Unexpected filename encountered");
             
             NSData *expectedFileData = [NSData dataWithContentsOfURL:self.testFileURLs[expectedFilename]];
             
             XCTAssertNotNil(fileData, @"No data extracted");
             XCTAssertTrue([expectedFileData isEqualToData:fileData], @"File data doesn't match original file");
         } error:&error];
        
        XCTAssertNil(error, @"Error iterating through files");
        XCTAssertEqual(fileIndex, newFileList.count, @"Incorrect number of files encountered");
    }
}



#pragma mark - Error Handling


- (void)testNestedError
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    NSData *extractedData = [archive extractDataFromFile:@"file-doesnt-exist.txt"
                                                progress:nil
                                                   error:&error];
    
    XCTAssertNotNil(error, @"No error returned when extracting data for nonexistant archived file");
    XCTAssertEqual(error.code, UZKErrorCodeFileNotFoundInArchive, @"Unexpected error code");

    NSString *description = error.localizedDescription;
    XCTAssertNotEqual([description rangeOfString:@"during buffered read"].location, NSNotFound,
                      @"Incorrect localized description returned in error: '%@'", description);

    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(underlyingError, @"No inner error returned when file doesn't exist");
    XCTAssertEqual(underlyingError.code, UZKErrorCodeFileNotFoundInArchive, @"Unexpected underlying error code");
    
    NSString *underlyingDescription = underlyingError.localizedDescription;
    XCTAssertNotEqual([underlyingDescription rangeOfString:@"No file position found"].location, NSNotFound,
                      @"Incorrect localized description returned in inner error: '%@'", underlyingDescription);
}



#pragma mark - Various


- (void)testFileDescriptorUsage
{
    NSInteger initialFileCount = [self numberOfOpenFileHandles];
    
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveOriginalURL = self.testFileURLs[testArchiveName];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < 1000; i++) {
        NSString *tempDir = [self randomDirectoryName];
        NSURL *tempDirURL = [self.tempDirectory URLByAppendingPathComponent:tempDir];
        NSURL *testArchiveCopyURL = [tempDirURL URLByAppendingPathComponent:testArchiveName];
        
        NSError *error = nil;
        [fm createDirectoryAtURL:tempDirURL
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&error];
        
        XCTAssertNil(error, @"Error creating temp directory: %@", tempDirURL);
        
        [fm copyItemAtURL:testArchiveOriginalURL toURL:testArchiveCopyURL error:&error];
        XCTAssertNil(error, @"Error copying test archive \n from: %@ \n\n   to: %@", testArchiveOriginalURL, testArchiveCopyURL);
        
        UZKArchive *archive = [UZKArchive zipArchiveAtURL:testArchiveCopyURL];
        
        NSArray *fileList = [archive listFilenames:&error];
        XCTAssertNotNil(fileList);
        
        for (NSString *fileName in fileList) {
            NSData *fileData = [archive extractDataFromFile:fileName
                                                   progress:nil
                                                      error:&error];
            XCTAssertNotNil(fileData);
            XCTAssertNil(error);
        }
    }
    
    NSInteger finalFileCount = [self numberOfOpenFileHandles];
    
    XCTAssertEqualWithAccuracy(initialFileCount, finalFileCount, 5, @"File descriptors were left open");
}

- (void)testMultiThreading {
    UZKArchive *largeArchiveA = [UZKArchive zipArchiveAtURL:[self largeArchive]];
    UZKArchive *largeArchiveB = [UZKArchive zipArchiveAtURL:[self largeArchive]];
    UZKArchive *largeArchiveC = [UZKArchive zipArchiveAtURL:[self largeArchive]];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveA performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveB performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveC performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationC fulfill];
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    queue.suspended = YES;
    
    [queue addOperation:enumerateA];
    [queue addOperation:enumerateB];
    [queue addOperation:enumerateC];
    
    queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error while waiting for expectations: %@", error);
        }
    }];
}

- (void)testMultiThreading_SingleFile {
    UZKArchive *largeArchiveA = [UZKArchive zipArchiveAtURL:[self largeArchive]];
    UZKArchive *largeArchiveB = [UZKArchive zipArchiveAtURL:largeArchiveA.fileURL];
    UZKArchive *largeArchiveC = [UZKArchive zipArchiveAtURL:largeArchiveA.fileURL];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveA performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveB performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveC performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationC fulfill];
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    queue.suspended = YES;
    
    [queue addOperation:enumerateA];
    [queue addOperation:enumerateB];
    [queue addOperation:enumerateC];
    
    queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error while waiting for expectations: %@", error);
        }
    }];
}

- (void)testMultiThreading_SingleArchiveObject {
    UZKArchive *largeArchive = [UZKArchive zipArchiveAtURL:[self largeArchive]];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            NSLog(@"File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error);
        [expectationC fulfill];
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    queue.suspended = YES;
    
    [queue addOperation:enumerateA];
    [queue addOperation:enumerateB];
    [queue addOperation:enumerateC];
    
    queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error while waiting for expectations: %@", error);
        }
    }];
}



#pragma mark - Helper Methods


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
    
//    NSLog(@"LSOF:\n%@", lsofOutput);
    
    return [lsofOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].count;
}

- (NSURL *)emptyTextFileOfLength:(NSUInteger)fileSize
{
    NSURL *resultURL = [self.tempDirectory URLByAppendingPathComponent:
                        [NSString stringWithFormat:@"%@.txt", [[NSProcessInfo processInfo] globallyUniqueString]]];
    
    [[NSFileManager defaultManager] createFileAtPath:resultURL.path
                                            contents:nil
                                          attributes:nil];
    
    NSError *error = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:resultURL
                                                                 error:&error];
    XCTAssertNil(error, @"Error creating file handle for URL: %@", resultURL);
    
    [fileHandle seekToFileOffset:fileSize];
    [fileHandle writeData:[@"\x00" dataUsingEncoding:NSUTF8StringEncoding]];
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
    task.arguments = [@[@"-j", archiveURL.path] arrayByAddingObjectsFromArray:[fileURLs valueForKeyPath:@"path"]];
    
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus != 0) {
        NSLog(@"Failed to create zip archive");
        return nil;
    }
    
    return archiveURL;
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
