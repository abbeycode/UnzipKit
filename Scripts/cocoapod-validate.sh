#!/bin/bash

set -ev
set -o pipefail

. Scripts/set-travis-tag-to-latest.sh

pod env

# Lint the podspec to check for errors. Don't call `pod spec lint`, because we want it to evaluate locally

# Using sed to remove logging from output until CocoaPods issue #7577 is implemented and I can use the
# OS_ACTIVITY_MODE = disable environment variable from the test spec scheme
pod lib lint --verbose | sed -l '/xctest\[/d; /^$/d'

. Scripts/unset-travis-tag.sh