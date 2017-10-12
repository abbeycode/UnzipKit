#!/bin/bash

REPO="github \"$TRAVIS_REPO_SLUG\""
COMMIT=$TRAVIS_COMMIT

if [ -z ${TRAVIS+x} ]; then
    REPO="git \"`pwd`\""
    COMMIT=`git log -1 --oneline | cut -f1 -d' '`
    TRAVIS_BUILD_DIR="/Users/Dov/Source Code/UnzipKit"
    echo "Not running in Travis. Setting REPO ($REPO) and COMMIT ($COMMIT)"
fi

if [ -n "$TRAVIS" ] && [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    REPO="github \"$TRAVIS_PULL_REQUEST_SLUG\""
    COMMIT=$TRAVIS_PULL_REQUEST_SHA
    echo "Build is for a Pull Request. Overriding REPO ($REPO) and COMMIT ($COMMIT)"
fi

if [ ! -d "CarthageValidation" ]; then
    mkdir "CarthageValidation"
fi

brew install carthage

rm UnzipKitDemo/Cartfile
rm UnzipKitDemo/Cartfile.resolved
rm -rf UnzipKitDemo/Carthage

echo "$REPO \"$COMMIT\"" > UnzipKitDemo/Cartfile

pushd UnzipKitDemo > /dev/null

carthage bootstrap --configuration Debug --verbose
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