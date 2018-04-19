//
//  CommentsTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"

@interface CommentsTests : UZKArchiveTestCase
@end

@implementation CommentsTests


- (void)testGlobalComment_Read
{
    UZKArchive *commentArchive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Comments Archive.zip"] error:nil];
    
    NSString *comment = commentArchive.comment;
    XCTAssertNotNil(comment, @"No comment returned from archive");
    XCTAssertGreaterThan(comment.length, (NSUInteger)0, @"Comment has no content");
}

- (void)testGlobalComment_ReadWhenNonePresent
{
    UZKArchive *commentFreeArchive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test Archive.zip"] error:nil];
    
    NSString *comment = commentFreeArchive.comment;
    XCTAssertNil(comment, @"Comment returned from archive that should have none");
}

- (void)testGlobalComment_Write
{
    UZKArchive *commentArchive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test Archive.zip"] error:nil];
    
    NSString *originalComment = commentArchive.comment;
    XCTAssertNil(originalComment, @"Comment returned from archive that should have none");
    
    NSString *expectedComment = @"Fünky unicode stuff";
    commentArchive.comment = expectedComment;
    
    UZKArchive *newArchiveInstance = [[UZKArchive alloc] initWithURL:commentArchive.fileURL error:nil];

    NSString *updatedComment = newArchiveInstance.comment.decomposedStringWithCanonicalMapping;
    XCTAssertEqualObjects(updatedComment, expectedComment.decomposedStringWithCanonicalMapping,
                          @"Wrong comment read from archive");
}


@end
