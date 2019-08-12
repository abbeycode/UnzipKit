//
//  UZKArchive+Deprecated.m
//  UnzipKit
//
//  Created by Dov Frankel on 8/12/19.
//  Copyright © 2019 Abbey Code. All rights reserved.
//

#import "UZKArchive+Deprecated.h"
#import "UZKArchive.h"

@implementation UZKArchive (Deprecated)

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                      error:(NSError *__autoreleasing *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
         compressionMethod:method
                  password:password
                     error:error];
#pragma clang diagnostic pop
}

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                  overwrite:(BOOL)overwrite
                      error:(NSError *__autoreleasing *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
         compressionMethod:method
                  password:password
                 overwrite:overwrite
                     error:error];
#pragma clang diagnostic pop
}

- (BOOL)deprecatedWriteData:(NSData *)data
                   filePath:(NSString *)filePath
                   fileDate:(nullable NSDate *)fileDate
           posixPermissions:(short)permissions
          compressionMethod:(UZKCompressionMethod)method
                   password:(nullable NSString *)password
                  overwrite:(BOOL)overwrite
                      error:(NSError *__autoreleasing *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
          posixPermissions:permissions
         compressionMethod:method
                  password:password
                 overwrite:overwrite
                     error:error];
#pragma clang diagnostic pop
}

- (BOOL)deprecatedWriteIntoBuffer:(NSString *)filePath
                         fileDate:(nullable NSDate *)fileDate
                 posixPermissions:(short)permissions
                compressionMethod:(UZKCompressionMethod)method
                        overwrite:(BOOL)overwrite
                              CRC:(unsigned long)preCRC
                         password:(nullable NSString *)password
                            error:(NSError *__autoreleasing *)error
                            block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self writeIntoBuffer:filePath
                        fileDate:fileDate
                posixPermissions:permissions
               compressionMethod:method
                       overwrite:overwrite
                             CRC:preCRC
                        password:password
                           error:error
                           block:action];
#pragma clang diagnostic pop
}
@end
