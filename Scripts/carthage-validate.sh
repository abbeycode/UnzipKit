#!/bin/bash

if [ -z ${TRAVIS+x} ]; then
    TRAVIS_BUILD_DIR="~/Source Code/UnzipKit"
    TRAVIS_BRANCH=carthage
fi

rm UnzipKitDemo/Cartfile
rm UnzipKitDemo/Cartfile.resolved
rm -rf UnzipKitDemo/Carthage

echo "git \"$TRAVIS_BUILD_DIR\" \"$TRAVIS_BRANCH\"" > UnzipKitDemo/Cartfile

pushd UnzipKitDemo

carthage bootstrap --configuration Debug --verbose
CARTHAGE_EXIT=$?

popd

echo "Carthage exit: $CARTHAGE_EXIT"
exit $CARTHAGE_EXIT