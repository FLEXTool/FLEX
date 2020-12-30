#!/bin/bash

XCP=$(which xcpretty)
if [ "$1" == "scp" ]; then
    export SHOULD_SCP=1
fi
if [ -z $XCP ]; then
    xcodebuild BUILD_ROOT=build -target FLEX-tvOS
else
    xcodebuild BUILD_ROOT=build -target FLEX-tvOS | $XCP
fi
