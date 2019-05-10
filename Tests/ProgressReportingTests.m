//
//  ProgressReportingTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 10/7/17.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"
#import "UnzipKitMacros.h"

@interface ProgressReportingTests : UZKArchiveTestCase

@property (retain) NSMutableArray<NSNumber*> *fractionsCompletedReported;
@property (retain) NSMutableArray<NSString*> *descriptionsReported;
@property (retain) NSMutableArray<NSString*> *additionalDescriptionsReported;
@property (retain) NSMutableArray<UZKFileInfo*> *fileInfosReported;

@end

static void *ExtractFilesContext = &ExtractFilesContext;
static void *OtherContext = &OtherContext;
static void *CancelContext = &CancelContext;

static NSUInteger observerCallCount;


@implementation ProgressReportingTests

- (void)setUp {
    [super setUp];
    
    self.fractionsCompletedReported = [NSMutableArray array];
    self.descriptionsReported = [NSMutableArray array];
    self.additionalDescriptionsReported = [NSMutableArray array];
    self.fileInfosReported = [NSMutableArray array];

    observerCallCount = 0;
}

- (void)testProgressReporting_ExtractFiles_FractionCompleted
{
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFilesProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFilesProgress addObserver:self
                           forKeyPath:observedSelector
                              options:NSKeyValueObservingOptionInitial
                              context:ExtractFilesContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                     error:&extractError];
    
    XCTAssertNil(extractError, @"Error returned by extractFilesTo:overwrite:progress:error:");
    XCTAssertTrue(success, @"Archive failed to extract %@ to %@", testArchiveName, extractURL);
    
    [extractFilesProgress resignCurrent];
    [extractFilesProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(extractFilesProgress.fractionCompleted, 1.00, .0000000001, @"Progress never reported as completed");
    
    NSUInteger expectedProgressUpdates = 4;
    NSArray<NSNumber *> *expectedProgresses = @[@0,
                                                @0.000315,
                                                @0.533568,
                                                @1.0];
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    for (NSUInteger i = 0; i < expectedProgressUpdates; i++) {
        float expectedProgress = expectedProgresses[i].floatValue;
        float actualProgress = self.fractionsCompletedReported[i].floatValue;
        
        XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.00001f, @"Incorrect progress reported at index %ld", (long)i);
    }
}

- (void)testProgressReporting_ExtractFiles_Description
{
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
    archive.progress = extractFilesProgress;
    
    NSString *observedSelector = NSStringFromSelector(@selector(localizedDescription));
    
    [self.descriptionsReported removeAllObjects];
    [extractFilesProgress addObserver:self
                           forKeyPath:observedSelector
                              options:NSKeyValueObservingOptionInitial
                              context:ExtractFilesContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                     error:&extractError];
    
    XCTAssertNil(extractError, @"Error returned by extractFilesTo:overwrite:error:");
    XCTAssertTrue(success, @"Archive failed to extract %@ to %@", testArchiveName, extractURL);
    
    [extractFilesProgress removeObserver:self forKeyPath:observedSelector];
    
    NSArray<NSString *>*expectedDescriptions = @[@"Processing “Test File A.txt”…",
                                                 @"Processing “Test File B.jpg”…",
                                                 @"Processing “Test File C.m4a”…"];
    
    for (NSString *expectedDescription in expectedDescriptions) {
        BOOL descriptionFound = [self.descriptionsReported containsObject:expectedDescription];
        XCTAssertTrue(descriptionFound, @"Expected progress updates to contain '%@', but they didn't", expectedDescription);
    }
}

- (void)testProgressReporting_ExtractFiles_AdditionalDescription
{
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
    archive.progress = extractFilesProgress;
    
    NSString *observedSelector = NSStringFromSelector(@selector(localizedAdditionalDescription));
    
    [extractFilesProgress addObserver:self
                           forKeyPath:observedSelector
                              options:NSKeyValueObservingOptionInitial
                              context:ExtractFilesContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                     error:&extractError];
    
    XCTAssertNil(extractError, @"Error returned by extractFilesTo:overwrite:error:");
    XCTAssertTrue(success, @"Archive failed to extract %@ to %@", testArchiveName, extractURL);
    
    [extractFilesProgress removeObserver:self forKeyPath:observedSelector];
    
    NSArray<NSString *>*expectedAdditionalDescriptions = @[@"Zero KB of 105 KB",
                                                           @"33 bytes of 105 KB",
                                                           @"56 KB of 105 KB",
                                                           @"105 KB of 105 KB"];
    
    for (NSString *expectedDescription in expectedAdditionalDescriptions) {
        BOOL descriptionFound = [self.additionalDescriptionsReported containsObject:expectedDescription];
        XCTAssertTrue(descriptionFound, @"Expected progress updates to contain '%@', but they didn't", expectedDescription);
    }
}

