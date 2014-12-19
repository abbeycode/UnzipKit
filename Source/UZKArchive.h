//
//  UZKArchive.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>

@class UZKFileInfo;


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
    
    /**
     *  Error finding a file in the archive
     */
    UZKErrorCodeFileNotFoundInArchive = 103,
    
    /**
     *  Error writing an extracted file to disk
     */
    UZKErrorCodeOutputError = 104,
    
    /**
     *  The destination directory is a file
     */
    UZKErrorCodeOutputErrorPathIsAFile = 105,
    
    /**
     *  The destination directory is a file
     */
    UZKErrorCodeInvalidPassword = 106,
    
    /**
     *  Error reading a file in the archive
     */
    UZKErrorCodeFileRead = 107,
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

/**
 *  Writes all files in the archive to the given path
 *
 *  @param destinationDirectory  The destination path of the unarchived files
 *  @param overwrite             YES to overwrite files in the destination directory, NO otherwise
 *  @param progress              Called every so often to report the progress of the extraction
 *
 *       - *currentFile*                The info about the file that's being extracted
 *       - *percentArchiveDecompressed* The percentage of the archive that has been decompressed
 *
 *  @param error     Contains an NSError object when there was an error reading the archive
 *
 *  @return YES on successful extraction, NO if an error was encountered
 */
- (BOOL)extractFilesTo:(NSString *)destinationDirectory
             overwrite:(BOOL)overwrite
              progress:(void (^)(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed))progress
                 error:(NSError **)error;

/**
 *  Unarchive a single file from the archive into memory
 *
 *  @param fileInfo The info of the file within the archive to be expanded. Only the filename property is used
 *  @param progress Called every so often to report the progress of the extraction
 *
 *       - *percentDecompressed* The percentage of the archive that has been decompressed
 *
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (NSData *)extractData:(UZKFileInfo *)fileInfo
               progress:(void (^)(CGFloat percentDecompressed))progress
                  error:(NSError **)error;

/**
 *  Unarchive a single file from the archive into memory
 *
 *  @param filePath The path of the file within the archive to be expanded
 *  @param progress Called every so often to report the progress of the extraction
 *
 *       - *percentDecompressed* The percentage of the file that has been decompressed
 *
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (NSData *)extractDataFromFile:(NSString *)filePath
                       progress:(void (^)(CGFloat percentDecompressed))progress
                          error:(NSError **)error;

/**
 *  Loops through each file in the archive into memory, allowing you to perform an action using its info
 *
 *  @param action The action to perform using the data
 *
 *       - *fileInfo* The metadata of the file within the archive
 *       - *stop*     Set to YES to stop reading the archive
 *
 *  @param error  Contains an error if any was returned
 *
 *  @return YES if no errors were encountered, NO otherwise
 */
- (BOOL)performOnFilesInArchive:(void(^)(UZKFileInfo *fileInfo, BOOL *stop))action
                          error:(NSError **)error;

/**
 *  Extracts each file in the archive into memory, allowing you to perform an action on it
 *
 *  @param action The action to perform using the data
 *
 *       - *fileInfo* The metadata of the file within the archive
 *       - *fileData* The full data of the file in the archive
 *       - *stop*     Set to YES to stop reading the archive
 *
 *  @param error  Contains an error if any was returned
 *
 *  @return YES if no errors were encountered, NO otherwise
 */
- (BOOL)performOnDataInArchive:(void(^)(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop))action
                         error:(NSError **)error;

/**
 *  Unarchive a single file from the archive into memory
 *
 *  @param filePath   The path of the file within the archive to be expanded
 *  @param error      Contains an NSError object when there was an error reading the archive
 *  @param action     The block to run for each chunk of data, each of size <= bufferSize
 *
 *       - *dataChunk*           The data read from the archived file. Read bytes and length to write the data
 *       - *percentDecompressed* The percentage of the file that has been decompressed
 *
 *  @return YES if all data was read successfully, NO if an error was encountered
 */
- (BOOL)extractBufferedDataFromFile:(NSString *)filePath
                              error:(NSError **)error
                             action:(void(^)(NSData *dataChunk, CGFloat percentDecompressed))action;

/**
 *  YES if archive protected with a password, NO otherwise
 */
- (BOOL)isPasswordProtected;

/**
 *  Tests whether the provided password unlocks the archive
 *
 *  @return YES if correct password or archive is not password protected, NO if password is wrong
 */
- (BOOL)validatePassword;


@end
