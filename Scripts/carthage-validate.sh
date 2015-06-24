#!/bin/bash

if [ -z ${TRAVIS+x} ]; then
    TRAVIS_BUILD_DIR="~/Source Code/UnzipKit"
    TRAVIS_BRANCH=carthage
fi

rm UnzipKitDemo/Cartfile
rm UnzipKitDemo/Cartfile.resolved
rm -rf UnzipKitDemo/Carthage

echo "git \"$TRAVIS_BUILD_DIR\" \"$TRAVIS_BRANCH\"" > UnzipKitDemo/Cartfile

pushd UnzipKitDemo > /dev/null

carthage bootstrap --configuration Debug --verbose --simulator-only
EXIT_CODE=$?

echo "Checking for build products..."

if [ ! -d "Carthage/Build/Mac/UnzipKit.framework" ]; then
    echo "No Mac library built"
    EXIT_CODE=1
fi

if [ ! -d "Carthage/Build/iOS/UnzipKit.framework" ]; then
    echo "No iOS library built"
    EXIT_CODE=1
fi

popd > /dev/null

exit $EXIT_CODE