- (void)testProgressReporting_ExtractFiles_FileInfo
{
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
    archive.progress = extractFilesProgress;
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFilesProgress addObserver:self
                           forKeyPath:observedSelector
                              options:NSKeyValueObservingOptionInitial
                              context:ExtractFilesContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                     error:&extractError];
    
    XCTAssertNil(extractError, @"Error returned by extractFilesTo:overwrite:error:");
    XCTAssertTrue(success, @"Archive failed to extract %@ to %@", testArchiveName, extractURL);
    
    [extractFilesProgress removeObserver:self forKeyPath:observedSelector];
    
    NSUInteger expectedFileInfos = 3;
    NSArray<NSString *> *expectedFileNames = @[@"Test File A.txt",
                                               @"Test File B.jpg",
                                               @"Test File C.m4a"];
    
    NSArray<NSString *> *actualFilenames = [self.fileInfosReported valueForKeyPath:NSStringFromSelector(@selector(filename))];
    
    XCTAssertEqual(self.fileInfosReported.count, expectedFileInfos, @"Incorrect number of progress updates");
    XCTAssertTrue([expectedFileNames isEqualToArray:actualFilenames], @"Incorrect filenames returned: %@", actualFilenames);
}

- (void)testProgressReporting_PerformOnFiles {
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *performProgress = [NSProgress progressWithTotalUnitCount:1];
    [performProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [performProgress addObserver:self
                      forKeyPath:observedSelector
                         options:NSKeyValueObservingOptionInitial
                         context:OtherContext];
    
    NSError *performError = nil;
    BOOL success = [archive performOnFilesInArchive:^(UZKFileInfo * _Nonnull fileInfo, BOOL * _Nonnull stop) {}
                                              error:&performError];
    
    XCTAssertNil(performError, @"Error returned by performOnFilesInArchive:error:");
    XCTAssertTrue(success, @"Archive failed to perform operation on files of archive");
    
    [performProgress resignCurrent];
    [performProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(performProgress.fractionCompleted, 1.00, 0.000001, @"Progress never reported as completed");
    
    NSUInteger expectedProgressUpdates = 4;
    NSArray<NSNumber *> *expectedProgresses = @[@0,
                                                @0.333333,
                                                @0.666666,
                                                @1.0];
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    for (NSUInteger i = 0; i < expectedProgressUpdates; i++) {
        float expectedProgress = expectedProgresses[i].floatValue;
        float actualProgress = self.fractionsCompletedReported[i].floatValue;
        
        XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.000001f, @"Incorrect progress reported at index %ld", (long)i);
    }
}

- (void)testProgressReporting_PerformOnData {
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *performProgress = [NSProgress progressWithTotalUnitCount:1];
    [performProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [performProgress addObserver:self
                      forKeyPath:observedSelector
                         options:NSKeyValueObservingOptionInitial
                         context:OtherContext];
    
    NSError *performError = nil;
    BOOL success = [archive performOnDataInArchive:
                    ^(UZKFileInfo * _Nonnull fileInfo, NSData * _Nonnull fileData, BOOL * _Nonnull stop) {}
                                             error:&performError];
    
    XCTAssertNil(performError, @"Error returned by performOnDataInArchive:error:");
    XCTAssertTrue(success, @"Archive failed to perform operation on data of archive");
    
    [performProgress resignCurrent];
    [performProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(performProgress.fractionCompleted, 1.00, 0.000001, @"Progress never reported as completed");
    
    NSUInteger expectedProgressUpdates = 4;
    NSArray<NSNumber *> *expectedProgresses = @[@0,
                                                @0.333333,
                                                @0.666666,
                                                @1.0];
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    for (NSUInteger i = 0; i < expectedProgressUpdates; i++) {
        float expectedProgress = expectedProgresses[i].floatValue;
        float actualProgress = self.fractionsCompletedReported[i].floatValue;
        
        XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.000001f, @"Incorrect progress reported at index %ld", (long)i);
    }
}

- (void)testProgressCancellation_ExtractFiles {
    NSString *testArchiveName = @"Test Archive.zip";
    NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFilesProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFilesProgress addObserver:self
                           forKeyPath:observedSelector
                              options:NSKeyValueObservingOptionInitial
                              context:CancelContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                     error:&extractError];
    
    XCTAssertNotNil(extractError, @"Error not returned by extractFilesTo:overwrite:error:");
    XCTAssertEqual(extractError.code, UZKErrorCodeUserCancelled, @"Incorrect error code returned from user cancellation");
    XCTAssertFalse(success, @"Archive didn't cancel extraction");
    
    [extractFilesProgress resignCurrent];
    [extractFilesProgress removeObserver:self forKeyPath:observedSelector];
    
    
    NSUInteger expectedProgressUpdates = 2;
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    
    NSError *listContentsError = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                      error:&listContentsError];
    
    XCTAssertNil(listContentsError, @"Error listing contents of extraction directory");
    XCTAssertEqual(extractedFiles.count, (unsigned long)1, @"Cancellation didn't occur in as timely a fashion as expected");
}

