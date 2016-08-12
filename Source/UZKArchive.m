//
//  UZKArchive.m
//  UnzipKit
//
//

#import "UZKArchive.h"

#import "zip.h"

#import "UZKFileInfo.h"
#import "UZKFileInfo_Private.h"
#import "NSURL+UnzipKitExtensions.h"


NSString *UZKErrorDomain = @"UZKErrorDomain";

#define FILE_IN_ZIP_MAX_NAME_LENGTH (512)


typedef NS_ENUM(NSUInteger, UZKFileMode) {
    UZKFileModeUnassigned = -1,
    UZKFileModeUnzip = 0,
    UZKFileModeCreate,
    UZKFileModeAppend
};

static NSBundle *_resources = nil;



@interface UZKArchive ()

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFile:(NSURL *)fileURL password:(NSString*)password error:(NSError * __autoreleasing*)error
#if (TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_7_0) || MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_9
NS_DESIGNATED_INITIALIZER
#endif
;

@property (strong) NSData *fileBookmark;
@property (strong) NSURL *fallbackURL;

@property (assign) NSInteger openCount;

@property (assign) UZKFileMode mode;
@property (assign) zipFile zipFile;
@property (assign) unzFile unzFile;
@property (strong) NSDictionary *archiveContents;

@property (strong) NSObject *threadLock;

@property (assign) BOOL commentRetrieved;

@end


@implementation UZKArchive

@synthesize comment = _comment;


#pragma mark - Deprecated Convenience Methods


+ (UZKArchive *)zipArchiveAtPath:(NSString *)filePath
{
    return [[UZKArchive alloc] initWithPath:filePath error:nil];
}

+ (UZKArchive *)zipArchiveAtURL:(NSURL *)fileURL
{
    return [[UZKArchive alloc] initWithURL:fileURL error:nil];
}

+ (UZKArchive *)zipArchiveAtPath:(NSString *)filePath password:(NSString *)password
{
    return [[UZKArchive alloc] initWithPath:filePath password:password error:nil];
}

+ (UZKArchive *)zipArchiveAtURL:(NSURL *)fileURL password:(NSString *)password
{
    return [[UZKArchive alloc] initWithURL:fileURL password:password error:nil];
}



#pragma mark - Initializers

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *resourcesURL = [mainBundle URLForResource:@"UnzipKitResources" withExtension:@"bundle"];
        
            _resources = (resourcesURL
                          ? [NSBundle bundleWithURL:resourcesURL]
                          : mainBundle);
    });
}

- (instancetype)init {
    NSAssert(NO, @"Do not use -init. Use one of the -initWithPath or -initWithURL variants", nil);
    @throw nil;
}

- (instancetype)initWithPath:(NSString *)filePath error:(NSError * __autoreleasing*)error
{
    return [self initWithFile:[NSURL fileURLWithPath:filePath] error:error];
}

- (instancetype)initWithURL:(NSURL *)fileURL error:(NSError * __autoreleasing*)error
{
    return [self initWithFile:fileURL error:error];
}

- (instancetype)initWithPath:(NSString *)filePath password:(NSString *)password error:(NSError * __autoreleasing*)error
{
    return [self initWithFile:[NSURL fileURLWithPath:filePath]
                     password:password
                        error:error];
}

- (instancetype)initWithURL:(NSURL *)fileURL password:(NSString *)password error:(NSError * __autoreleasing*)error
{
    return [self initWithFile:fileURL password:password error:error];
}

- (instancetype)initWithFile:(NSURL *)fileURL error:(NSError * __autoreleasing*)error
{
    return [self initWithFile:fileURL password:nil error:error];
}

- (instancetype)initWithFile:(NSURL *)fileURL password:(NSString*)password error:(NSError * __autoreleasing*)error
{
    if ((self = [super init])) {
        if ([fileURL checkResourceIsReachableAndReturnError:NULL]) {
            NSError *bookmarkError = nil;
            if (![self storeFileBookmark:fileURL error:&bookmarkError]) {
                NSLog(@"Error creating bookmark to ZIP archive: %@", bookmarkError);
                
                if (error) {
                    *error = bookmarkError;
                }
                
                return nil;
            }
        }

        _openCount = 0;
        _mode = UZKFileModeUnassigned;
        
        _fallbackURL = fileURL;
        _password = password;
        _threadLock = [[NSObject alloc] init];
        
        _commentRetrieved = NO;
    }
    
    return self;
}



#pragma mark - Properties


- (NSURL *)fileURL
{
    if (!self.fileBookmark
        || (self.fallbackURL && [self.fallbackURL checkResourceIsReachableAndReturnError:NULL]))
    {
        return self.fallbackURL;
    }
    
    BOOL bookmarkIsStale = NO;
    NSError *error = nil;
    
    NSURL *result = [NSURL URLByResolvingBookmarkData:self.fileBookmark
                                              options:(NSURLBookmarkResolutionOptions)0
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&bookmarkIsStale
                                                error:&error];
    
    if (error) {
        NSLog(@"Error resolving bookmark to ZIP archive: %@", error);
        return nil;
    }
    
    if (bookmarkIsStale) {
        self.fallbackURL = result;
        
        if (![self storeFileBookmark:result
                               error:&error]) {
            NSLog(@"Error creating fresh bookmark to ZIP archive: %@", error);
        }
    }
    
    return result;
}

- (NSString *)filename
{
    NSURL *url = self.fileURL;
    
    if (!url) {
        return nil;
    }
    
    return url.path;
}

- (NSString *)comment
{
    if (self.commentRetrieved) {
        return _comment;
    }
    
    _comment = [self readGlobalComment];
    return _comment;
}

- (void)setComment:(NSString *)comment
{
    _comment = comment;
    self.commentRetrieved = YES;

    NSError *error = nil;
    BOOL success = [self performActionWithArchiveOpen:nil
                                               inMode:UZKFileModeAppend
                                                error:&error];

    if (!success) {
        NSLog(@"Failed to write comment to archive: %@", error);
    }
}



#pragma mark - Zip file detection


+ (BOOL)pathIsAZip:(NSString *)filePath
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (!handle) {
        return NO;
    }
    
    @try {
        NSData *fileData = [handle readDataOfLength:4];
        
        if (fileData.length < 4) {
            return NO;
        }
        
        const unsigned char *dataBytes = fileData.bytes;

        // First two bytes must equal 'PK'
        if (dataBytes[0] != 0x50 || dataBytes[1] != 0x4b) {
            return NO;
        }
        
        // Check for standard Zip
        if (dataBytes[2] == 0x03 &&
            dataBytes[3] == 0x04) {
            return YES;
        }
        
        // Check for empty Zip
        if (dataBytes[2] == 0x05 &&
            dataBytes[3] == 0x06) {
            return YES;
        }
        
        // Check for spanning Zip
        if (dataBytes[2] == 0x07 &&
            dataBytes[3] == 0x08) {
            return YES;
        }
    }
    @finally {
        [handle closeFile];
    }
    
    return NO;
}

+ (BOOL)urlIsAZip:(NSURL *)fileURL
{
    if (!fileURL || !fileURL.path) {
        return NO;
    }
    
    return [UZKArchive pathIsAZip:(NSString* _Nonnull)fileURL.path];
}



#pragma mark - Read Methods


