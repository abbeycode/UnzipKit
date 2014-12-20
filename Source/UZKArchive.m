//
//  UZKArchive.m
//  UnzipKit
//
//

#import "UZKArchive.h"

#import "zip.h"

#import "UZKFileInfo.h"


NSString *UZKErrorDomain = @"UZKErrorDomain";
#define kMiniZipErrorDomain @"MiniZip error"

#define FILE_IN_ZIP_MAX_NAME_LENGTH (512)


typedef NS_ENUM(NSUInteger, UZKFileMode) {
    UZKFileModeUnzip,
    UZKFileModeCreate,
    UZKFileModeAppend
};



@interface UZKArchive ()

- (instancetype)initWithFile:(NSURL *)fileURL password:(NSString*)password NS_DESIGNATED_INITIALIZER;

@property (strong) NSData *fileBookmark;
@property (strong) NSURL *fallbackURL;

@property (assign) UZKFileMode mode;
@property (assign) zipFile zipFile;
@property (assign) unzFile unzFile;
@property (strong) NSDictionary *archiveContents;

@end


@implementation UZKArchive



#pragma mark - Convenience Methods


+ (UZKArchive *)zipArchiveAtPath:(NSString *)filePath
{
    return [[UZKArchive alloc] initWithFile:[NSURL fileURLWithPath:filePath]];
}

+ (UZKArchive *)zipArchiveAtURL:(NSURL *)fileURL
{
    return [[UZKArchive alloc] initWithFile:fileURL];
}

+ (UZKArchive *)zipArchiveAtPath:(NSString *)filePath password:(NSString *)password
{
    return [[UZKArchive alloc] initWithFile:[NSURL fileURLWithPath:filePath]
                                   password:password];
}

+ (UZKArchive *)zipArchiveAtURL:(NSURL *)fileURL password:(NSString *)password
{
    return [[UZKArchive alloc] initWithFile:fileURL password:password];
}



#pragma mark - Initializers


- (instancetype)initWithFile:(NSURL *)fileURL
{
    return [self initWithFile:fileURL password:nil];
}

- (instancetype)initWithFile:(NSURL *)fileURL password:(NSString*)password
{
    if ((self = [super init])) {
        NSError *error = nil;
        if (![self storeFileBookmark:fileURL error:&error]) {
            NSLog(@"Error creating bookmark to ZIP archive: %@", error);
        }

        self.fallbackURL = fileURL;
        self.password = password;
    }
    
    return self;
}



#pragma mark - Properties


