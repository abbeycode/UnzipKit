#!/bin/bash

if [ "$TRAVIS_XCODE_SCHEME" = "UnzipKitDemo" ]; then
    pushd UnzipKitDemo
    pod --version
    pod update
    popd
fi