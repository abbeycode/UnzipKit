//
//  UZKArchive.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>

@interface UZKArchive : NSObject

/**
 *  The URL of the archive
 */
@property(weak, readonly) NSURL *fileURL;

/**
 *  The filename of the archive
 */
@property(weak, readonly) NSString *filename;

/**
 *  The password of the archive
 */
@property(strong, strong) NSString *password;


/**
 *  Creates and returns an archive at the given path
 *
 *  @param filePath A path to the archive file
 */
+ (instancetype)zipArchiveAtPath:(NSString *)filePath;

/**
 *  Creates and returns an archive at the given URL
 *
 *  @param fileURL The URL of the archive file
 */
+ (instancetype)zipArchiveAtURL:(NSURL *)fileURL;

/**
 *  Creates and returns an archive at the given path, with a given password
 *
 *  @param filePath A path to the archive file
 *  @param password The passowrd of the given archive
 */
+ (instancetype)zipArchiveAtPath:(NSString *)filePath password:(NSString *)password;

/**
 *  Creates and returns an archive at the given URL, with a given password
 *
 *  @param fileURL  The URL of the archive file
 *  @param password The passowrd of the given archive
 */
+ (instancetype)zipArchiveAtURL:(NSURL *)fileURL password:(NSString *)password;

@end
