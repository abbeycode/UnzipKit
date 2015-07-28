//
//  CommentsTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
@import UnzipKit;

@interface CommentsTests : UZKArchiveTestCase
@end

@implementation CommentsTests


- (void)testGlobalComment_Read
{
    UZKArchive *commentArchive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Comments Archive.zip"]];
    
    NSString *comment = commentArchive.comment;
    XCTAssertNotNil(comment, @"No comment returned from archive");
    XCTAssertGreaterThan(comment.length, 0, @"Comment has no content");
}

- (void)testGlobalComment_ReadWhenNonePresent
{
    UZKArchive *commentFreeArchive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test Archive.zip"]];
    
    NSString *comment = commentFreeArchive.comment;
    XCTAssertNil(comment, @"Comment returned from archive that should have none");
}

- (void)testGlobalComment_Write
{
    UZKArchive *commentArchive = [UZKArchive zipArchiveAtURL:self.testFileURLs[@"Test Archive.zip"]];
    
    NSString *originalComment = commentArchive.comment;
    XCTAssertNil(originalComment, @"Comment returned from archive that should have none");
    
    NSString *expectedComment = @"Fünky unicode stuff";
    commentArchive.comment = expectedComment;
    
    UZKArchive *newArchiveInstance = [UZKArchive zipArchiveAtURL:commentArchive.fileURL];

    NSString *updatedComment = newArchiveInstance.comment.decomposedStringWithCanonicalMapping;
    XCTAssertEqualObjects(updatedComment, expectedComment.decomposedStringWithCanonicalMapping,
                          @"Wrong comment read from archive");
}


@end