- (NSArray<NSString*> *)listFilenames:(NSError * __autoreleasing*)error
{
    NSArray *zipInfos = [self listFileInfo:error];
    
    if (!zipInfos) {
        return nil;
    }
    
    return (NSArray* _Nonnull)[zipInfos valueForKeyPath:@"filename"];
}

- (NSArray<UZKFileInfo*> *)listFileInfo:(NSError * __autoreleasing*)error
{
    if (error) {
        *error = nil;
    }
    
    NSError *checkExistsError = nil;
    if (![self.fileURL checkResourceIsReachableAndReturnError:&checkExistsError]) {
        return @[];
    }
    
    NSError *unzipError;
    
    NSMutableArray *zipInfos = [NSMutableArray array];
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        unzGoToNextFile(self.unzFile);
        
        unz_global_info gi;
        int err = unzGetGlobalInfo(self.unzFile, &gi);
        if (err != UNZ_OK) {
            [self assignError:innerError code:UZKErrorCodeArchiveNotFound
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting global info (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                               err]];
            return;
        }
        
        NSUInteger fileCount = gi.number_entry;

        err = unzGoToFirstFile(self.unzFile);
        
        if (err != UNZ_OK) {
            [self assignError:innerError code:UZKErrorCodeFileNavigationError
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error going to first file in archive (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                               err]];
            return;
        }
        
        for (NSUInteger i = 0; i < fileCount; i++) {
            UZKFileInfo *info = [self currentFileInZipInfo:innerError];
            
            if (info) {
                [zipInfos addObject:info];
            } else {
                return;
            }
            
            err = unzGoToNextFile(self.unzFile);
            if (err == UNZ_END_OF_LIST_OF_FILE)
                return;
            
            if (err != UNZ_OK) {
                [self assignError:innerError code:UZKErrorCodeFileNavigationError
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error navigating to next file (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                   err]];
                return;
            }
        }
    } inMode:UZKFileModeUnzip error:&unzipError];
    
    if (!success) {
        if (error) {
            *error = unzipError;
        }
        
        return nil;
    }
    
    return [zipInfos copy];
}

- (BOOL)extractFilesTo:(NSString *)destinationDirectory
             overwrite:(BOOL)overwrite
              progress:(void (^)(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed))progress
                 error:(NSError * __autoreleasing*)error
{
    NSError *listError = nil;
    NSArray *fileInfo = [self listFileInfo:&listError];
    
    if (!fileInfo || listError) {
        NSLog(@"Error listing contents of archive: %@", listError);
        
        if (error) {
            *error = listError;
        }
        
        return NO;
    }
    
    NSFileManager *fm = [[NSFileManager alloc] init];

    NSNumber *totalSize = [fileInfo valueForKeyPath:@"@sum.uncompressedSize"];
    __block long long bytesDecompressed = 0;

    NSError *extractError = nil;
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        NSError *strongError = nil;
        
        @try {
            for (UZKFileInfo *info in fileInfo) {
                @autoreleasepool {
                    if (progress) {
                        progress(info, bytesDecompressed / totalSize.doubleValue);
                    }
                    
                    if (![self locateFileInZip:info.filename error:&strongError]) {
                        [self assignError:&strongError code:UZKErrorCodeFileNotFoundInArchive
                                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error locating file '%@' in archive", @"UnzipKit", _resources, @"Detailed error string"),
                                           info.filename]];
                        return;
                    }
                    
                    NSString *extractPath = [destinationDirectory stringByAppendingPathComponent:info.filename];
                    if ([fm fileExistsAtPath:extractPath] && !overwrite) {
                        return;
                    }
                    
                    if (info.isDirectory) {
                        continue;
                    }
                    
                    BOOL isDirectory = YES;
                    NSString *extractDir = extractPath.stringByDeletingLastPathComponent;
                    if (![fm fileExistsAtPath:extractDir]) {
                        BOOL directoriesCreated = [fm createDirectoryAtPath:extractDir
                                                withIntermediateDirectories:YES
                                                                 attributes:nil
                                                                      error:error];
                        if (!directoriesCreated) {
                            [self assignError:&strongError code:UZKErrorCodeOutputError
                                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to create destination directory: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                               extractDir]];
                            return;
                        }
                    } else if (!isDirectory) {
                        [self assignError:&strongError code:UZKErrorCodeOutputErrorPathIsAFile
                                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Extract path exists, but is not a directory: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                           extractDir]];
                        return;
                    }

                    
                    NSURL *deflatedDirectoryURL = [NSURL fileURLWithPath:destinationDirectory];
                    NSURL *deflatedFileURL = [deflatedDirectoryURL URLByAppendingPathComponent:info.filename];
                    NSString *path = deflatedFileURL.path;
                    
                    BOOL createSuccess = [fm createFileAtPath:path
                                                     contents:nil
                                                   attributes:nil];

                    if (!createSuccess) {
                        [self assignError:&strongError code:UZKErrorCodeOutputError
                                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error creating current file (%d) '%@'", @"UnzipKit", _resources, @"Detailed error string"),
                                           strongError, info.filename]];
                        return;
                    }
                                        
                    NSFileHandle *deflatedFileHandle = [NSFileHandle fileHandleForWritingToURL:deflatedFileURL
                                                                                         error:&strongError];

                    
                    if (!deflatedFileHandle) {
                        [self assignError:&strongError code:UZKErrorCodeOutputError
                                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error writing to file: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                           deflatedFileURL]];
                        return;
                    }
                    
                    BOOL extractSuccess = [self extractBufferedDataFromFile:info.filename
                                                                  error:&strongError
                                                                 action:
                                    ^(NSData *dataChunk, CGFloat percentDecompressed) {
                                        bytesDecompressed += dataChunk.length;
                                        [deflatedFileHandle writeData:dataChunk];
                                        if (progress) {
                                            progress(info, bytesDecompressed / totalSize.doubleValue);
                                        }
                                    }];

                    [deflatedFileHandle closeFile];
                    
                    if (!extractSuccess) {
                        [self assignError:&strongError code:strongError.code
                                   detail:strongError.localizedDescription];
                        
                        // Remove the directory we were going to unzip to if it fails.
                        [fm removeItemAtURL:deflatedDirectoryURL
                                      error:nil];
                        return;
                    }
                }
            }
        }
        @finally {
            if (strongError && innerError) {
                *innerError = strongError;
            }
        }
    } inMode:UZKFileModeUnzip error:&extractError];
    
    if (error) {
        *error = extractError ? extractError : nil;
    }

    return success;
}

- (nullable NSData *)extractData:(UZKFileInfo *)fileInfo
                        progress:(void (^)(CGFloat))progress
                           error:(NSError * __autoreleasing*)error
{
    return [self extractDataFromFile:fileInfo.filename
                            progress:progress
                               error:error];
}

- (nullable NSData *)extractDataFromFile:(NSString *)filePath
                                progress:(void (^)(CGFloat))progress
                                   error:(NSError * __autoreleasing*)error
{
    NSMutableData *result = [NSMutableData data];
    
    BOOL success = [self extractBufferedDataFromFile:filePath
                                               error:error
                                              action:^(NSData *dataChunk, CGFloat percentDecompressed) {
                                                  if (progress) {
                                                      progress(percentDecompressed);
                                                  }
                                                  
                                                  [result appendData:dataChunk];
                                              }];
    
    if (progress) {
        progress(1.0);
    }
    
    if (!success) {
        return nil;
    }
    
    return [NSData dataWithData:result];
}

