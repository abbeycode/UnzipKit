#!/bin/bash

set -ev

. Scripts/set-travis-tag-to-latest.sh

# Lint the podspec to check for errors. Don't call `pod spec lint`, because we want it to evaluate locally
pod lib lint

. Scripts/unset-travis-tag.sh