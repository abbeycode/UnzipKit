//
//  UZKArchiveTests.m
//  UZKArchiveTests
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

@import UnzipKit;


@interface UZKArchiveTests : XCTestCase

@property BOOL testFailed;

@property NSURL *tempDirectory;
@property NSMutableDictionary *testFileURLs;
@property NSMutableDictionary *unicodeFileURLs;
@property NSURL *corruptArchive;

@end

@implementation UZKArchiveTests



#pragma mark - Test Management


- (void)setUp {
    [super setUp];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *uniqueName = [self randomDirectoryName];
    NSError *error = nil;
    
    NSArray *testFiles = @[@"Test Archive.zip",
                           @"Test Archive (Password).zip",
                           @"L'incertain.zip",
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
    
    // Make a "corrupt" rar file
    NSURL *m4aFileURL = [self urlOfTestFile:@"Test File C.m4a"];
    self.corruptArchive = [self.tempDirectory URLByAppendingPathComponent:@"corrupt.zip"];
    [fm copyItemAtURL:m4aFileURL
                toURL:self.corruptArchive
                error:&error];
    
    XCTAssertNil(error, @"Failed to create corrupt archive (copy from %@ to %@)", m4aFileURL, self.corruptArchive);
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
    
    static NSDateFormatter *testFileInfoDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testFileInfoDateFormatter = [[NSDateFormatter alloc] init];
        testFileInfoDateFormatter.dateFormat = @"M/dd/yyyy h:mm a";
        testFileInfoDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    });
    
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
    
    XCTAssertNil(error, @"Error returned by unrarListFiles");
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
        XCTAssertTrue(success, @"Unrar failed to extract %@ to %@", testArchiveName, extractURL);
        
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
    XCTAssertTrue(success, @"Unrar failed to extract %@ to %@", testArchiveName, extractURL);
    
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

- (NSUInteger)crcOfTestFile:(NSString *)filename {
    NSURL *fileURL = [self urlOfTestFile:filename];
    NSData *fileContents = [[NSFileManager defaultManager] contentsAtPath:fileURL.path];
    return crc32(0, fileContents.bytes, (uInt)fileContents.length);
}


@end
