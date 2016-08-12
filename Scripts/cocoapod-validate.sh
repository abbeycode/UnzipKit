#!/bin/bash

set -ev

./Scripts/install-demo-libs.sh

# Lint the podspec to check for errors. Don't call `pod spec lint`, because we want it to evaluate locally
pod lib lint