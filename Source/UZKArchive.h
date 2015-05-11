//
//  UZKArchive.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>

#import "UZKFileInfo.h"


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
    
    /**
     *  Error opening a file in the archive for writing
     */
    UZKErrorCodeFileOpenForWrite = 108,
    
    /**
     *  Error writing a file in the archive
     */
    UZKErrorCodeFileWrite = 109,
    
    /**
     *  Error closing the file in the archive
     */
    UZKErrorCodeFileCloseWriting = 110,
    
    /**
     *  Error deleting a file in the archive
     */
    UZKErrorCodeDeleteFile = 111,
    
    /**
     *  Tried to read before all writes have completed, or vise-versa
     */
    UZKErrorCodeMixedModeAccess = 112,
    
    /**
     *  Error reading the global comment of the archive
     */
    UZKErrorCodeReadComment = 113,
};

/**
 *  The URL of the archive
 */
@property(weak, nonatomic, readonly) NSURL *fileURL;

/**
 *  The filename of the archive
 */
@property(weak, nonatomic, readonly) NSString *filename;

/**
 *  The password of the archive
 */
@property(strong) NSString *password;

/**
 *  The global comment inside the archive
 *
 *  Comments are written in UTF-8, and read in UTF-8 and Windows/CP-1252, falling back to defaultCStringEncoding
 */
@property(atomic) NSString *comment;


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



#pragma mark - Read Methods


/**
 *  Determines whether a file is a Zip file by reading the header
 *
 *  @param filePath Path to the file being checked
 *
 *  @return YES if the file exists and contains a signature indicating it is a Zip file
 */
+ (BOOL)pathIsAZip:(NSString *)filePath;

/**
 *  Determines whether a file is a Zip file by reading the header
 *
 *  @param fileURL URL of the file being checked
 *
 *  @return YES if the file exists and contains a signature indicating it is a Zip file
 */
+ (BOOL)urlIsAZip:(NSURL *)fileURL;


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



#pragma mark - Write Methods


/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
            error:(NSError **)error;

/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error;

/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error;

/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param method   The full path to the target file in the archive
 *  @param password Override the password associated with the archive (not recommended)
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(NSString *)password
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error;

/**
 *  Writes the data to the zip file, overwriting only if specified with the overwrite flag. Overwriting
 *  presents a tradeoff: the whole archive needs to be copied (minus the file to be overwritten) before
 *  the write begins. For a large archive, this can be slow. On the other hand, when not overwriting,
 *  the size of the archive will grow each time the file is written.
 *
 *  @param data      Data to write into the archive
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The full path to the target file in the archive
 *  @param password  Override the password associated with the archive (not recommended)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param progress  Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(NSString *)password
        overwrite:(BOOL)overwrite
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param method   The full path to the target file in the archive
 *  @param password Override the password associated with the archive (not recommended)
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
               password:(NSString *)password
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name, only if
 *  specified with the overwrite flag. Overwriting presents a tradeoff: the whole archive needs to be
 *  copied (minus the file to be overwritten) before the write begins. For a large archive, this can
 *  be slow. On the other hand, when not overwriting, the size of the archive will grow each time
 *  the file is written.
 *
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The full path to the target file in the archive
 *  @param password  Override the password associated with the archive (not recommended)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *  @param action    Contains your code to loop through the source bytes and write them to the
 *                   archive. Each time a chunk of data is ready to be written, call writeData,
 *                   passing in a pointer to the bytes and their length. Return YES if successful,
 *                   or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
               password:(NSString *)password
              overwrite:(BOOL)overwrite
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Removes the given file from the archive
 *
 *  @param filePath The file in the archive you wish to delete
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if the file was successfully deleted, NO otherwise
 */
- (BOOL)deleteFile:(NSString *)filePath error:(NSError **)error;


@end
