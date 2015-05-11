# UnzipKit CHANGELOG

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