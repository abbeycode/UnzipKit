//
//  TestKeppPrmissions.m
//  UnzipKitTests
//
//  Created by MartinLau on 2019/6/13.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "zip.h"
#import "UnzipKit.h"


@interface TestKeppPrmissions : UZKArchiveTestCase

@end

@implementation TestKeppPrmissions

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
    
    NSError *extractError = nil;
    BOOL success = [archive extractFilesTo:extractDirectory overwrite:NO error:&extractError];
    XCTAssert(success, @"extract error %@", extractError);
    // $ ls -l "extractURL.path" look up prmissions
}

- (void)testWriteFile {
    
    NSURL *testArchiveURL = [self.tempDirectory URLByAppendingPathComponent:@"WriteFile.zip"];
    [[NSFileManager defaultManager] removeItemAtURL:testArchiveURL error:nil];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithPath:testArchiveURL.path error:nil];
    
    NSArray *array = [[NSFileManager defaultManager] subpathsAtPath:[testArchiveURL URLByDeletingLastPathComponent].path];
    [array enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![[obj pathExtension] hasSuffix:@"zip"]) {
            
            NSError *error = nil;
            NSString *itemPath = [[testArchiveURL URLByDeletingLastPathComponent].path stringByAppendingPathComponent:obj];
            
            BOOL success = [archive writeFile:itemPath
                                      zipPath:obj
                            compressionMethod:UZKCompressionMethodDefault
                                     password:nil
                                    overwrite:NO
                                        error:&error];
            XCTAssert(success, "write error %@", error);
        }
    }];
    NSLog(@"%@", archive.filename);
}

@end
