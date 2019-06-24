//
//  UZKFileInfo.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>



@class UZKArchive;

/**
 *   Defines the various compression levels that can be applied to a file
 */
typedef NS_ENUM(NSInteger, UZKCompressionMethod) {
    /**
     *  Default level
     */
    UZKCompressionMethodDefault= -1,
    
    /**
     *  No compression
     */
    UZKCompressionMethodNone= 0,
    
    /**
     *  Fastest compression
     */
    UZKCompressionMethodFastest= 1,
    
    /**
     *  Best (slowest) compression
     */
    UZKCompressionMethodBest= 9
};


@interface UZKFileInfo : NSObject

/**
 *  The name of the file
 */
@property (readonly, strong) NSString *filename;

/**
 *  The timestamp of the file
 */
@property (readonly, nonatomic) NSDate *timestamp;

/**
 *  The CRC checksum of the file
 */
@property (readonly) NSUInteger CRC;

/**
 *  Size of the uncompressed file
 */
@property (readonly) unsigned long long int uncompressedSize;

/**
 *  Size of the compressed file
 */
@property (readonly) unsigned long long int compressedSize;

/**
 *  YES if the file will be continued of the next volume
 */
@property (readonly) BOOL isEncryptedWithPassword;

/**
 *  YES if the file is a directory
 */
@property (readonly) BOOL isDirectory;

/**
 *  The type of compression
 */
@property (readonly) UZKCompressionMethod compressionMethod;

/**
 @brief posixPermissions (posixPermissions of the file,The value from the file attributes - NSFilePosixPermissions)
 */
@property (nonatomic, readonly) NSNumber *posixPermissions;

@end
