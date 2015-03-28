[![Build Status](https://travis-ci.org/abbeycode/UnzipKit.svg?branch=master)](https://travis-ci.org/abbeycode/UnzipKit)

# About

UnzipKit is an Objective-C `zlib` wrapper for compressing and decompressing Zip files on OS X and iOS. It's based on the [AgileBits fork](https://github.com/AgileBits/objective-zip) of [Objective-Zip](http://code.google.com/p/objective-zip/), developed by [Flying Dolphin Studio](http://www.flyingdolphinstudio.com).

It provides the following over Objective-Zip:

* A simpler API, with only a handful of methods, and no incantations to remember
* The ability to delete files in an archive, including overwriting an existing file
* Pervasive use of blocks, making iteration and progress reporting simple to use
* Full documentation for all methods
* Pervasive use of `NSError`, instead of throwing exceptions

# Deleting files

Using the method `-deleteFile:error:` currently creates a new copy of the archive in a temporary location, without the deleted file, then replaces the original archive. By default, all methods to write data perform a delete on the file name they write before archiving the new data. You can turn this off by calling the overload with an `overwrite` argument, setting it to `NO`. This will not remove the original copy of that file, though, causing the archive to grow with each write of the same file name.

If that's not a concern, such as when creating a new archive from scratch, it would improve performance, particularly for archives with a large number of files.

# Reading Zip contents

You can use UnzipKit to:

* List the contents of the archive
* Extract all files to disk
* Extract each archived file into memory

```Objective-C
UZKArchive *archive = [UZKArchive zipArchiveAtPath:@"An Archive.zip"];

NSError *error = nil;

NSArray *filesInArchive = [archive listFilenames:&error];
BOOL extractFilesSuccessful = [archive extractFilesTo:@"some/directory"
                                            overWrite:NO
                                             progress:
    ^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
        NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
    }
                                                error:&error];
NSData *extractedData = [archive extractDataFromFile:@"a file in the archive.jpg"
                                            progress:^(CGFloat percentDecompressed) {
                                                         NSLog(@"Extracting, %f%% complete", percentDecompressed);
                                            }
                                               error:&error];
```

# Writing to archives

You can also write data to Zip archives:

* You can write an `NSData` into the archive
* Write data as a stream to the archive, using a block
* Delete files from the archive

```Objective-C
NSData *someFile = // Some data to write

BOOL writeSuccessful = [archive writeData:someFile
                                 filePath:@"dir/filename.jpg"
                                    error:&error];

uInt crc = (uInt)crc32(0, someFile.bytes, (uInt)someFile.length);
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

* UnzipKit: [See LICENSE (BSD)](LICENSE)
* MiniZip: [See MiniZip website](http://www.winimage.com/zLibDll/minizip.html)