- (void)testProgressReporting_WriteData {
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteData.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
//    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
//    NSArray<NSString *> *nonZipFiles = [self.nonZipTestFilePaths sortedArrayUsingDescriptors:@[sort]];
//    NSString *firstFile = nonZipFiles.firstObject;
    NSData *firstFileData = [NSData dataWithContentsOfURL:self.testFileURLs[@"Aces.zip"]];
    
    NSProgress *performProgress = [NSProgress progressWithTotalUnitCount:1];
    [performProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [performProgress addObserver:self
                      forKeyPath:observedSelector
                         options:NSKeyValueObservingOptionInitial
                         context:OtherContext];
    
    NSError *writeError = nil;
    BOOL success = [archive writeData:firstFileData
                             filePath:@"First File.idk"
                                error:&writeError];
    
    XCTAssertNil(writeError, @"Error returned by writeData:filePath:error:");
    XCTAssertTrue(success, @"Failed to write data to archive");
    
    [performProgress resignCurrent];
    [performProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(performProgress.fractionCompleted, 1.00, 0.000001, @"Progress never reported as completed");
    
    NSUInteger expectedProgressUpdates = 4;
    NSArray<NSNumber *> *expectedProgresses = @[@0,
                                                @0.402872,
                                                @0.805744,
                                                @1.0];
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    for (NSUInteger i = 0; i < expectedProgressUpdates; i++) {
        float expectedProgress = expectedProgresses[i].floatValue;
        float actualProgress = self.fractionsCompletedReported[i].floatValue;
        
        XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.000001f, @"Incorrect progress reported at index %ld", (long)i);
    }
}


#pragma mark - Mac-only tests


#if !TARGET_OS_IPHONE
- (void)testProgressReporting_ExtractData {
    NSURL *largeArchiveURL = [self largeArchive];

    UZKArchive *archive = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    NSString *firstFile = [[archive listFilenames:nil] firstObject];
    
    NSProgress *extractFileProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFileProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFileProgress addObserver:self
                          forKeyPath:observedSelector
                             options:NSKeyValueObservingOptionInitial
                             context:OtherContext];
    
    NSError *extractError = nil;
    NSData *data = [archive extractDataFromFile:firstFile error:&extractError];
    
    XCTAssertNil(extractError, @"Error returned by extractDataFromFile:error:");
    XCTAssertNotNil(data, @"Archive failed to extract large archive");
    
    [extractFileProgress resignCurrent];
    [extractFileProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(extractFileProgress.fractionCompleted, 1.00, 0.000001, @"Progress never reported as completed");

    NSUInteger expectedProgressUpdates = 78;
    NSDictionary<NSNumber *, NSNumber *> *expectedProgresses = @{
                                                                 @00: @0,
                                                                 @20: @0.262144,
                                                                 @35: @0.458752,
                                                                 @60: @0.786432,
                                                                 @76: @0.996147,
                                                                 @77: @1,
                                                                 };
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    [expectedProgresses enumerateKeysAndObjectsUsingBlock:
     ^(NSNumber *key, NSNumber *obj, BOOL *stop) {
         float expectedProgress = obj.floatValue;
         float actualProgress = self.fractionsCompletedReported[key.intValue].floatValue;
         
         XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.000001f, @"Incorrect progress reported at index %d", key.intValue);
     }];
}

