[![Build Status](https://travis-ci.org/abbeycode/UnzipKit.svg?branch=master)](https://travis-ci.org/abbeycode/UnzipKit)

# About

UnzipKit is an Objective-C `zlib` wrapper for compressing and decompressing ZIP files on OS X and iOS. It's based on the [AgileBits fork](https://github.com/AgileBits/objective-zip) of [Objective-Zip](http://code.google.com/p/objective-zip/), developed by [Flying Dolphin Studio](http://www.flyingdolphinstudio.com).

It provides the following over Objective-Zip:

* A simpler API, with only a handful of methods, and no incantations to remember
* Full documentation for all methods
* Pervasive use of `NSError`, instead of throwing exceptions

# Example Usage

```Objective-C
UZKArchive *archive = [UZKArchive zipArchiveAtPath:@"An Archive.zip"];

NSError *error = nil;

// Read-only methods

NSArray *filesInArchive = [archive listFilenames:&error];
BOOL extractFilesSuccessful = [archive extractFilesTo:@"some/directory"
                                            overWrite:NO
                                             progress:
    ^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
        NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
    }
                                                error:&error];
NSData *extractedData = [archive extractDataFromFile:@"a file in the archive.jpg"
                                            progress:^(CGFloat percentDecompressed) {
                                                         NSLog(@"Extracting, %f%% complete", percentDecompressed);
                                            }
                                               error:&error];

// Write methods

NSData *someFile = // Some data to write

BOOL writeSuccessful = [archive writeData:someFile
                                 filePath:@"dir/filename.jpg"
                                    error:&error];

uInt crc = (uInt)crc32(0, fileData.bytes, (uInt)fileData.length);
BOOL bufferWriteSuccessful = [archive writeIntoBuffer:@"dir/filename.png"
                                           CRC:crc
                                         error:&writeError
                                         block:
                              ^(BOOL(^writeData)(const void *bytes, unsigned int length)) {
                                  for (NSUInteger i = 0; i <= someFile.length; i += bufferSize) {
                                      unsigned int size = (unsigned int)MIN(someFile.length - i, bufferSize);

                                      if (!writeData(&bytes[i], size)) {
                                          return;
                                      }
                                  }
                              }];

BOOL deleteSuccessful = [archive deleteFile:@"dir/anotherFilename.jpg"
                                      error:&error];
```

# License

* Objective-Zip: [New BSD License](http://www.opensource.org/licenses/bsd-license.php)
* MiniZip: [See MiniZip website](http://www.winimage.com/zLibDll/minizip.html)