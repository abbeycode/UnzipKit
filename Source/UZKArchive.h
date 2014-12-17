//
//  UZKArchive.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>


@interface UZKArchive : NSObject

extern NSString *UZKErrorDomain;

/**
 *  Defines the various error codes that the listing and extraction methods return.
 *  These are returned in NSError's [code]([NSError code]) field.
 */
typedef NS_ENUM(NSInteger, UZKErrorCode) {
    
    /**
     *  An error from zlib reading or writing the file (UNZ_ERRNO/ZIP_ERRNO)
     */
    UZKErrorCodeZLibError = -1,
    
    /**
     *  An error with a parameter, usually the file name (UNZ_PARAMERROR/ZIP_PARAMERROR)
     */
    UZKErrorCodeParameterError = -102,
    
    /**
     *  The Zip file appears to be corrupted, or invalid (UNZ_BADZIPFILE/ZIP_BADZIPFILE)
     */
    UZKErrorCodeBadZipFile = -103,
    
    /**
     *  An error internal to MiniZip (UNZ_INTERNALERROR/ZIP_INTERNALERROR)
     */
    UZKErrorCodeInternalError = -104,
    
    /**
     *  The decompressed file's CRC doesn't match the original file's CRC (UNZ_CRCERROR)
     */
    UZKErrorCodeCRCError = -105,
    
    /**
     *  Failure to find/open the archive
     */
    UZKErrorCodeArchiveNotFound = 101,
    
    /**
     *  Error reading or advancing through the archive
     */
    UZKErrorCodeFileNavigationError = 102,
};

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


/**
 *  Lists the names of the files in the archive
 *
 *  @param error Contains an NSError object when there was an error reading the archive
 *
 *  @return Returns a list of NSString containing the paths within the archive's contents, or nil if an error was encountered
 */
- (NSArray *)listFilenames:(NSError **)error;

/**
 *  Lists the various attributes of each file in the archive
 *
 *  @param error Contains an NSError object when there was an error reading the archive
 *
 *  @return Returns a list of UZKFileInfo objects, which contain metadata about the archive's files, or nil if an error was encountered
 */
- (NSArray *)listFileInfo:(NSError **)error;


@end
