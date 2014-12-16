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
        
        XCTAssertNil(error, @"Error returned by unzipListFiles");
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



#pragma mark - Helper Methods


- (NSURL *)urlOfTestFile:(NSString *)fileName
{
    NSString *name = [fileName stringByDeletingPathExtension];
    NSString *extension = [fileName pathExtension];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name
                                                                      ofType:extension
                                                                 inDirectory:@"Test Data"];
    return [NSURL fileURLWithPath:path];
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
@end