- (BOOL)performOnFilesInArchive:(void (^)(UZKFileInfo *, BOOL *))action
                          error:(NSError * __autoreleasing*)error
{
    NSError *listError = nil;
    NSArray *fileInfo = [self listFileInfo:&listError];
    
    if (listError || !fileInfo) {
        NSLog(@"Failed to list the files in the archive");
        
        if (error) {
            *error = listError;
        }
        
        return NO;
    }
    
    NSArray *sortedFileInfo = [fileInfo sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:YES]]];
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        BOOL stop = NO;

        for (UZKFileInfo *info in sortedFileInfo) {
            action(info, &stop);
            
            if (stop) {
                break;
            }
        }
    } inMode:UZKFileModeUnzip error:error];
    
    return success;
}

- (BOOL)performOnDataInArchive:(void (^)(UZKFileInfo *, NSData *, BOOL *))action
                         error:(NSError * __autoreleasing*)error
{
    return [self performOnFilesInArchive:^(UZKFileInfo *fileInfo, BOOL *stop) {
        if (![self locateFileInZip:fileInfo.filename error:error]) {
            [self assignError:error code:UZKErrorCodeFileNotFoundInArchive
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to locate '%@' in archive during-perform on-data operation", @"UnzipKit", _resources, @"Detailed error string"),
                               fileInfo.filename]];
            return;
        }
        
        NSData *fileData = [self readFile:fileInfo.filename
                                   length:fileInfo.uncompressedSize
                                    error:error];
        
        if (!fileData) {
            NSLog(@"Error reading file %@ in archive", fileInfo.filename);
            return;
        }
        
        action(fileInfo, fileData, stop);
    } error:error];
}

- (BOOL)extractBufferedDataFromFile:(NSString *)filePath
                              error:(NSError * __autoreleasing*)error
                             action:(void (^)(NSData *, CGFloat))action
{
    NSUInteger bufferSize = 4096; //Arbitrary
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        if (![self locateFileInZip:filePath error:innerError]) {
            [self assignError:innerError code:UZKErrorCodeFileNotFoundInArchive
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to locate '%@' in archive during buffered read", @"UnzipKit", _resources, @"Detailed error string"),
                               filePath]];
            return;
        }
        
        UZKFileInfo *info = [self currentFileInZipInfo:innerError];
        
        if (!info) {
            NSLog(@"Failed to locate file %@ in zip", filePath);
            return;
        }
        
        if (![self openFile:innerError]) {
            return;
        }
        
        long long bytesDecompressed = 0;
        
        for (;;)
        {
            @autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
                int bytesRead = unzReadCurrentFile(self.unzFile, data.mutableBytes, (unsigned)bufferSize);
                
                if (bytesRead < 0) {
                    [self assignError:innerError code:bytesRead
                               detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to read file %@ in zip", @"UnzipKit", _resources, @"Detailed error string"),
                                       info.filename]];
                    return;
                }
                else if (bytesRead == 0) {
                    break;
                }
                
                data.length = bytesRead;
                bytesDecompressed += bytesRead;
                
                if (action) {
                    action([data copy], bytesDecompressed / (CGFloat)info.uncompressedSize);
                }
            }
        }
        
        int err = unzCloseCurrentFile(self.unzFile);
        if (err != UNZ_OK) {
            if (err == UZKErrorCodeCRCError) {
                err = UZKErrorCodeInvalidPassword;
            }
            
            [self assignError:innerError code:err
                       detail:NSLocalizedStringFromTableInBundle(@"Error closing current file during buffered read", @"UnzipKit", _resources, @"Detailed error string")];
            return;
        }
    } inMode:UZKFileModeUnzip error:error];
    
    return success;
}

