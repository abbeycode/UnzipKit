//
//  UZKFileInfo.h
//  UnzipKit
//
//

@import Foundation;

#import "unzip.h"

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
@property (readonly, strong) NSDate *timestamp;

/**
 *  The CRC checksum of the file
 */
@property (readonly) NSUInteger CRC;

/**
 *  Size of the uncompressed file
 */
@property (readonly) NSUInteger uncompressedSize;

/**
 *  Size of the compressed file
 */
@property (readonly) NSUInteger compressedSize;

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
 *  Returns a UZKFileInfo instance for the given extended header data
 *
 *  @param fileInfo The header data for a Zip file
 *  @param filename The archive that contains the file
 *
 *  @return an instance of UZKFileInfo
 */
+ (instancetype) fileInfo:(unz_file_info *)fileInfo filename:(NSString *)filename;


@end
