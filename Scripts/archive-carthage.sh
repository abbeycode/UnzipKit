#!/bin/bash

set -ev

# Archives the Carthage packages, and prints the name of the archive

carthage build --no-skip-current --use-xcframeworks

# This doesn't work with --use-xcframeworks above (https://github.com/Carthage/Carthage/issues/3130)
# carthage archive

# When the above starts working again, this won't be necessary
pushd Carthage/Build/UnzipKit.xcframework
zip -r "../../../UnzipKit" .
popd
mv "UnzipKit.zip" "UnzipKit.xcframework"

export ARCHIVE_PATH="UnzipKit.xcframework"