- (BOOL)isPasswordProtected
{
    NSError *error = nil;
    NSArray *fileInfos = [self listFileInfo:&error];
    
    if (error) {
        NSLog(@"Error checking whether file is password protected: %@", error);
        return NO;
    }
    
    for (UZKFileInfo *fileInfo in fileInfos) {
        if (fileInfo.isEncryptedWithPassword) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)validatePassword
{
    if (!self.isPasswordProtected) {
        return YES;
    }
    
    NSError *error = nil;
    NSArray *fileInfos = [self listFileInfo:&error];
    
    if (error) {
        NSLog(@"Error checking whether file is password protected: %@", error);
        return NO;
    }
    
    if (!fileInfos || fileInfos.count == 0) {
        NSLog(@"No files in archive");
        return NO;
    }
    
    UZKFileInfo *smallest = [fileInfos sortedArrayUsingComparator:^NSComparisonResult(UZKFileInfo *file1, UZKFileInfo *file2) {
        if (file1.uncompressedSize < file2.uncompressedSize)
            return NSOrderedAscending;
        if (file1.uncompressedSize > file2.uncompressedSize)
            return NSOrderedDescending;
        return NSOrderedSame;
    }].firstObject;

    NSData *smallestData = [self extractData:(UZKFileInfo* _Nonnull)smallest
                                    progress:nil
                                       error:&error];
    
    if (error || !smallestData) {
        NSLog(@"Error while checking password: %@", error);
        return NO;
    }
    
    return YES;
}



#pragma mark - Write Methods


- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
            error:(NSError * __autoreleasing*)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:nil
         compressionMethod:UZKCompressionMethodDefault
                  password:nil
                 overwrite:YES
                  progress:nil
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError * __autoreleasing*)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:nil
         compressionMethod:UZKCompressionMethodDefault
                  password:nil
                 overwrite:YES
                  progress:progress
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError * __autoreleasing*)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
         compressionMethod:UZKCompressionMethodDefault
                  password:nil
                 overwrite:YES
                  progress:progress
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(NSString *)password
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError * __autoreleasing*)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
         compressionMethod:UZKCompressionMethodDefault
                  password:password
                 overwrite:YES
                  progress:progress
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(NSString *)password
        overwrite:(BOOL)overwrite
         progress:(void (^)(CGFloat percentCompressed))progress
            error:(NSError * __autoreleasing*)error
{
    NSUInteger bufferSize = 4096; //Arbitrary
    const void *bytes = data.bytes;
    
    if (progress) {
        progress(0);
    }

    uLong calculatedCRC = crc32(0, data.bytes, (uInt)data.length);
    
    BOOL success = [self performWriteAction:^int(uLong *crc, NSError * __autoreleasing*innerError) {
        NSAssert(crc, @"No CRC reference passed", nil);
        *crc = calculatedCRC;
        
        for (NSUInteger i = 0; i <= data.length; i += bufferSize) {
            unsigned int dataRemaining = (unsigned int)(data.length - i);
            unsigned int size = (unsigned int)(dataRemaining < bufferSize ? dataRemaining : bufferSize);
            int err = zipWriteInFileInZip(self.zipFile, (const char *)bytes + i, size);
            
            if (err != ZIP_OK) {
                return err;
            }
            
            if (progress) {
                progress(i / (CGFloat)data.length);
            }
        }
        
        return ZIP_OK;
    }
                                   filePath:filePath
                                   fileDate:fileDate
                          compressionMethod:method
                                   password:password
                                  overwrite:overwrite
                                        CRC:calculatedCRC
                                      error:error];
    
    return success;
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
                  error:(NSError * __autoreleasing*)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError * __autoreleasing*actionError))action
{
    return [self writeIntoBuffer:filePath
                        fileDate:nil
               compressionMethod:UZKCompressionMethodDefault
                       overwrite:YES
                             CRC:0
                        password:nil
                           error:error
                           block:action];
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
                  error:(NSError * __autoreleasing*)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError * __autoreleasing*actionError))action
{
    return [self writeIntoBuffer:filePath
                        fileDate:fileDate
               compressionMethod:UZKCompressionMethodDefault
                       overwrite:YES
                             CRC:0
                        password:nil
                           error:error
                           block:action];
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
                  error:(NSError * __autoreleasing*)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError * __autoreleasing*actionError))action
{
    return [self writeIntoBuffer:filePath
                        fileDate:fileDate
               compressionMethod:method
                       overwrite:YES
                             CRC:0
                        password:nil
                           error:error
                           block:action];
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                  error:(NSError * __autoreleasing*)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError * __autoreleasing*actionError))action
{
    return [self writeIntoBuffer:filePath
                        fileDate:fileDate
               compressionMethod:method
                       overwrite:overwrite
                             CRC:0
                        password:nil
                           error:error
                           block:action];
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                    CRC:(uLong)preCRC
                  error:(NSError *__autoreleasing *)error
                  block:(BOOL (^)(BOOL (^)(const void *, unsigned int), NSError *__autoreleasing *))action
{
    return [self writeIntoBuffer:filePath
                        fileDate:fileDate
               compressionMethod:method
                       overwrite:overwrite
                             CRC:preCRC
                        password:nil
                           error:error
                           block:action];
}

- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                    CRC:(uLong)preCRC
               password:(NSString *)password
                  error:(NSError *__autoreleasing *)error
                  block:(BOOL (^)(BOOL (^)(const void *, unsigned int), NSError *__autoreleasing *))action
{
    NSAssert(preCRC != 0 || ([password length] == 0 && [self.password length] == 0),
             @"Cannot provide a password when writing into a buffer, "
             "unless a CRC is provided up front for inclusion in the header", nil);
    
    BOOL success = [self performWriteAction:^int(uLong *crc, NSError * __autoreleasing*innerError) {
        __block int writeErr;
        
        if (!action) {
            return ZIP_OK;
        }
        
        BOOL result = action(^BOOL(const void *bytes, unsigned int length){
            writeErr = zipWriteInFileInZip(self.zipFile, bytes, length);
            if (writeErr != ZIP_OK) {
                return NO;
            }
            
            NSAssert(crc, @"No CRC reference passed", nil);
            
            uLong oldCRC = *crc;
            *crc = crc32(oldCRC, bytes, (uInt)length);;
            
            return YES;
        }, innerError);
        
        if (preCRC != 0 && *crc != preCRC) {
            uLong calculatedCRC = *crc;
            NSString *preCRCStr = [NSString stringWithFormat:@"%010lu", preCRC];
            NSString *calculatedCRCStr = [NSString stringWithFormat:@"%010lu", calculatedCRC];
            return [self assignError:innerError
                                code:UZKErrorCodePreCRCMismatch
                              detail:[NSString stringWithFormat:
                                      NSLocalizedStringFromTableInBundle(@"Incorrect CRC provided\n%@ given\n%@ calculated", @"UnzipKit", _resources, @"CRC mismatch error detail"),
                                      preCRCStr, calculatedCRCStr]];
        }
        
        return result;
    }
                                   filePath:filePath
                                   fileDate:fileDate
                          compressionMethod:method
                                   password:password
                                  overwrite:overwrite
                                        CRC:preCRC
                                      error:error];
    
    return success;
}

- (BOOL)deleteFile:(NSString *)filePath error:(NSError * __autoreleasing*)error
{
    // Thanks to Ivan A. Krestinin for much of the code below: http://www.winimage.com/zLibDll/del.cpp
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (!self.filename || ![fm fileExistsAtPath:(NSString* _Nonnull)self.filename]) {
        NSLog(@"No archive exists at path %@, when trying to delete %@", self.filename, filePath);
        return YES;
    }
    
    NSString *randomString = [NSString stringWithFormat:@"%@.zip", [[NSProcessInfo processInfo] globallyUniqueString]];
    NSURL *temporaryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString];
    
    const char *originalFilename = self.filename.UTF8String;
    const char *del_file = filePath.UTF8String;
    const char *tempFilename = temporaryURL.path.UTF8String;
    
    // Open source and destination files
    
    zipFile sourceZip = unzOpen(originalFilename);
    if (sourceZip == NULL) {
        return [self assignError:error code:UZKErrorCodeDeleteFile
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening the source file while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                  filePath]];
    }
    
    zipFile destZip = zipOpen(tempFilename, APPEND_STATUS_CREATE);
    if (destZip == NULL) {
        unzClose(sourceZip);
        return [self assignError:error code:UZKErrorCodeDeleteFile
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening the destination file while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                  filePath]];
    }
    
    // Get global commentary
    
    unz_global_info globalInfo;
    int err = unzGetGlobalInfo(sourceZip, &globalInfo);
    if (err != UNZ_OK) {
        zipClose(destZip, NULL);
        unzClose(sourceZip);
        return [self assignError:error code:UZKErrorCodeDeleteFile
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting the global info of the source file while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                  filePath, err]];
    }
    
    char *globalComment = NULL;
    
    if (globalInfo.size_comment > 0)
    {
        globalComment = (char*)malloc(globalInfo.size_comment+1);
        if ((globalComment == NULL) && (globalInfo.size_comment != 0)) {
            zipClose(destZip, NULL);
            unzClose(sourceZip);
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error reading the global comment of the source file while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                      filePath]];
        }
        
        if ((unsigned int)unzGetGlobalComment(sourceZip, globalComment, globalInfo.size_comment + 1) != globalInfo.size_comment) {
            zipClose(destZip, NULL);
            unzClose(sourceZip);
            free(globalComment);
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error reading the global comment of the source file while deleting %@ (wrong size)", @"UnzipKit", _resources, @"Detailed error string"),
                                      filePath]];
        }
    }
    
    BOOL noFilesDeleted = YES;
    int filesCopied = 0;
    
    NSString *filenameToDelete = [UZKArchive figureOutCString:del_file];
    
    int nextFileReturnValue = unzGoToFirstFile(sourceZip);
    
    while (nextFileReturnValue == UNZ_OK)
    {
        // Get zipped file info
        char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
        unz_file_info64 unzipInfo;
        
        err = unzGetCurrentFileInfo64(sourceZip, &unzipInfo, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
        if (err != UNZ_OK) {
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting file info of file while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                      filePath, err]];
        }
        
        NSString *currentFileName = [UZKArchive figureOutCString:filename_inzip];
        
        // if not need delete this file
        if ([filenameToDelete isEqualToString:currentFileName.decomposedStringWithCanonicalMapping])
            noFilesDeleted = NO;
        else
        {
            char *extrafield = (char*)malloc(unzipInfo.size_file_extra);
            if ((extrafield == NULL) && (unzipInfo.size_file_extra != 0)) {
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error allocating extrafield info of %@ while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            char *commentary = (char*)malloc(unzipInfo.size_file_comment);
            if ((commentary == NULL) && (unzipInfo.size_file_comment != 0)) {
                free(extrafield);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error allocating commentary info of %@ while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            err = unzGetCurrentFileInfo64(sourceZip, &unzipInfo, filename_inzip, FILE_IN_ZIP_MAX_NAME_LENGTH, extrafield, unzipInfo.size_file_extra, commentary, unzipInfo.size_file_comment);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error reading extrafield and commentary info of %@ while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            // Open source archive for raw reading
            
            int method;
            int level;
            err = unzOpenCurrentFile2(sourceZip, &method, &level, 1);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening %@ for raw reading while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            int size_local_extra = unzGetLocalExtrafield(sourceZip, NULL, 0);
            if (size_local_extra < 0) {
                free(extrafield);
                free(commentary);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting size_local_extra for file while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            void *local_extra = malloc(size_local_extra);
            if ((local_extra == NULL) && (size_local_extra != 0)) {
                free(extrafield);
                free(commentary);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error allocating local_extra for file %@ while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            if (unzGetLocalExtrafield(sourceZip, local_extra, size_local_extra) < 0) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting local_extra for file %@ while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            // This malloc may fail if the file is very large
            void *buf = malloc((unsigned long)unzipInfo.compressed_size);
            if ((buf == NULL) && (unzipInfo.compressed_size != 0)) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error allocating buffer for file %@ while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            // Read file
            int size = unzReadCurrentFile(sourceZip, buf, (uInt)unzipInfo.compressed_size);
            if ((unsigned int)size != unzipInfo.compressed_size) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error reading %@ into buffer while deleting %@", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath]];
            }
            
            // Open destination archive
            
            zip_fileinfo zipInfo;
            memcpy (&zipInfo.tmz_date, &unzipInfo.tmu_date, sizeof(tm_unz));
            zipInfo.dosDate = unzipInfo.dosDate;
            zipInfo.internal_fa = unzipInfo.internal_fa;
            zipInfo.external_fa = unzipInfo.external_fa;
            
            err = zipOpenNewFileInZip2(destZip, filename_inzip, &zipInfo,
                                       local_extra, size_local_extra, extrafield, (uInt)unzipInfo.size_file_extra, commentary,
                                       method, level, 1);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening %@ in destination zip while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            // Write file
            err = zipWriteInFileInZip(destZip, buf, (uInt)unzipInfo.compressed_size);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error writing %@ to destination zip while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            // Close destination archive
            err = zipCloseFileInZipRaw64(destZip, unzipInfo.uncompressed_size, unzipInfo.crc);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing %@ in destination zip while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            // Close source archive
            err = unzCloseCurrentFile(sourceZip);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                return [self assignError:error code:UZKErrorCodeDeleteFile
                                  detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing %@ in source zip while deleting %@ (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                          currentFileName, filePath, err]];
            }
            
            free(commentary);
            free(buf);
            free(extrafield);
            free(local_extra);
            
            ++filesCopied;
        }
        
        nextFileReturnValue = unzGoToNextFile(sourceZip);
    }
    
    zipClose(destZip, globalComment);
    unzClose(sourceZip);
    
    // Don't change the files around
    if (noFilesDeleted) {
        return YES;
    }
    
    // Failure
    if (nextFileReturnValue != UNZ_END_OF_LIST_OF_FILE)
    {
        remove(tempFilename);
        return [self assignError:error code:UZKErrorCodeDeleteFile
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to seek to the next file, while deleting %@ from the archive", @"UnzipKit", _resources, @"Detailed error string"),
                                  filenameToDelete]];
    }
    
    // Replace old file with the new (trimmed) one
    NSURL *newURL;
    
    NSString *temporaryVolume = temporaryURL.volumeName;
    NSString *destinationVolume = self.fileURL.volumeName;
    
    if ([temporaryVolume isEqualToString:destinationVolume]) {
        NSError *replaceError = nil;
        BOOL result = [fm replaceItemAtURL:(NSURL* _Nonnull)self.fileURL
                             withItemAtURL:temporaryURL
                            backupItemName:nil
                                   options:NSFileManagerItemReplacementWithoutDeletingBackupItem
                          resultingItemURL:&newURL
                                     error:&replaceError];
        
        if (!result)
        {
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to replace the old archive with the new one, after deleting '%@' from it", @"UnzipKit", _resources, @"Detailed error string"),
                                      filenameToDelete]
                           underlyer:replaceError];
        }
    } else {
        newURL = self.fileURL;
        
        NSError *deleteError = nil;
        if (![fm removeItemAtURL:(NSURL* _Nonnull)newURL
                           error:&deleteError]) {
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to remove archive from external volume '%@', after deleting '%@' from a new version to replace it", @"UnzipKit", _resources, @"Detailed error string"),
                                      destinationVolume, filenameToDelete]
                           underlyer:deleteError];
        }
        
        NSError *copyError = nil;
        if (![fm copyItemAtURL:temporaryURL
                         toURL:(NSURL* _Nonnull)newURL
                         error:&copyError]) {
            return [self assignError:error code:UZKErrorCodeDeleteFile
                              detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to copy archive to external volume '%@', after deleting '%@' from it", @"UnzipKit", _resources, @"Detailed error string"),
                                      destinationVolume, filenameToDelete]
                           underlyer:copyError];
        }
    }
    
    NSError *bookmarkError = nil;
    if (![self storeFileBookmark:newURL
                           error:&bookmarkError])
    {
        return [self assignError:error code:UZKErrorCodeDeleteFile
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to store the new file bookmark to the archive after deleting '%@' from it: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                  filenameToDelete, bookmarkError.localizedDescription]
                       underlyer:bookmarkError];
    }
    
    return YES;
}



