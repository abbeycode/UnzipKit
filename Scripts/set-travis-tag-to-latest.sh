#!/bin/bash

git fetch --tags

if [ -z "$TRAVIS_TAG" ]; then
    TRAVIS_TAG_SUBSTITUTED=1
    export TRAVIS_TAG="$(git tag -l | tail -1)"
    echo "Not a tagged build. Using last tag ($TRAVIS_TAG)..."
fi
