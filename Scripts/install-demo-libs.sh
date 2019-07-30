#!/bin/bash

set -ev

. Scripts/set-travis-tag-to-latest.sh

pushd UnzipKitDemo
bundle exec pod --version
bundle exec pod update
popd

. Scripts/unset-travis-tag.sh