#pragma mark - Private Methods


- (BOOL)performActionWithArchiveOpen:(void(^)(NSError * __autoreleasing*innerError))action
                              inMode:(UZKFileMode)mode
                               error:(NSError * __autoreleasing*)error
{
    @synchronized(self.threadLock) {
        if (error) {
            *error = nil;
        }
        
        NSError *openError = nil;
        NSError *actionError = nil;
        
        @try {
            if (![self openFile:self.filename
                         inMode:mode
                   withPassword:self.password
                          error:&openError])
            {
                if (error) {
                    *error = openError;
                }
                
                return NO;
            }
            
            if (action) {
                action(&actionError);
            }
        }
        @finally {
            NSError *closeError = nil;
            if (![self closeFile:&closeError inMode:mode]) {
                if (error && !actionError && !openError) {
                    *error = closeError;
                }
                
                return NO;
            }
        }
        
        if (error && actionError && !openError) {
            *error = actionError;
        }
        
        return !actionError;
    }
}

- (BOOL)performWriteAction:(int(^)(uLong *crc, NSError * __autoreleasing*innerError))write
                  filePath:(NSString *)filePath
                  fileDate:(NSDate *)fileDate
         compressionMethod:(UZKCompressionMethod)method
                  password:(NSString *)password
                 overwrite:(BOOL)overwrite
                       CRC:(uLong)crc
                     error:(NSError * __autoreleasing*)error
{
    if (overwrite) {
        NSError *listFilesError = nil;
        NSArray *existingFiles;
        
        @autoreleasepool {
            existingFiles = [self listFileInfo:&listFilesError];
        }
        
        if (existingFiles) {
            NSIndexSet *matchingFiles = [existingFiles indexesOfObjectsPassingTest:
                                         ^BOOL(UZKFileInfo *info, NSUInteger idx, BOOL *stop) {
                                             if ([info.filename isEqualToString:filePath]) {
                                                 *stop = YES;
                                                 return YES;
                                             }
                                             
                                             return NO;
                                         }];
            
            if (matchingFiles.count > 0 && ![self deleteFile:filePath error:error]) {
                NSLog(@"Failed to delete %@ before writing new data for it", filePath);
                return NO;
            }
        }
    }
    
    if (!password) {
        password = self.password;
    }
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        zip_fileinfo zi = [UZKArchive zipFileInfoForDate:fileDate];
        
        const char *passwordStr = NULL;
        
        if (password) {
            passwordStr = [password cStringUsingEncoding:NSISOLatin1StringEncoding];
        }
        
        int err = zipOpenNewFileInZip3(self.zipFile,
                                       filePath.UTF8String,
                                       &zi,
                                       NULL, 0, NULL, 0, NULL,
                                       (method != UZKCompressionMethodNone) ? Z_DEFLATED : 0,
                                       method,
                                       0,
                                       -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                       passwordStr,
                                       crc);
        
        if (err != ZIP_OK) {
            [self assignError:innerError code:UZKErrorCodeFileOpenForWrite
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening file '%@' for write (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                               filePath, err]];
            return;
        }
        
        uLong outCRC = 0;
        err = write(&outCRC, innerError);
        if (err < 0) {
            [self assignError:innerError code:UZKErrorCodeFileWrite
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error writing to file  '%@' (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                               filePath, err]];
            return;
        }
        
        err = zipCloseFileInZipRaw(self.zipFile, 0, outCRC);
        if (err != ZIP_OK) {
            [self assignError:innerError code:UZKErrorCodeFileWrite
                       detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing file '%@' for write (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                               filePath, err]];
            return;
        }
        
    } inMode:UZKFileModeAppend error:error];
    
    return success;
}

