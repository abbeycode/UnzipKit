#!/bin/bash

if [ -n "$TRAVIS_TAG_SUBSTITUTED" ]; then
    echo "Unsetting TRAVIS_TAG..."
    unset TRAVIS_TAG
fi