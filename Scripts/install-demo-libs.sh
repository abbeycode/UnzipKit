#!/bin/bash

if [ "$TRAVIS_XCODE_SCHEME" = "UnzipKitDemo" ]; then
    gem install cocoapods
    pushd UnzipKitDemo
    pod install
    popd
fi