- (BOOL)openFile:(NSString *)zipFile
          inMode:(UZKFileMode)mode
    withPassword:(NSString *)aPassword
           error:(NSError * __autoreleasing*)error
{
    if (error) {
        *error = nil;
    }
    
    if (self.mode != UZKFileModeUnassigned && self.mode != mode) {
        NSString *message;
        
        if (self.mode == UZKFileModeUnzip) {
            message = NSLocalizedStringFromTableInBundle(@"Unable to begin writing to the archive until all read operations have completed", @"UnzipKit", _resources, @"Detailed error string");
        } else {
            message = NSLocalizedStringFromTableInBundle(@"Unable to begin reading from the archive until all write operations have completed", @"UnzipKit", _resources, @"Detailed error string");
        }
        
        return [self assignError:error code:UZKErrorCodeMixedModeAccess detail:message];
    }
    
    if (mode != UZKFileModeUnzip && self.openCount > 0) {
        return [self assignError:error code:UZKErrorCodeFileWrite
                          detail:NSLocalizedStringFromTableInBundle(@"Attempted to write to the archive while another write operation is already in progress", @"UnzipKit", _resources, @"Detailed error string")];
    }
    
    // Always initialize comment, so it can be read when the file is closed
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    if (!self.commentRetrieved) {
        self.commentRetrieved = YES;
        _comment = [self readGlobalComment];
    }
#pragma clang diagnostic pop

    if (self.openCount++ > 0) {
        return YES;
    }
    
    self.mode = mode;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    switch (mode) {
        case UZKFileModeUnzip: {
            if (![fm fileExistsAtPath:zipFile]) {
                [self assignError:error code:UZKErrorCodeArchiveNotFound
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"No file found at path %@", @"UnzipKit", _resources, @"Detailed error string"),
                                   zipFile]];
                return NO;
            }
            
            self.unzFile = unzOpen(self.filename.UTF8String);
            if (self.unzFile == NULL) {
                [self assignError:error code:UZKErrorCodeBadZipFile
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening zip file %@", @"UnzipKit", _resources, @"Detailed error string"),
                                   zipFile]];
                return NO;
            }
            
            int err = unzGoToFirstFile(self.unzFile);
            if (err != UNZ_OK) {
                [self assignError:error code:UZKErrorCodeFileNavigationError
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error going to first file in archive (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                   err]];
                return NO;
            }
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            
            do {
                @autoreleasepool {
                    UZKFileInfo *info = [self currentFileInZipInfo:error];
                    
                    if (!info) {
                        return NO;
                    }
                    
                    unz_file_pos pos;
                    int err = unzGetFilePos(self.unzFile, &pos);
                    if (err == UNZ_OK && info.filename) {
                        NSValue *dictValue = [NSValue valueWithBytes:&pos
                                                            objCType:@encode(unz_file_pos)];
                        dic[info.filename.decomposedStringWithCanonicalMapping] = dictValue;
                    }
                }
            } while (unzGoToNextFile (self.unzFile) != UNZ_END_OF_LIST_OF_FILE);
            
            self.archiveContents = [dic copy];
            break;
        }
        case UZKFileModeCreate:
        case UZKFileModeAppend:
            if (![fm fileExistsAtPath:zipFile]) {
                NSError *createFileError = nil;
                
                if (![[NSData data] writeToFile:zipFile options:NSDataWritingAtomic error:&createFileError]) {
                    return [self assignError:error code:UZKErrorCodeFileOpenForWrite
                                      detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed to create new file for archive: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                              createFileError.localizedDescription]
                                   underlyer:createFileError];
                }
                
                NSError *bookmarkError = nil;
                if (![self storeFileBookmark:[NSURL fileURLWithPath:zipFile]
                                       error:&bookmarkError])
                {
                    return [self assignError:error code:UZKErrorCodeFileOpenForWrite
                                      detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error creating bookmark to new archive file: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                              bookmarkError.localizedDescription]
                                   underlyer:bookmarkError];
                }
            }
            
            int appendStatus = mode == UZKFileModeCreate ? APPEND_STATUS_CREATE : APPEND_STATUS_ADDINZIP;
            
            self.zipFile = zipOpen(self.filename.UTF8String, appendStatus);
            if (self.zipFile == NULL) {
                [self assignError:error code:UZKErrorCodeArchiveNotFound
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening zip file for write: %@", @"UnzipKit", _resources, @"Detailed error string"),
                                   zipFile]];
                return NO;
            }
            break;
            
        case UZKFileModeUnassigned:
            NSAssert(NO, @"Cannot call -openFile:inMode:withPassword:error: with a mode of UZKFileModeUnassigned (%lu)", (unsigned long)mode);
            break;
    }
    
    return YES;
}

- (BOOL)closeFile:(NSError * __autoreleasing*)error
           inMode:(UZKFileMode)mode
{
    int err;
    const char *cmt;
    
    if (mode != self.mode) {
        return NO;
    }
    
    if (--self.openCount > 0) {
        return YES;
    }
    
    BOOL closeSucceeded = YES;
    
    switch (self.mode) {
        case UZKFileModeUnzip:
            if (!self.unzFile) {
                break;
            }
            err = unzClose(self.unzFile);
            if (err != UNZ_OK) {
                [self assignError:error code:UZKErrorCodeZLibError
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing file in archive after read (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                   err]];
                closeSucceeded = NO;
            }
            break;

        case UZKFileModeCreate:
            if (!self.zipFile) {
                break;
            }
            cmt = self.comment.UTF8String;
            err = zipClose(self.zipFile, cmt);
            if (err != ZIP_OK) {
                [self assignError:error code:UZKErrorCodeZLibError
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing file in archive after create (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                   err]];
                closeSucceeded = NO;
            }
            break;

        case UZKFileModeAppend:
            if (!self.zipFile) {
                break;
            }
            cmt = self.comment.UTF8String;
            err= zipClose(self.zipFile, cmt);
            if (err != ZIP_OK) {
                [self assignError:error code:UZKErrorCodeZLibError
                           detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error closing file in archive after append (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                   err]];
                closeSucceeded = NO;
            }
            break;
            
        case UZKFileModeUnassigned:
            NSAssert(NO, @"Unbalanced call to -closeFile:, openCount == %ld", (long)self.openCount);
            break;
    }
    
    if (self.openCount == 0) {
        self.mode = UZKFileModeUnassigned;
    }
    
    return closeSucceeded;
}



