#!/bin/bash

set -ev
set -o pipefail

. Scripts/set-travis-tag-to-latest.sh

pod env

# Work around bug in Xcode 9.3.0 (on Travis) that causes unit tests to crash when targeting
# iOS 8.0. Remove when it's no longer necessary (as well as the `mv` at the end)
sed -i '.original' 's/s.ios.deployment_target = "8.0"/s.ios.deployment_target = "9.0"/g' UnzipKit.podspec

# Lint the podspec to check for errors. Don't call `pod spec lint`, because we want it to evaluate locally

# Using sed to remove logging from output until CocoaPods issue #7577 is implemented and I can use the
# OS_ACTIVITY_MODE = disable environment variable from the test spec scheme
pod lib lint --verbose | sed -l '/xctest\[/d; /^$/d'

# Restore previous version
mv UnzipKit.podspec.original UnzipKit.podspec

. Scripts/unset-travis-tag.sh