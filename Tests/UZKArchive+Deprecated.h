//
//  UZKArchive+Deprecated.h
//  UnzipKit
//
//  Created by Dov Frankel on 8/12/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UZKArchive.h"

@interface UZKArchive (Deprecated)

NS_ASSUME_NONNULL_BEGIN

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                      error:(NSError **)error;

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                  overwrite:(BOOL)overwrite
                      error:(NSError **)error;

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
           posixPermissions:(short)permissions
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                  overwrite:(BOOL)overwrite
                      error:(NSError **)error;

- (BOOL)deprecatedWriteIntoBuffer:(NSString *)filePath
                         fileDate:(nullable NSDate *)fileDate
                 posixPermissions:(short)permissions
                compressionMethod:(UZKCompressionMethod)method
                        overwrite:(BOOL)overwrite
                              CRC:(unsigned long)preCRC
                         password:(nullable NSString *)password
                            error:(NSError **)error
                            block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

NS_ASSUME_NONNULL_END

@end