#pragma mark - Zip File Navigation


- (UZKFileInfo *)currentFileInZipInfo:(NSError * __autoreleasing*)error {
    char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
    unz_file_info64 file_info;
    
    int err = unzGetCurrentFileInfo64(self.unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
    if (err != UNZ_OK) {
        [self assignError:error code:UZKErrorCodeArchiveNotFound
                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting current file info (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                           err]];
        return nil;
    }
    
    NSString *filename = [UZKArchive figureOutCString:filename_inzip];
    return [UZKFileInfo fileInfo:&file_info filename:filename];
}

- (BOOL)locateFileInZip:(NSString *)fileNameInZip error:(NSError * __autoreleasing*)error {
    NSValue *filePosValue = self.archiveContents[fileNameInZip.decomposedStringWithCanonicalMapping];
    
    if (!filePosValue) {
        return [self assignError:error code:UZKErrorCodeFileNotFoundInArchive
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"No file position found for '%@'", @"UnzipKit", _resources, @"Detailed error string"),
                                  fileNameInZip]];
    }
    
    unz_file_pos pos;
    [filePosValue getValue:&pos];
    
    int err = unzGoToFilePos(self.unzFile, &pos);
    
    if (err == UNZ_END_OF_LIST_OF_FILE) {
        return [self assignError:error code:UZKErrorCodeFileNotFoundInArchive
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"File '%@' not found in archive", @"UnzipKit", _resources, @"Detailed error string"),
                                  fileNameInZip]];
    }

    if (err != UNZ_OK) {
        return [self assignError:error code:err
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error seeking to file position (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                  err]];
    }
    
    return YES;
}



#pragma mark - Zip File Operations


- (BOOL)openFile:(NSError * __autoreleasing*)error
{
    char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
    unz_file_info64 file_info;
    
    int err = unzGetCurrentFileInfo64(self.unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
    if (err != UNZ_OK) {
        return [self assignError:error code:UZKErrorCodeInternalError
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error getting current file info for archive (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                  err]];
    }
    
    const char *passwordStr = NULL;
    
    if (self.password) {
        passwordStr = [self.password cStringUsingEncoding:NSISOLatin1StringEncoding];
    }
    
    if ([self isDeflate64:file_info]) {
        return [self assignError:error
                            code:UZKErrorCodeDeflate64
                          detail:NSLocalizedStringFromTableInBundle(@"Cannot open archive, since it was compressed using the Deflate64 algorithm (method ID 9)", @"UnzipKit", _resources, @"Error message")];
    }
    
    err = unzOpenCurrentFilePassword(self.unzFile, passwordStr);
    if (err != UNZ_OK) {
        return [self assignError:error code:err
                          detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error opening archive (%d)", @"UnzipKit", _resources, @"Detailed error string"),
                                  err]];
    }
    
    return YES;
}


- (NSData *)readFile:(NSString *)filePath length:(unsigned long long int)length error:(NSError * __autoreleasing*)error {
    if (![self openFile:error]) {
        return nil;
    }
    
    NSMutableData *data = [NSMutableData dataWithLength:(NSUInteger)length];
    int bytes = unzReadCurrentFile(self.unzFile, data.mutableBytes, (unsigned)length);
    
    if (bytes < 0) {
        [self assignError:error code:bytes
                   detail:[NSString localizedStringWithFormat:NSLocalizedStringFromTableInBundle(@"Error reading data from '%@' in archive", @"UnzipKit", _resources, @"Detailed error string"),
                           filePath]];
        return nil;
    }
    
    data.length = bytes;
    return data;
}

- (NSString *)readGlobalComment {
    
    NSError *checkExistsError = nil;
    if (![self.fileURL checkResourceIsReachableAndReturnError:&checkExistsError]) {
        return nil;
    }
    
    __weak UZKArchive *welf = self;
    __block NSString *comment = nil;
    NSError *error = nil;
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError * __autoreleasing*innerError) {
        unz_global_info globalInfo;
        int err = unzGetGlobalInfo(welf.unzFile, &globalInfo);
        if (err != UNZ_OK) {
            unzClose(welf.unzFile);
            
            NSString *detail = [NSString stringWithFormat:@"Error getting global info of archive during comment read: %d", err];
            [welf assignError:innerError code:UZKErrorCodeReadComment detail:detail];
            return;
        }
        
        char *globalComment = NULL;
        
        if (globalInfo.size_comment > 0)
        {
            globalComment = (char*)malloc(globalInfo.size_comment+1);
            if ((globalComment == NULL) && (globalInfo.size_comment != 0)) {
                unzClose(welf.unzFile);
                
                [welf assignError:innerError code:UZKErrorCodeReadComment detail:@"Error allocating the global comment during comment read"];
                return;
            }
            
            if ((unsigned int)unzGetGlobalComment(welf.unzFile, globalComment, globalInfo.size_comment + 1) != globalInfo.size_comment) {
                unzClose(welf.unzFile);
                free(globalComment);
                
                [welf assignError:innerError code:UZKErrorCodeReadComment detail:@"Error reading the comment (readGlobalComment)"];
                return;
            }
            
            comment = [UZKArchive figureOutCString:globalComment];
        }
    } inMode:UZKFileModeUnzip error:&error];
    
    self.commentRetrieved = YES;

    if (!success) {
        return nil;
    }
    
    return comment;
}



#pragma mark - Misc. Private Methods


- (BOOL)storeFileBookmark:(NSURL *)fileURL error:(NSError * __autoreleasing*)error
{
    NSError *bookmarkError = nil;
    self.fileBookmark = [fileURL bookmarkDataWithOptions:(NSURLBookmarkCreationOptions)0
                          includingResourceValuesForKeys:@[]
                                           relativeToURL:nil
                                                   error:&bookmarkError];
    
    if (error) {
        *error = bookmarkError ? bookmarkError : nil;
    }
    
    return bookmarkError == nil;
}

+ (NSString *)figureOutCString:(const char *)filenameBytes
{
    NSString *stringValue = [NSString stringWithUTF8String:filenameBytes];
    
    if (!stringValue) {
        stringValue = [NSString stringWithCString:filenameBytes
                                         encoding:NSWindowsCP1252StringEncoding];
    }
    
    if (!stringValue) {
        stringValue = [NSString stringWithCString:filenameBytes
                                         encoding:[NSString defaultCStringEncoding]];
    }
    
    return [stringValue decomposedStringWithCanonicalMapping];
}