- (NSURL *)fileURL
{
    if (!self.fileBookmark) {
        return self.fallbackURL;
    }
    
    BOOL bookmarkIsStale = NO;
    NSError *error = nil;
    
    NSURL *result = [NSURL URLByResolvingBookmarkData:self.fileBookmark
                                              options:0
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



#pragma mark - Read Methods


- (NSArray *)listFilenames:(NSError **)error
{
    NSArray *zipInfos = [self listFileInfo:error];
    
    if (!zipInfos) {
        return nil;
    }
    
    return [zipInfos valueForKeyPath:@"filename"];
}

- (NSArray *)listFileInfo:(NSError **)error
{
    if (error) {
        *error = nil;
    }
    
    NSError *unzipError;
    
    NSMutableArray *zipInfos = [NSMutableArray array];
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        unzGoToNextFile(self.unzFile);
        
        unz_global_info gi;
        int err = unzGetGlobalInfo(self.unzFile, &gi);
        if (err != UNZ_OK) {
            [self assignError:innerError code:UZKErrorCodeArchiveNotFound];
            return;
        }
        
        NSUInteger fileCount = gi.number_entry;

        err = unzGoToFirstFile(self.unzFile);
        
        if (err != UNZ_OK) {
            [self assignError:innerError code:UZKErrorCodeFileNavigationError];
            return;
        }

        for (NSInteger i = 0; i < fileCount; i++) {
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
                [self assignError:innerError code:UZKErrorCodeFileNavigationError];
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
    
    return [NSArray arrayWithArray:zipInfos];
}

- (BOOL)extractFilesTo:(NSString *)destinationDirectory
             overwrite:(BOOL)overwrite
              progress:(void (^)(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed))progress
                 error:(NSError **)error
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
    
    NSFileManager *fm = [NSFileManager defaultManager];

    NSNumber *totalSize = [fileInfo valueForKeyPath:@"@sum.uncompressedSize"];
    __block long long bytesDecompressed = 0;

    NSError *extractError = nil;
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        for (UZKFileInfo *info in fileInfo) {
            if (progress) {
                progress(info, bytesDecompressed / totalSize.floatValue);
            }
            
            if (![self locateFileInZip:info.filename error:innerError]) {
                [self assignError:innerError code:UZKErrorCodeFileNotFoundInArchive];
                return;
            }
            
            NSString *extractPath = [destinationDirectory stringByAppendingPathComponent:info.filename];
            if ([fm fileExistsAtPath:extractPath] && !overwrite) {
                return;
            }

            NSData *data = [self readFile:info.filename
                                   length:info.uncompressedSize
                                    error:innerError];
            
            int err = unzCloseCurrentFile(self.unzFile);
            if (err != UNZ_OK) {
                if (err == UZKErrorCodeCRCError) {
                    err = UZKErrorCodeInvalidPassword;
                }
                
                [self assignError:innerError code:err];
                return;
            }

            BOOL isDirectory = YES;
            NSString *extractDir = extractPath.stringByDeletingLastPathComponent;
            if (![fm fileExistsAtPath:extractDir]) {
                BOOL directoriesCreated = [fm createDirectoryAtPath:destinationDirectory
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:error];
                if (!directoriesCreated) {
                    NSLog(@"Failed to create destination directory: %@", destinationDirectory);
                    [self assignError:innerError code:UZKErrorCodeOutputError];
                    return;
                }
            } else if (!isDirectory) {
                [self assignError:innerError code:UZKErrorCodeOutputErrorPathIsAFile];
                return;
            }
            
            BOOL writeSuccess = [data writeToFile:extractPath
                                          options:NSDataWritingAtomic
                                            error:innerError];
            if (!writeSuccess) {
                NSLog(@"Failed to extract file to path: %@", extractPath);
                [self assignError:innerError code:UZKErrorCodeOutputError];
                return;
            }

            bytesDecompressed += data.length;
        }
    } inMode:UZKFileModeUnzip error:&extractError];
    
    if (error) {
        *error = extractError ? extractError : nil;
    }

    return success;
}

- (NSData *)extractData:(UZKFileInfo *)fileInfo
               progress:(void (^)(CGFloat))progress
                  error:(NSError **)error
{
    return [self extractDataFromFile:fileInfo.filename
                            progress:progress
                               error:error];
}

- (NSData *)extractDataFromFile:(NSString *)filePath
                       progress:(void (^)(CGFloat))progress
                          error:(NSError **)error
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
                          error:(NSError **)error
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
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        BOOL stop = NO;

        for (UZKFileInfo *info in fileInfo) {
            action(info, &stop);
            
            if (stop) {
                break;
            }
        }
    } inMode:UZKFileModeUnzip error:error];
    
    return success;
}

- (BOOL)performOnDataInArchive:(void (^)(UZKFileInfo *, NSData *, BOOL *))action
                         error:(NSError **)error
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
    
    __block BOOL result = YES;
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        BOOL stop = NO;
        
        for (UZKFileInfo *info in fileInfo) {
            if (![self locateFileInZip:info.filename error:innerError]) {
                [self assignError:innerError code:UZKErrorCodeFileNotFoundInArchive];
                result = NO;
                return;
            }

            NSData *fileData = [self readFile:info.filename
                                       length:info.uncompressedSize
                                        error:error];
            
            if (!fileData) {
                NSLog(@"Error reading file %@ in archive", info.filename);
                [self assignError:innerError code:UZKErrorCodeFileNotFoundInArchive];
                result = NO;
                return;
            }
            
            action(info, fileData, &stop);
            
            if (stop) {
                break;
            }
        }
    } inMode:UZKFileModeUnzip error:error];
    
    return success && result;
}

