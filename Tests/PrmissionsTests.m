//
//  PrmissionsTests.m
//  UnzipKitTests
//
//  Created by MartinLau on 2019/6/24.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

#import "UnzipKit.h"
#import "UZKArchiveTestCase.h"

@interface PrmissionsTests : UZKArchiveTestCase

@end

@implementation PrmissionsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
}

- (void)testExtract {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test Permissions Archive.zip"] error:nil];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:archive.filename.stringByDeletingPathExtension];
    
    // show zip file posixPermissions value
    NSArray *archiveItems = [archive listFileInfo:nil];
    for (UZKFileInfo *item in archiveItems) {
        
        if (![item isDirectory] && ![item isResourceFork]) {
        
            NSLog(@"zip file %@ : posixPermissions_%ld", item.filename, [item.posixPermissions unsignedLongValue] - 32768);
        }
    }
    
    printf("=====================");
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractDirectory overwrite:NO error:&extractError];
    XCTAssert(success, @"extract error %@", extractError);
    
    // show local file posixPermissions value
    NSArray *localItems = [[NSFileManager defaultManager] subpathsAtPath:extractDirectory];
    [localItems enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[extractDirectory stringByAppendingPathComponent:obj] isDirectory:&isDir] && !isDir) {
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[extractDirectory stringByAppendingPathComponent:obj] error:nil];
            NSLog(@"local file %@: posixPermissions_ %lu", obj , [attributes filePosixPermissions]);
        }
    }];
}

@end