+ (NSString *)errorNameForErrorCode:(NSInteger)errorCode
{
    NSString *errorName;
    
    switch (errorCode) {
        case UZKErrorCodeZLibError:
            errorName = NSLocalizedStringFromTableInBundle(@"Error reading/writing file", @"UnzipKit", _resources, @"UZKErrorCodeZLibError");
            break;
            
        case UZKErrorCodeParameterError:
            errorName = NSLocalizedStringFromTableInBundle(@"Parameter error", @"UnzipKit", _resources, @"UZKErrorCodeParameterError");
            break;
            
        case UZKErrorCodeBadZipFile:
            errorName = NSLocalizedStringFromTableInBundle(@"Bad zip file", @"UnzipKit", _resources, @"UZKErrorCodeBadZipFile");
            break;
            
        case UZKErrorCodeInternalError:
            errorName = NSLocalizedStringFromTableInBundle(@"Internal error", @"UnzipKit", _resources, @"UZKErrorCodeInternalError");
            break;
            
        case UZKErrorCodeCRCError:
            errorName = NSLocalizedStringFromTableInBundle(@"The data got corrupted during decompression", @"UnzipKit", _resources, @"UZKErrorCodeCRCError");
            break;
            
        case UZKErrorCodeArchiveNotFound:
            errorName = NSLocalizedStringFromTableInBundle(@"Can't open archive", @"UnzipKit", _resources, @"UZKErrorCodeArchiveNotFound");
            break;
            
        case UZKErrorCodeFileNavigationError:
            errorName = NSLocalizedStringFromTableInBundle(@"Error navigating through the archive", @"UnzipKit", _resources, @"UZKErrorCodeFileNavigationError");
            break;
            
        case UZKErrorCodeFileNotFoundInArchive:
            errorName = NSLocalizedStringFromTableInBundle(@"Can't find a file in the archive", @"UnzipKit", _resources, @"UZKErrorCodeFileNotFoundInArchive");
            break;
            
        case UZKErrorCodeOutputError:
            errorName = NSLocalizedStringFromTableInBundle(@"Error extracting files from the archive", @"UnzipKit", _resources, @"UZKErrorCodeOutputError");
            break;
            
        case UZKErrorCodeOutputErrorPathIsAFile:
            errorName = NSLocalizedStringFromTableInBundle(@"Attempted to extract the archive to a path that is a file, not a directory", @"UnzipKit", _resources, @"UZKErrorCodeOutputErrorPathIsAFile");
            break;
            
        case UZKErrorCodeInvalidPassword:
            errorName = NSLocalizedStringFromTableInBundle(@"Incorrect password provided", @"UnzipKit", _resources, @"UZKErrorCodeInvalidPassword");
            break;
            
        case UZKErrorCodeFileRead:
            errorName = NSLocalizedStringFromTableInBundle(@"Error reading a file in the archive", @"UnzipKit", _resources, @"UZKErrorCodeFileRead");
            break;
            
        case UZKErrorCodeFileOpenForWrite:
            errorName = NSLocalizedStringFromTableInBundle(@"Error opening a file in the archive to write it", @"UnzipKit", _resources, @"UZKErrorCodeFileOpenForWrite");
            break;
            
        case UZKErrorCodeFileWrite:
            errorName = NSLocalizedStringFromTableInBundle(@"Error writing a file in the archive", @"UnzipKit", _resources, @"UZKErrorCodeFileWrite");
            break;
            
        case UZKErrorCodeFileCloseWriting:
            errorName = NSLocalizedStringFromTableInBundle(@"Error clonsing a file in the archive after writing it", @"UnzipKit", _resources, @"UZKErrorCodeFileCloseWriting");
            break;
            
        case UZKErrorCodeDeleteFile:
            errorName = NSLocalizedStringFromTableInBundle(@"Error deleting a file in the archive", @"UnzipKit", _resources, @"UZKErrorCodeDeleteFile");
            break;
            
        case UZKErrorCodeMixedModeAccess:
            errorName = NSLocalizedStringFromTableInBundle(@"Attempted to read before all writes have completed, or vise-versa", @"UnzipKit", _resources, @"UZKErrorCodeMixedModeAccess");
            break;
            
        case UZKErrorCodePreCRCMismatch:
            errorName = NSLocalizedStringFromTableInBundle(@"The CRC given up front doesn't match the calculated CRC", @"UnzipKit", _resources, @"UZKErrorCodePreCRCMismatch");
            break;
            
        case UZKErrorCodeDeflate64:
            errorName = NSLocalizedStringFromTableInBundle(@"The archive was compressed with the Deflate64 method, which isn't supported", @"UnzipKit", _resources, @"UZKErrorCodeDeflate64");
            break;
            
        default:
            errorName = [NSString localizedStringWithFormat:
                         NSLocalizedStringFromTableInBundle(@"Unknown error code: %ld", @"UnzipKit", _resources, @"UnknownErrorCode"), errorCode];
            break;
    }
    
    return errorName;
}

+ (zip_fileinfo)zipFileInfoForDate:(NSDate *)fileDate
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    // Use "now" if no date given
    if (!fileDate) {
        fileDate = [NSDate date];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"

    NSDateComponents *date = [calendar components:(NSCalendarUnitSecond |
                                                   NSCalendarUnitMinute |
                                                   NSCalendarUnitHour |
                                                   NSCalendarUnitDay |
                                                   NSCalendarUnitMonth |
                                                   NSCalendarUnitYear)
                                         fromDate:fileDate];

#pragma clang diagnostic pop

    zip_fileinfo zi;
    zi.tmz_date.tm_sec = (uInt)date.second;
    zi.tmz_date.tm_min = (uInt)date.minute;
    zi.tmz_date.tm_hour = (uInt)date.hour;
    zi.tmz_date.tm_mday = (uInt)date.day;
    zi.tmz_date.tm_mon = (uInt)date.month - 1; // 0-indexed
    zi.tmz_date.tm_year = (uInt)date.year;
    zi.internal_fa = 0;
    zi.external_fa = 0;
    zi.dosDate = 0;
    
    return zi;
}

/**
 *  @return Always returns NO
 */
- (BOOL)assignError:(NSError * __autoreleasing*)error
               code:(NSInteger)errorCode
             detail:(NSString *)errorDetail
{
    return [self assignError:error
                        code:errorCode
                      detail:errorDetail
                   underlyer:nil];
}

/**
 *  @return Always returns NO
 */
- (BOOL)assignError:(NSError * __autoreleasing*)error
               code:(NSInteger)errorCode
             detail:(NSString *)errorDetail
          underlyer:(NSError *)underlyingError
{
    if (error) {
        NSString *errorName = [UZKArchive errorNameForErrorCode:errorCode];
        NSLog(@"UnzipKit error...\nName: %@\nDetail: %@", errorName, errorDetail);
        
        // If this error is being re-wrapped, include the original error
        if (!underlyingError && *error && [*error isKindOfClass:[NSError class]]) {
            underlyingError = *error;
        }
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:
                                         @{NSLocalizedFailureReasonErrorKey: errorName,
                                           NSLocalizedDescriptionKey: errorName,
                                           NSLocalizedRecoverySuggestionErrorKey: errorDetail}];
        
        if (self.fileURL) {
            userInfo[NSURLErrorKey] = self.fileURL;
        }
        
        if (underlyingError) {
            userInfo[NSUnderlyingErrorKey] = underlyingError;
        }
        
        *error = [NSError errorWithDomain:UZKErrorDomain
                                     code:errorCode
                                 userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
    }
    
    return NO;
}

- (BOOL)isDeflate64:(unz_file_info64)file_info
{
    return file_info.compression_method == 9;
}


@end


