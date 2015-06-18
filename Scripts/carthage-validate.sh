echo "git \"$TRAVIS_BUILD_DIR\" \"$TRAVIS_BRANCH\"" > UnzipKitDemo/Cartfile

pushd UnzipKitDemo
carthage update --configuration Debug --verbose
popd