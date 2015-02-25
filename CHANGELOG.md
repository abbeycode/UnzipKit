# UnzipKit CHANGELOG

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