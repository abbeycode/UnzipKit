//
//  UZKFileInfo.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>

#import "unzip.h"

@class UZKArchive;

/**
 *   Defines the various compression levels that can be applied to a file
 */
typedef NS_ENUM(NSInteger, UZKCompressionLevel) {
    /**
     *  Default level
     */
    UZKCompressionLevelDefault= -1,
    
    /**
     *  No compression
     */
    UZKCompressionLevelNone= 0,
    
    /**
     *  Fastest compression
     */
    UZKCompressionLevelFastest= 1,
    
    /**
     *  Best (slowest) compression
     */
    UZKCompressionLevelBest= 9
};


@interface UZKFileInfo : NSObject

/**
 *  The name of the file's archive
 */
@property (readonly, strong) NSString *archiveName;

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
@property (readonly) long long uncompressedSize;

/**
 *  Size of the compressed file
 */
@property (readonly) long long compressedSize;

/**
 *  YES if the file will be continued of the next volume
 */
@property (readonly) BOOL isEncryptedWithPassword;

/**
 *  The type of compression
 */
@property (readonly) UZKCompressionLevel compressionLevel;


/**
 *  Returns a UZKFileInfo instance for the given extended header data
 *
 *  @param fileHeader The header data for a Zip file
 *  @param filename   The archive that contains the file
 *
 *  @return an instance of UZKFileInfo
 */
+ (instancetype) fileInfo:(unz_file_info *)fileInfo filename:(NSString *)filename;


@end