- (BOOL)extractBufferedDataFromFile:(NSString *)filePath
                              error:(NSError **)error
                             action:(void (^)(NSData *, CGFloat))action
{
    NSUInteger bufferSize = 4096; //Arbitrary
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        if (![self locateFileInZip:filePath error:innerError]) {
            [self assignError:innerError code:UZKErrorCodeFileNotFoundInArchive];
            return;
        }
        
        UZKFileInfo *info = [self currentFileInZipInfo:innerError];
        
        if (!info) {
            NSLog(@"Failed to locate file %@ in zip", filePath);
            return;
        }
        
        if (![self openFile:error]) {
            return;
        }
        
        long long bytesDecompressed = 0;
        
        for (;;)
        {
            @autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
                int bytesRead = unzReadCurrentFile(self.unzFile, data.mutableBytes, (unsigned)bufferSize);
                
                if (bytesRead < 0) {
                    NSLog(@"Failed to read file %@ in zip", info.filename);
                    [self assignError:innerError code:bytesRead];
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
            
            [self assignError:innerError code:err];
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
    
    UZKFileInfo *firstFile = fileInfos.firstObject;
    
    if (!firstFile) {
        return NO;
    }
    
    return firstFile.isEncryptedWithPassword;
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
    
    UZKFileInfo *smallest = [fileInfos sortedArrayUsingComparator:^NSComparisonResult(UZKFileInfo *file1, UZKFileInfo *file2) {
        if (file1.uncompressedSize < file2.uncompressedSize)
            return NSOrderedAscending;
        if (file1.uncompressedSize > file2.uncompressedSize)
            return NSOrderedDescending;
        return NSOrderedSame;
    }].firstObject;

    NSData *smallestData = [self extractData:smallest
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
            error:(NSError **)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:nil
         compressionMethod:UZKCompressionMethodDefault
                  password:nil
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
            error:(NSError **)error
{
    return [self writeData:data
                  filePath:filePath
                  fileDate:fileDate
         compressionMethod:UZKCompressionMethodDefault
                  password:nil
                     error:error];
}

- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(NSString *)password
            error:(NSError **)error
{
    if (![self deleteFile:filePath error:error]) {
        NSLog(@"Failed to delete %@ before writing new data for it", filePath);
        return NO;
    }

    if (!password) {
        password = self.password;
    }
    
    BOOL success = [self performActionWithArchiveOpen:^(NSError **innerError) {
        zip_fileinfo zi = [UZKArchive zipFileInfoForDate:fileDate];
        
        const char *passwordStr = NULL;
        
        if (self.password) {
            passwordStr = password.UTF8String;
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
                                       (uInt)crc32(0, data.bytes, (uInt)data.length));
        
        if (err != ZIP_OK) {
            NSLog(@"Error opening file for write: %@, %d", filePath, err);
            [self assignError:innerError code:UZKErrorCodeFileOpenForWrite];
            return;
        }
        
        err = zipWriteInFileInZip(self.zipFile, data.bytes, (uInt)data.length);
        if (err < 0) {
            NSLog(@"Error writing file: %@, %d", filePath, err);
            [self assignError:innerError code:UZKErrorCodeFileWrite];
            return;
        }
        
        err = zipCloseFileInZip(self.zipFile);
        if (err != ZIP_OK) {
            NSLog(@"Error closing file for write: %@, %d", filePath, err);
            [self assignError:innerError code:UZKErrorCodeFileWrite];
            return;
        }
        
    } inMode:UZKFileModeAppend error:error];
    
    return success;
}



#pragma mark - Private Methods


- (BOOL)performActionWithArchiveOpen:(void(^)(NSError **innerError))action
                              inMode:(UZKFileMode)mode
                               error:(NSError **)error
{
    if (error) {
        *error = nil;
    }
    
    if (![self openFile:self.filename
                 inMode:mode
           withPassword:self.password
                  error:error]) {
        return NO;
    }
    
    NSError *actionError = nil;
    
    @try {
        action(&actionError);
    }
    @finally {
        NSError *closeError = nil;
        if (![self closeFile:&closeError]) {
            if (error && !actionError) {
                *error = closeError;
            }
            
            return NO;
        }
    }
    
    if (error && actionError) {
        *error = actionError;
    }

    return !actionError;
}

- (BOOL)openFile:(NSString *)zipFile
          inMode:(UZKFileMode)mode
    withPassword:(NSString *)aPassword
           error:(NSError **)error
{
    if (error) {
        *error = nil;
    }
    
    self.mode = mode;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    switch (mode) {
        case UZKFileModeUnzip: {
            if (![fm fileExistsAtPath:zipFile]) {
                [self assignError:error code:UZKErrorCodeArchiveNotFound];
                return NO;
            }
            
            self.unzFile = unzOpen(self.filename.UTF8String);
            if (self.unzFile == NULL) {
                [self assignError:error code:UZKErrorCodeBadZipFile];
                return NO;
            }
            
            int err = unzGoToFirstFile(self.unzFile);
            if (err != UNZ_OK) {
                [self assignError:error code:UZKErrorCodeFileNavigationError];
                return NO;
            }
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            
            do {
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
            } while (unzGoToNextFile (self.unzFile) != UNZ_END_OF_LIST_OF_FILE);
            
            self.archiveContents = [NSDictionary dictionaryWithDictionary:dic];
            break;
        }
        case UZKFileModeCreate:
        case UZKFileModeAppend:
            if (![fm fileExistsAtPath:zipFile]) {
                [fm createFileAtPath:zipFile contents:nil attributes:nil];
                
                NSError *bookmarkError = nil;
                if (![self storeFileBookmark:[NSURL fileURLWithPath:zipFile]
                                       error:&bookmarkError]) {
                    NSLog(@"Error creating new file for archive %@, %@", zipFile, bookmarkError);
                    
                    if (error) {
                        *error = bookmarkError;
                    }
                    
                    return NO;
                }
            }
            
            int appendStatus = mode == UZKFileModeCreate ? APPEND_STATUS_CREATE : APPEND_STATUS_ADDINZIP;
            
            self.zipFile = zipOpen(self.filename.UTF8String, appendStatus);
            if (self.zipFile == NULL) {
                [self assignError:error code:UZKErrorCodeArchiveNotFound];
                return NO;
            }
            break;

        default:
            [NSException raise:@"Invalid UZKArchive openFile mode"
                        format:@"Unknown mode: %lu for file: %@", mode, self.filename];
    }
    
    return YES;
}

- (BOOL)closeFile:(NSError **)error
{
    int err;
    
    switch (self.mode) {
        case UZKFileModeUnzip:
            err = unzClose(self.unzFile);
            if (err != UNZ_OK) {
                [self assignError:error code:UZKErrorCodeZLibError];
                return NO;
            }
            break;

        case UZKFileModeCreate:
            err = zipClose(self.zipFile, NULL);
            if (err != ZIP_OK) {
                [self assignError:error code:UZKErrorCodeZLibError];
                return NO;
            }
            break;

        case UZKFileModeAppend:
            err= zipClose(self.zipFile, NULL);
            if (err != ZIP_OK) {
                [self assignError:error code:UZKErrorCodeZLibError];
                return NO;
            }
            break;

        default:
            [NSException raise:@"Invalid UZKArchive closeFile mode"
                        format:@"Unknown mode: %lu for file: %@", self.mode, self.filename];
    }
    
    self.mode = -1;
    return YES;
}



#pragma mark - Zip File Navigation


- (UZKFileInfo *)currentFileInZipInfo:(NSError **)error {
    char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
    unz_file_info file_info;
    
    int err = unzGetCurrentFileInfo(self.unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
    if (err != UNZ_OK) {
        [self assignError:error code:UZKErrorCodeArchiveNotFound];
        return nil;
    }
    
    NSString *filename = [UZKArchive figureOutFilename:filename_inzip];
    return [UZKFileInfo fileInfo:&file_info filename:filename];
}

- (BOOL)locateFileInZip:(NSString *)fileNameInZip error:(NSError **)error {
    NSValue *filePosValue = self.archiveContents[fileNameInZip.decomposedStringWithCanonicalMapping];
    
    if (!filePosValue) {
        return [self assignError:error code:UZKErrorCodeFileNotFoundInArchive];
    }
    
    unz_file_pos pos;
    [filePosValue getValue:&pos];
    
    int err = unzGoToFilePos(self.unzFile, &pos);
    
    if (err == UNZ_END_OF_LIST_OF_FILE) {
        return [self assignError:error code:UZKErrorCodeFileNotFoundInArchive];
    }

    if (err != UNZ_OK) {
        return [self assignError:error code:err];
    }
    
    return YES;
}



#pragma mark - Zip File Operations


- (BOOL)openFile:(NSError **)error
{
    char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
    unz_file_info file_info;
    
    int err = unzGetCurrentFileInfo(self.unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
    if (err != UNZ_OK) {
        return [self assignError:error code:UZKErrorCodeInternalError];
    }
    
    const char *passwordStr = NULL;
    
    if (self.password) {
        passwordStr = self.password.UTF8String;
    }
    
    err = unzOpenCurrentFilePassword(self.unzFile, passwordStr);
    if (err != UNZ_OK) {
        return [self assignError:error code:UZKErrorCodeFileRead];
    }
    
    return YES;
}


- (NSData *)readFile:(NSString *)filePath length:(NSUInteger)length error:(NSError **)error {
    if (![self openFile:error]) {
        return nil;
    }
    
    NSMutableData *data = [NSMutableData dataWithLength:length];
    int bytes = unzReadCurrentFile(self.unzFile, data.mutableBytes, (unsigned)length);
    
    if (bytes < 0) {
        [self assignError:error code:bytes];
        return nil;
    }
    
    data.length = bytes;
    return data;
}

- (BOOL)deleteFile:(NSString *)filePath error:(NSError **)error
{
    // Thanks to Ivan A. Krestinin for much of the code below: http://www.winimage.com/zLibDll/del.cpp
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:self.filename]) {
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
        NSLog(@"Error opening the source file while deleting %@", filePath);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    zipFile destZip = zipOpen(tempFilename, APPEND_STATUS_CREATE);
    if (destZip == NULL) {
        unzClose(sourceZip);
        NSLog(@"Error opening the destination file while deleting %@", filePath);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    // Get global commentary
    
    unz_global_info globalInfo;
    int err = unzGetGlobalInfo(sourceZip, &globalInfo);
    if (err != UNZ_OK) {
        zipClose(destZip, NULL);
        unzClose(sourceZip);
        NSLog(@"Error getting the global info of the source file while deleting %@", filePath);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    char *globalComment = NULL;
    
    if (globalInfo.size_comment > 0)
    {
        globalComment = (char*)malloc(globalInfo.size_comment+1);
        if ((globalComment == NULL) && (globalInfo.size_comment != 0)) {
            zipClose(destZip, NULL);
            unzClose(sourceZip);
            NSLog(@"Error reading the global comment of the source file while deleting %@", filePath);
            return [self assignError:error code:UZKErrorCodeDeleteFile];
        }
        
        if ((unsigned int)unzGetGlobalComment(sourceZip, globalComment, globalInfo.size_comment + 1) != globalInfo.size_comment) {
            zipClose(destZip, NULL);
            unzClose(sourceZip);
            free(globalComment);
            NSLog(@"Error reading the global comment of the source file while deleting %@ (wrong size)", filePath);
            return [self assignError:error code:UZKErrorCodeDeleteFile];
        }
    }
    
    BOOL noFilesDeleted = YES;
    int filesCopied = 0;
    
    NSString *filenameToDelete = [UZKArchive figureOutFilename:del_file];
    
    int nextFileReturnValue = unzGoToFirstFile(sourceZip);
    
    while (nextFileReturnValue == UNZ_OK)
    {
        // Get zipped file info
        char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
        unz_file_info unzipInfo;
        
        err = unzGetCurrentFileInfo(sourceZip, &unzipInfo, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
        if (err != UNZ_OK) {
            NSLog(@"Error getting file info of file while deleting %@", filePath);
            return [self assignError:error code:UZKErrorCodeDeleteFile];
        }

        NSString *currentFileName = [UZKArchive figureOutFilename:filename_inzip];

        // if not need delete this file
        if ([filenameToDelete isEqualToString:currentFileName.decomposedStringWithCanonicalMapping])
            noFilesDeleted = NO;
        else
        {
            char *extrafield = (char*)malloc(unzipInfo.size_file_extra);
            if ((extrafield == NULL) && (unzipInfo.size_file_extra != 0)) {
                NSLog(@"Error allocating extrafield info of %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            char *commentary = (char*)malloc(unzipInfo.size_file_comment);
            if ((commentary == NULL) && (unzipInfo.size_file_comment != 0)) {
                free(extrafield);
                NSLog(@"Error allocating commentary info of %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            err = unzGetCurrentFileInfo(sourceZip, &unzipInfo, filename_inzip, FILE_IN_ZIP_MAX_NAME_LENGTH, extrafield, unzipInfo.size_file_extra, commentary, unzipInfo.size_file_comment);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                NSLog(@"Error reading extrafield and commentary info of %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // Open source archive for raw reading
            
            int method;
            int level;
            err = unzOpenCurrentFile2(sourceZip, &method, &level, 1);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                NSLog(@"Error opening %@ for raw reading while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            int size_local_extra = unzGetLocalExtrafield(sourceZip, NULL, 0);
            if (size_local_extra < 0) {
                free(extrafield);
                free(commentary);
                NSLog(@"Error getting size_local_extra for file %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            void *local_extra = malloc(size_local_extra);
            if ((local_extra == NULL) && (size_local_extra != 0)) {
                free(extrafield);
                free(commentary);
                NSLog(@"Error allocating local_extra for file %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            if (unzGetLocalExtrafield(sourceZip, local_extra, size_local_extra) < 0) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                NSLog(@"Error getting local_extra for file %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // This malloc may fail if file very large
            void *buf = malloc(unzipInfo.compressed_size);
            if ((buf == NULL) && (unzipInfo.compressed_size != 0)) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                NSLog(@"Error allocating buffer for file %@ while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // Read file
            int size = unzReadCurrentFile(sourceZip, buf, (uInt)unzipInfo.compressed_size);
            if ((unsigned int)size != unzipInfo.compressed_size) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                NSLog(@"Error reading %@ into buffer while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
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
                NSLog(@"Error opening %@ in destination zip while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // Write file
            err = zipWriteInFileInZip(destZip, buf, (uInt)unzipInfo.compressed_size);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                NSLog(@"Error writing %@ to destination zip while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // Close destination archive
            err = zipCloseFileInZipRaw(destZip, unzipInfo.uncompressed_size, unzipInfo.crc);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                NSLog(@"Error closing %@ in destination zip while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
            }
            
            // Close source archive
            err = unzCloseCurrentFile(sourceZip);
            if (err != UNZ_OK) {
                free(extrafield);
                free(commentary);
                free(local_extra);
                free(buf);
                NSLog(@"Error closing %@ in source zip while deleting %@", currentFileName, filePath);
                return [self assignError:error code:UZKErrorCodeDeleteFile];
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
        NSLog(@"Failed to seek to the next file, while deleting %@ from the archive", filenameToDelete);
        remove(tempFilename);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    // Replace old file with the new (trimmed) one
    NSError *replaceError = nil;
    NSURL *newURL;
    
    BOOL result = [fm replaceItemAtURL:self.fileURL
                         withItemAtURL:temporaryURL
                        backupItemName:nil
                               options:NSFileManagerItemReplacementWithoutDeletingBackupItem
                      resultingItemURL:&newURL
                                 error:&replaceError];
    
    if (!result)
    {
        NSLog(@"Failed to replace the old archive with the new one, after deleting %@ from it", filenameToDelete);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    NSError *bookmarkError = nil;
    if (![self storeFileBookmark:newURL
                           error:&bookmarkError])
    {
        NSLog(@"Failed to store the new file bookmark to the archive after deleting %@ from it", filenameToDelete);
        return [self assignError:error code:UZKErrorCodeDeleteFile];
    }
    
    return YES;
}



#pragma mark - Misc. Private Methods


- (BOOL)storeFileBookmark:(NSURL *)fileURL error:(NSError **)error
{
    NSError *bookmarkError = nil;
    self.fileBookmark = [fileURL bookmarkDataWithOptions:0
                          includingResourceValuesForKeys:@[]
                                           relativeToURL:nil
                                                   error:&bookmarkError];
    
    if (error) {
        *error = bookmarkError ? bookmarkError : nil;
    }
    
    return bookmarkError == nil;
}

+ (NSString *)figureOutFilename:(const char *)filenameBytes
{
    NSString *name = [NSString stringWithUTF8String:filenameBytes];
    
    if (!name) {
        name = [NSString stringWithCString:filenameBytes
                                  encoding:NSWindowsCP1252StringEncoding];
    }
    
    if (!name) {
        name = [NSString stringWithCString:filenameBytes
                                  encoding:[NSString defaultCStringEncoding]];
    }
    
    return [name decomposedStringWithCanonicalMapping];
}

+ (NSString *)errorNameForErrorCode:(UZKErrorCode)errorCode
{
    NSString *errorName;
    
    switch (errorCode) {
        case UZKErrorCodeZLibError:
            errorName = NSLocalizedString(@"Error reading/writing file", @"UZKErrorCodeZLibError");
            break;
            
        case UZKErrorCodeParameterError:
            errorName = NSLocalizedString(@"Parameter error", @"UZKErrorCodeParameterError");
            break;
            
        case UZKErrorCodeBadZipFile:
            errorName = NSLocalizedString(@"Bad zip file", @"UZKErrorCodeBadZipFile");
            break;
            
        case UZKErrorCodeInternalError:
            errorName = NSLocalizedString(@"Internal error", @"UZKErrorCodeInternalError");
            break;
            
        case UZKErrorCodeCRCError:
            errorName = NSLocalizedString(@"The data got corrupted during decompression",
                                          @"UZKErrorCodeCRCError");
            break;
            
        case UZKErrorCodeArchiveNotFound:
            errorName = NSLocalizedString(@"Can't open archive", @"UZKErrorCodeArchiveNotFound");
            break;
            
        case UZKErrorCodeFileNavigationError:
            errorName = NSLocalizedString(@"Error navigating through the archive",
                                          @"UZKErrorCodeFileNavigationError");
            break;
            
        case UZKErrorCodeFileNotFoundInArchive:
            errorName = NSLocalizedString(@"Can't find a file in the archive",
                                          @"UZKErrorCodeFileNotFoundInArchive");
            break;
            
        case UZKErrorCodeOutputError:
            errorName = NSLocalizedString(@"Error extracting files from the archive",
                                          @"UZKErrorCodeOutputError");
            break;
            
        case UZKErrorCodeOutputErrorPathIsAFile:
            errorName = NSLocalizedString(@"Attempted to extract the archive to a path that is a file, not a directory",
                                          @"UZKErrorCodeOutputErrorPathIsAFile");
            break;
            
        case UZKErrorCodeInvalidPassword:
            errorName = NSLocalizedString(@"Incorrect password provided",
                                          @"UZKErrorCodeInvalidPassword");
            break;
            
        case UZKErrorCodeFileRead:
            errorName = NSLocalizedString(@"Error reading a file in the archive",
                                          @"UZKErrorCodeFileRead");
            break;
            
        case UZKErrorCodeFileOpenForWrite:
            errorName = NSLocalizedString(@"Error opening a file in the archive to write it",
                                          @"UZKErrorCodeFileOpenForWrite");
            break;
            
        case UZKErrorCodeFileWrite:
            errorName = NSLocalizedString(@"Error writing a file in the archive",
                                          @"UZKErrorCodeFileWrite");
            break;
            
        case UZKErrorCodeFileCloseWriting:
            errorName = NSLocalizedString(@"Error clonsing a file in the archive after writing it",
                                          @"UZKErrorCodeFileCloseWriting");
            break;
            
        case UZKErrorCodeDeleteFile:
            errorName = NSLocalizedString(@"Error deleting a file in the archive",
                                          @"UZKErrorCodeDeleteFile");
            break;
            
        default:
            errorName = [NSString localizedStringWithFormat:
                         NSLocalizedString(@"Unknown error code: %ld", @"UnknownErrorCode"), errorCode];
            break;
    }
    
    return errorName;
}

+ (zip_fileinfo)zipFileInfoForDate:(NSDate *)fileDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Use "now" if no date given
    if (!fileDate) {
        fileDate = [NSDate date];
    }
    
    NSDateComponents *date = [calendar components:(NSCalendarUnitSecond |
                                                   NSCalendarUnitMinute |
                                                   NSCalendarUnitHour |
                                                   NSCalendarUnitDay |
                                                   NSCalendarUnitMonth |
                                                   NSCalendarUnitYear)
                                         fromDate:fileDate];
    zip_fileinfo zi;
    zi.tmz_date.tm_sec = (uInt)date.second;
    zi.tmz_date.tm_min = (uInt)date.minute;
    zi.tmz_date.tm_hour = (uInt)date.hour;
    zi.tmz_date.tm_mday = (uInt)date.day;
    zi.tmz_date.tm_mon = (uInt)date.month - 1;
    zi.tmz_date.tm_year = (uInt)date.year;
    zi.internal_fa = 0;
    zi.external_fa = 0;
    zi.dosDate = 0;
    
    return zi;
}

/**
 *  @return Always returns NO
 */
- (BOOL)assignError:(NSError **)error code:(NSInteger)errorCode
{
    if (error) {
        NSString *errorName = [UZKArchive errorNameForErrorCode:errorCode];
        
        *error = [NSError errorWithDomain:UZKErrorDomain
                                     code:errorCode
                                 userInfo:@{NSLocalizedFailureReasonErrorKey: errorName}];
    }
    
    return NO;
}


@end
