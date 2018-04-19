//
//  ErrorHandlingTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface ErrorHandlingTests : UZKArchiveTestCase
@end

@implementation ErrorHandlingTests


- (void)testNestedError
{
    NSURL *testArchiveURL = self.testFileURLs[@"Test Archive.zip"];
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSError *error = nil;
    NSData *extractedData = [archive extractDataFromFile:@"file-doesnt-exist.txt"
                                                   error:&error];
    
    XCTAssertNil(extractedData, @"Data returned when there was an error");
    XCTAssertNotNil(error, @"No error returned when extracting data for nonexistant archived file");
    XCTAssertEqual(error.code, UZKErrorCodeFileNotFoundInArchive, @"Unexpected error code");
    
    NSString *recoverySuggestion = error.localizedRecoverySuggestion;
    XCTAssertNotEqual([recoverySuggestion rangeOfString:@"during buffered read"].location, NSNotFound,
                      @"Incorrect localized recovery suggestion returned in error: '%@'", recoverySuggestion);
    
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(underlyingError, @"No inner error returned when file doesn't exist");
    XCTAssertEqual(underlyingError.code, UZKErrorCodeFileNotFoundInArchive, @"Unexpected underlying error code");
    
    NSString *underlyingRecoverySuggestion = underlyingError.localizedRecoverySuggestion;
    XCTAssertNotEqual([underlyingRecoverySuggestion rangeOfString:@"No file position found"].location, NSNotFound,
                      @"Incorrect localized recovery suggestion returned in inner error: '%@'", underlyingRecoverySuggestion);
}


@end
