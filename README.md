[![Build Status](https://travis-ci.org/abbeycode/UnzipKit.svg?branch=master)](https://travis-ci.org/abbeycode/UnzipKit)
[![Documentation Coverage](https://img.shields.io/cocoapods/metrics/doc-percent/UnzipKit.svg)](http://cocoadocs.org/docsets/UnzipKit)

# About

UnzipKit is an Objective-C `zlib` wrapper for compressing and decompressing Zip files on OS X and iOS. It's based on the [AgileBits fork](https://github.com/AgileBits/objective-zip) of [Objective-Zip](http://code.google.com/p/objective-zip/), developed by [Flying Dolphin Studio](http://www.flyingdolphinstudio.com).

It provides the following over Objective-Zip:

* A simpler API, with only a handful of methods, and no incantations to remember
* The ability to delete files in an archive, including overwriting an existing file
* Pervasive use of blocks, making iteration and progress reporting simple to use
* Full documentation for all methods
* Pervasive use of `NSError`, instead of throwing exceptions

# Installation

UnzipKit supports both [CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage). CocoaPods does not support dynamic framework targets (as of v0.39.0), so in that case, please use Carthage.

Cartfile:

    github "abbeycode/UnzipKit"

Podfile:

    pod "UnzipKit"

# Deleting files

Using the method `-deleteFile:error:` currently creates a new copy of the archive in a temporary location, without the deleted file, then replaces the original archive. By default, all methods to write data perform a delete on the file name they write before archiving the new data. You can turn this off by calling the overload with an `overwrite` argument, setting it to `NO`. This will not remove the original copy of that file, though, causing the archive to grow with each write of the same file name.

If that's not a concern, such as when creating a new archive from scratch, it would improve performance, particularly for archives with a large number of files.

```Objective-C
NSError *archiveError = nil;
UZKArchive *archive = [UZKArchive zipArchiveAtPath:@"An Archive.zip" error:&archiveError];
BOOL deleteSuccessful = [archive deleteFile:@"dir/anotherFilename.jpg"
                                      error:&error];
```

# Detecting Zip files

You can quickly and efficiently check whether a file at a given path or URL is a Zip archive:

```Objective-C
BOOL fileAtPathIsArchive = [UZKArchive pathIsAZip:@"some/file.zip"];

NSURL *url = [NSURL fileURLWithPath:@"some/file.zip"];
BOOL fileAtURLIsArchive = [UZKArchive urlIsAZip:url];
```

# Reading Zip contents

```Objective-C
NSError *archiveError = nil;
UZKArchive *archive = [UZKArchive zipArchiveAtPath:@"An Archive.zip" error:&archiveError];
NSError *error = nil;
```

You can use UnzipKit to perform these read-only operations:

* List the contents of the archive

    ```Objective-C
NSArray<NSString*> *filesInArchive = [archive listFilenames:&error];
    ```
* Extract all files to disk

    ```Objective-C
BOOL extractFilesSuccessful = [archive extractFilesTo:@"some/directory"
                                                overWrite:NO
                                                 progress:
    ^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
        NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
    }
                                                    error:&error];
    ```

* Extract each archived file into memory

    ```Objective-C
NSData *extractedData = [archive extractDataFromFile:@"a file in the archive.jpg"
                                                progress:^(CGFloat percentDecompressed) {
                                                             NSLog(@"Extracting, %f%% complete", percentDecompressed);
                                                }
                                                   error:&error];
    ```

# Modifying archives

```Objective-C
NSError *archiveError = nil;
UZKArchive *archive = [UZKArchive zipArchiveAtPath:@"An Archive.zip" error:&archiveError];
NSError *error = nil;
NSData *someFile = // Some data to write
```

You can also modify Zip archives:

* Write an in-memory `NSData` into the archive

    ```Objective-C
BOOL success = [archive writeData:someFile
                             filePath:@"dir/filename.jpg"
                                error:&error];
    ```
* Write data as a stream to the archive (from disk or over the network), using a block:

    ```Objective-C
BOOL success = [archive writeIntoBuffer:@"dir/filename.png"
                                  error:&error
                                  block:
                ^BOOL(BOOL(^writeData)(const void *bytes, unsigned int length), NSError**(actionError)) {
                    for (NSUInteger i = 0; i <= someFile.length; i += bufferSize) {
                        const void *bytes = // some data
                        unsigned int length = // length of data

                        if (/* Some error occurred reading the data */) {
                            *actionError = // Any error that was produced, or make your own
                            return NO;
                        }

                        if (!writeData(&bytes, length)) {
                            return NO;
                        }
                    }

                    return YES;
                }];
    ```
* Delete files from the archive

    ```Objective-C
BOOL success = [archive deleteFile:@"No-good-file.txt" error:&error];
    ```
# Documentation

Full documentation for the project is available on [CocoaDocs](http://cocoadocs.org/docsets/UnzipKit).

# Pushing a new CocoaPods version

New tagged builds (in any branch) get pushed to CocoaPods automatically, provided they meet the following criteria:

1. All builds and tests succeed
2. The library builds successfully for CocoaPods and for Carthage
3. The build is tagged with something resembling a version number (`#.#.#(-beta#)`, e.g. **2.9** or **2.9-beta5**)
4. `pod spec lint` passes, making sure the CocoaPod is 100% valid

Before pushing a build, you must:

1. Add the release notes to the [CHANGELOG.md](CHANGELOG.md), and commit
2. Run [set-version](Scripts/set-version.sh), like so:
     
    `./Scripts/set-version.sh <version number>`
    
    This does the following:
    
    1. Updates the various Info.plist files to indicate the new version number, and commits them
    2. Makes an annotated tag whose message contains the release notes entered in Step 1

Once that's done, you can call `git push --follow-tags` [<sup id=a1>1</sup>](#f1), and let [Travis CI](https://travis-ci.org/abbeycode/UnrarKit/builds) take care of the rest. 

# License

* UnzipKit: [See LICENSE (BSD)](LICENSE)
* MiniZip: [See MiniZip website](http://www.winimage.com/zLibDll/minizip.html)



<hr>

<span id="f1">1</span>: Or set `followTags = true` in your git config to always get this behavior:

    git config --global push.followTags true

[↩](#a1)