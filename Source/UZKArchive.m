//
//  UZKArchive.m
//  UnzipKit
//
//

#import "UZKArchive.h"


@interface UZKArchive ()

@property (strong) NSData *fileBookmark;

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


- (id)initWithFile:(NSURL *)fileURL
{
    if ((self = [super init])) {
        NSError *error = nil;
        self.fileBookmark = [fileURL bookmarkDataWithOptions:0
                              includingResourceValuesForKeys:@[]
                                               relativeToURL:nil
                                                       error:&error];
        
        if (error) {
            NSLog(@"Error creating bookmark to ZIP archive: %@", error);
        }
    }
    
    return self;
}

- (id)initWithFile:(NSURL *)fileURL password:(NSString*)password
{
    if ((self = [self initWithFile:fileURL])) {
        self.password = password;
    }
    
    return self;
}



#pragma mark - Properties


- (NSURL *)fileURL
{
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
        self.fileBookmark = [result bookmarkDataWithOptions:0
                             includingResourceValuesForKeys:@[]
                                              relativeToURL:nil
                                                      error:&error];
        
        if (error) {
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


@end
