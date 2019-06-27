# UnzipKit CHANGELOG

## 1.9

* Added support for `NSProgress` and `NSProgressReporting` in all extraction and iteration methods (Issue #32)
* Added detailed logging using new unified logging framework. See [the readme](README.md) for more details (Issue #47)
* Added support for archiving and restoring files' POSIX permissions (PRs #84, #86, #87 - Thanks, [@MartinLau7](https://github.com/MartinLau7)!)
* Added methods to check data integrity of an individual archived file, or the entire archive (Issue #63)
* Fixed a crasher in `extractBufferedDataFromFile:error:action:`, which also manifested in other methods that use it, like `validatePassword` (Issue #51 - Thanks, [@amosavian](https://github.com/amosavian), [@monobono](https://github.com/monobono), and [@segunlee](https://github.com/segunlee)!)
* Upgraded project to Xcode 9 and to the macOS 10.13 and iOS 11 SDKs (Issue #61)
* Consolidated targets so they're shared between iOS and macOS (Issue #62)
* Added a CocoaPods test spec (Issue #59)
* Improved the way warnings are ignored to be more consistent, and so they're only ignored in `minizip`, and not the UnzipKit sources (Issue #68)

## 1.8.5

* Fixed issues with localization (again, again) (Issue #42). Thanks, @stevenp!

## 1.8.4

* Updated to Xcode 8 (Issue #50)
* Fixed issues with localization (again) (Issue #42). Thanks, @ConfusedVorlon and @tomjpsun!

## 1.8.3

* Fixed bug in iOS framework target causing a framework bundle not to be produced (Issue #48 – Thanks, @amosavian!)
* Added CI automation to release tagged successful builds to CocoaPods from Travis (Issue #49)

## 1.8.2

Fixed issues with localization, that could affect submission through iTunes Connect (Issue #42)

## 1.8.1

* Added checking whether a file is compressed with the Deflate64 method, and returning a specific error code for that unsupported format (Issue #37)
* Fixed internationalization, laying the groundwork for non-US-English localization in the future. If you use UnzipKit from Carthage or CocoaPods, and run your app using the "Show non-localized strings" option, UnzipKit's strings should no longer display as all-cap (Issue #38)

## 1.8

Fixed a bug causing delete operations (including writing updated data with the `overwrite` flag set to true) to fail when the archive resides on an external volume (Issue #36)

## 1.7.2

Fixed the nullability attributes of the 'password' argument in the UZKArchive intitializers (Issue #34 - Thanks, Mohammad!)

## 1.7.1

Fixed a bug causing the UZKErrorDomain constant not to be visible from client projects using Swift 2.2 (Xcode 7.3) or greater (Issue #33)

## 1.7

* Reduced memory footprint while using `extractFilesTo:overwrite:progress:error` to extract an archive. This method now uses a buffer to read and write the archived file, rather than reading it into memory up front (Issue #27, PR #28). Thanks, @brendand!
* Added `nullable` attribute to the return types of the `extractData...` methods, so they play more nicely with Swift's error handling (PR #29). Thanks, @amosavian!
* Fixed a compiler warning that started showing up in Xcode 7.3 (Issue #26). Thanks again, @brendand!

## 1.6.2

Fixed some issues when extracting files from an archive:

* Extracting the first file past the 4 GB mark in an archive would fail, due to a bug in the Zip64 implementation (Issue #25)
* Memory would grow as each file was extracted, potentially consuming multiple gigabytes for large archives
* Improved error messages when there's an error extracting a file (the underlying error is no longer hidden)

Thanks @brendand!

## 1.6.1

Fixed issue that can cause a crash when writing to Zip files across multiple threads (Issue #23). Thanks again, @iblacksun!

## 1.6

Added support for using UnzipKit from a Swift dynamic framework target (Issue #21, PR #22). Thanks @iblacksun!

## 1.5

* Added full support for Carthage (Issue #11)
* Added annotations for nullability, improving compatibility with Xcode 7 and Swift

## 1.4.2

Fixed a bug causing global comments not to get written to disk (Issue #19)

## 1.4.1

* Added the ability to password protect a file over the streaming API (`-writeInfoBuffer:...`), if the CRC of the file is known up front (Issue #16)
* Fixed a memory consumption bug, causing a crash on iOS when creating an archive with many files when `overwrite =- YES` (Issue #18)
* Quieted the warning logged every time a `UZKArchive` is created for an as-yet uncreated file (Issue #17)

Fixed a bug causing file-specific passwords never to be written to an archive (Issue #15)

## 1.4

* Fixed file encryption (Issue #12)

    _Due to Zip format requirements (the CRC needs to be known before a file write begins), passwords can no longer be used with the block-based file writing methods (`-writeIntobuffer...`). This is checked with an assertion, since the `password` property could be set already before starting the buffered write_

* Updated the implementation of `isPasswordProtected` to check all files, not just the first (Issue #13)

## 1.3.2

Fixed a bug causing file-specific passwords never to be written to an archive (Issue #15)

## 1.3.1

Fixed a bug, in which `password` was passed through as `nil` for the overload of `-writeData...` that doesn't take the `overwrite` argument (Issue #14)

## 1.3

Improved buffered writing API, no longer requiring a CRC, and allowing for error handling in the action block (Issue #9)

## 1.2.2

Silenced some 32-bit iOS warnings (Thanks, Clint!)

## 1.2.1

Added iOS 7 compatibility (Issue #8), and an iOS (Swift!) demo project

## 1.2

Added methods to easily detect whether a file is a Zip archive or not (Issue #7)

## 1.1.3

Fixed a bug introduced in the last version that would cause errors when writing a file for whom the comment had not first been read or written

## 1.1.2

Exposed a "comment" property on UZKArchive for reading and writing an archive's global comment (Issue #6)

## 1.1.1

Fixed a file handle leak that could lead to random file access errors (Issue #5)

## 1.1

Improved error handling, providing more detail in the NSSError objects returned (Issue #3)

## 1.0.3

Added synchronization, so accessing the same archive across threads doesn't cause errors (Issue #4)

## 1.0.2

Fixed bug causing file extraction to fail when an archive contains directories (Issue #2)

## 1.0.1

Fixed bug causing the library not to build for the 10.9 target SDK

## 1.0

Initial release