- (void)testProgressReporting_ExtractBufferedData {
    NSURL *largeArchiveURL = [self largeArchive];

    UZKArchive *archive = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    NSString *firstFile = [[archive listFilenames:nil] firstObject];
    
    NSProgress *extractFileProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFileProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFileProgress addObserver:self
                          forKeyPath:observedSelector
                             options:NSKeyValueObservingOptionInitial
                             context:OtherContext];
    
    NSError *extractError = nil;
    BOOL success = [archive extractBufferedDataFromFile:firstFile
                                                  error:&extractError
                                                 action:^(NSData * _Nonnull dataChunk, CGFloat percentDecompressed) {}];
    
    XCTAssertNil(extractError, @"Error returned by extractDataFromFile:error:");
    XCTAssertTrue(success, @"Archive failed to extract large archive into buffer");
    
    [extractFileProgress resignCurrent];
    [extractFileProgress removeObserver:self forKeyPath:observedSelector];
    
    XCTAssertEqualWithAccuracy(extractFileProgress.fractionCompleted, 1.00, 0.000001, @"Progress never reported as completed");

    NSUInteger expectedProgressUpdates = 78;
    NSDictionary<NSNumber *, NSNumber *> *expectedProgresses = @{
                                                                 @00: @0,
                                                                 @20: @0.262144,
                                                                 @35: @0.458752,
                                                                 @60: @0.786432,
                                                                 @76: @0.996147,
                                                                 @77: @1,
                                                                 };
    
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    [expectedProgresses enumerateKeysAndObjectsUsingBlock:
     ^(NSNumber *key, NSNumber *obj, BOOL *stop) {
         float expectedProgress = obj.floatValue;
         float actualProgress = self.fractionsCompletedReported[key.intValue].floatValue;
         
         XCTAssertEqualWithAccuracy(actualProgress, expectedProgress, 0.000001f, @"Incorrect progress reported at index %d", key.intValue);
     }];
}

- (void)testProgressCancellation_ExtractData {
    NSURL *largeArchiveURL = [self largeArchive];

    UZKArchive *archive = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    NSString *firstFile = [[archive listFilenames:nil] firstObject];
    
    NSProgress *extractFileProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFileProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFileProgress addObserver:self
                          forKeyPath:observedSelector
                             options:NSKeyValueObservingOptionInitial
                             context:CancelContext];
    
    NSError *extractError = nil;
    NSData *data = [archive extractDataFromFile:firstFile error:&extractError];
    
    XCTAssertNotNil(extractError, @"No error returned by cancelled extractDataFromFile:error:");
    XCTAssertEqual(extractError.code, UZKErrorCodeUserCancelled, @"Incorrect error code returned from user cancellation");
    XCTAssertNil(data, @"extractData didn't return nil when cancelled");
    
    [extractFileProgress resignCurrent];
    [extractFileProgress removeObserver:self forKeyPath:observedSelector];
    
    NSUInteger expectedProgressUpdates = 2;
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
}

- (void)testProgressCancellation_ExtractBufferedData {
    NSURL *largeArchiveURL = [self largeArchive];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    NSString *firstFile = [[archive listFilenames:nil] firstObject];
    
    NSProgress *extractFileProgress = [NSProgress progressWithTotalUnitCount:1];
    [extractFileProgress becomeCurrentWithPendingUnitCount:1];
    
    NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
    
    [extractFileProgress addObserver:self
                          forKeyPath:observedSelector
                             options:NSKeyValueObservingOptionInitial
                             context:CancelContext];
    
    __block NSUInteger blockCallCount = 0;
    
    NSError *extractError = nil;
    BOOL success = [archive extractBufferedDataFromFile:firstFile
                                                  error:&extractError
                                                 action:^(NSData * _Nonnull dataChunk, CGFloat percentDecompressed) {
                                                     blockCallCount++;
                                                 }];
    
    XCTAssertNotNil(extractError, @"No error returned by cancelled extractDataFromFile:error:");
    XCTAssertEqual(extractError.code, UZKErrorCodeUserCancelled, @"Incorrect error code returned from user cancellation");
    XCTAssertFalse(success, @"extractBufferedData didn't return false when cancelled");
    
    [extractFileProgress resignCurrent];
    [extractFileProgress removeObserver:self forKeyPath:observedSelector];
    
    NSUInteger expectedProgressUpdates = 2;
    XCTAssertEqual(self.fractionsCompletedReported.count, expectedProgressUpdates, @"Incorrect number of progress updates");
    XCTAssertEqual(blockCallCount, (NSUInteger)1, @"Action block called incorrect number of times after cancellation");
}
#endif


#pragma mark - Private methods


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    observerCallCount++;
    
    NSProgress *progress;
    
    if ([object isKindOfClass:[NSProgress class]]) {
        progress = object;
        [self.fractionsCompletedReported addObject:@(progress.fractionCompleted)];
    } else {
        return;
    }
    
    if (context == ExtractFilesContext) {
        [self.descriptionsReported addObject:progress.localizedDescription];
        [self.additionalDescriptionsReported addObject:progress.localizedAdditionalDescription];

        UZKFileInfo *fileInfo = progress.userInfo[UZKProgressInfoKeyFileInfoExtracting];
        if (fileInfo) [self.fileInfosReported addObject:fileInfo];
    }
    
    if (context == CancelContext && observerCallCount == 2) {
        [progress cancel];
    }
}

@end
