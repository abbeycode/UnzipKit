#!/bin/bash

set -ev

. Scripts/set-travis-tag-to-latest.sh

pushd UnzipKitDemo
pod --version
pod update
popd

. Scripts/unset-travis-tag.sh