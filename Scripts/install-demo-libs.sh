#!/bin/bash

if [ "$TRAVIS_XCODE_SCHEME" = "UnzipKitDemo" ]; then
    pushd UnzipKitDemo
    bundle exec pod update
    popd
fi