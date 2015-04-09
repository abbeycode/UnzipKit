#!/bin/bash

if [ "$TRAVIS_XCODE_SCHEME" = "UnzipKitDemo" ]; then
    pushd UnzipKitDemo
    pod update
    popd
fi