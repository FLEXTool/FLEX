#!/bin/bash

XCP=$(which xcpretty)

echo $XCP

if [ -z $XCP ]; then
    xcodebuild BUILD_ROOT=build -target FLEX-tvOS
else
    xcodebuild BUILD_ROOT=build -target FLEX-tvOS | $XCP
fi
