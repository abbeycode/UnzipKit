//
//  UZKFileInfo.m
//  UnzipKit
//
//

#import "UZKFileInfo.h"
#import "unzip.h"

/**
 *  Define the file storage system in zip according to "version made by"
 *  - Currently defined are two general two version field,
 *    more version field references are available from
 *    https://www.pkware.com/documents/casestudies/APPNOTE.TXT 4.4.2.1
 */
typedef NS_ENUM(NSUInteger, UZKZipOS) {
    
    UZKZipOSMSDOS = 0,
    UZKZipOSAmiga = 1,
    UZKZipOSOpenVMS = 2,
    UZKZipOSUnix = 3,
    UZKZipOSVMCMS = 4,
    UZKZipOSAtariST = 5,
    UZKZipOSOS2 = 6,
    UZKZipOSClassicMac = 7,
    UZKZipOSZSystem = 8,
    UZKZipOSCPM = 9,
    UZKZipOSWindowsNT = 10,
    UZKZipOSMVS = 11,
    UZKZipOSVSE = 12,
    UZKZipOSAcorn = 13,
    UZKZipOSVFAT = 14,
    UZKZipOSAlternateMVS = 15,
    UZKZipOSBeOS = 16,
    UZKZipOSTandem = 17,
    UZKZipOSOS400 = 18,
    UZKZipOSDarwin = 19
};


@interface UZKFileInfo ()

@property (readwrite) tm_unz zipTMUDate;

@end


@implementation UZKFileInfo

@synthesize timestamp = _timestamp;


#pragma mark - Initialization


+ (instancetype) fileInfo:(unz_file_info64 *)fileInfo filename:(NSString *)filename {
    return [[UZKFileInfo alloc] initWithFileInfo:fileInfo filename:filename];
}

- (instancetype)initWithFileInfo:(unz_file_info64 *)fileInfo filename:(NSString *)filename
{
    if ((self = [super init])) {
        _filename = filename;
        _uncompressedSize = fileInfo->uncompressed_size;
        _compressedSize = fileInfo->compressed_size;
        _zipTMUDate = fileInfo->tmu_date;
        _CRC = fileInfo->crc;
        _isEncryptedWithPassword = (fileInfo->flag & 1) != 0;
        _isDirectory = [UZKFileInfo itemIsDirectory:fileInfo];
        _isSymbolicLink = [UZKFileInfo itemIsSymbolicLink:fileInfo];
        
        if (_isDirectory) {
            _filename = [_filename substringToIndex:_filename.length - 1];
        }
        
        _compressionMethod = [self readCompressionMethod:fileInfo->compression_method
                                                    flag:fileInfo->flag];
        
        uLong permissions = (fileInfo->external_fa >> 16) & 0777U;
        _posixPermissions = permissions ? permissions : 0644U;
    }
    return self;
}


#pragma mark - Private Class Methods


+ (BOOL)itemIsDirectory:(unz_file_info64 *)fileInfo {
    UZKZipOS zipOSClassMapping = fileInfo->version >> 8;
    if (zipOSClassMapping == UZKZipOSMSDOS || zipOSClassMapping == UZKZipOSWindowsNT) {
        return 0x01 == (fileInfo->external_fa >> 4) && ![UZKFileInfo itemIsSymbolicLink:fileInfo];
    }
    
    return S_IFDIR == (S_IFMT & fileInfo->external_fa >> 16) && ![UZKFileInfo itemIsSymbolicLink:fileInfo];
}

+ (BOOL)itemIsSymbolicLink:(unz_file_info64 *)fileInfo {
    return S_IFLNK == (S_IFMT & fileInfo->external_fa >> 16);
}


#pragma mark - Properties


- (NSDate *)timestamp {
    if (!_timestamp) {
        _timestamp = [self readDate:self.zipTMUDate];
    }
    
    return _timestamp;
}


#pragma mark - Private Methods


- (UZKCompressionMethod)readCompressionMethod:(uLong)compressionMethod
                                         flag:(uLong)flag
{
    UZKCompressionMethod level = UZKCompressionMethodNone;
    if (compressionMethod != 0) {
        switch ((flag & 0x6) / 2) {
            case 0:
                level = UZKCompressionMethodDefault;
                break;
                
            case 1:
                level = UZKCompressionMethodBest;
                break;
                
            default:
                level = UZKCompressionMethodFastest;
                break;
        }
    }
    
    return level;
}

- (NSDate *)readDate:(tm_unz)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day    = date.tm_mday;
    components.month  = date.tm_mon + 1;
    components.year   = date.tm_year;
    components.hour   = date.tm_hour;
    components.minute = date.tm_min;
    components.second = date.tm_sec;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    return [calendar dateFromComponents:components];
}

@end
