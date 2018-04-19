//
//  MultithreadingTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
#import "UnzipKit.h"
#import "UnzipKitMacros.h"

@interface MultithreadingTests : UZKArchiveTestCase
@end

@implementation MultithreadingTests


#if !TARGET_OS_IPHONE
- (void)testMultithreading {
    UZKArchive *largeArchiveA = [[UZKArchive alloc] initWithURL:[self largeArchive] error:nil];
    UZKArchive *largeArchiveB = [[UZKArchive alloc] initWithURL:[self largeArchive] error:nil];
    UZKArchive *largeArchiveC = [[UZKArchive alloc] initWithURL:[self largeArchive] error:nil];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveA performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration A");
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveB performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration B");
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveC performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration C");
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
            UZKLogError("Error while waiting for expectations: %@", error);
        }
    }];
}

- (void)testMultithreading_SingleFile {
    NSURL *largeArchiveURL = [self largeArchive];
    
    UZKArchive *largeArchiveA = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    UZKArchive *largeArchiveB = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    UZKArchive *largeArchiveC = [[UZKArchive alloc] initWithURL:largeArchiveURL error:nil];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveA performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration A");
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveB performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration B");
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchiveC performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration C");
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
            UZKLogError("Error while waiting for expectations: %@", error);
        }
    }];
}

- (void)testMultithreading_SingleArchiveObject {
    
    UZKArchive *largeArchive = [[UZKArchive alloc] initWithURL:[self largeArchive] error:nil];
    
    XCTestExpectation *expectationA = [self expectationWithDescription:@"A finished"];
    XCTestExpectation *expectationB = [self expectationWithDescription:@"B finished"];
    XCTestExpectation *expectationC = [self expectationWithDescription:@"C finished"];
    
    NSBlockOperation *enumerateA = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration A");
        [expectationA fulfill];
    }];
    
    NSBlockOperation *enumerateB = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration B");
        [expectationB fulfill];
    }];
    
    NSBlockOperation *enumerateC = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        [largeArchive performOnDataInArchive:^(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
            UZKLogInfo("File name: %@", fileInfo.filename);
        } error:&error];
        
        XCTAssertNil(error, @"Failed enumeration C");
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
            UZKLogError("Error while waiting for expectations: %@", error);
        }
    }];
}
#endif


@end
