* Removed methods deprecated in v1.9 (Issue #90, PR #92)
* Fixed behavior of `-extractFilesTo:overwrite:error:`, so it shows the progress of each individual file as they extract (Issue #91, PR #94)
* Deprecated the initializers that take a file path instead of an `NSURL` (Issue #90, PR #95)
* Fixed a crasher for unreadable files in `+pathIsAZip:` (Issue #99)
* Deprecated all overloads of `-writeData:...` and `-writeIntoBuffer:...` that take any file properties other than the path, replacing them each with a single call that takes an instance of the new `ZipFileProperties`. This allows for all the default values to be defined in one place, so you can specify only where you want to deviate from the defaults (Issue #89, PR #97)
* Fixed buffer overrun vulnerability when deleting a file in an archive where not every file has a file comment (Issue #106)
* Fixed deallocated pointer use when a file write occurs inside the block of a file write operation, already an error condition (Issue #107)

In this release:
* Fixed some issues caught by running tests with sanitizers (Issues #106 and #107)