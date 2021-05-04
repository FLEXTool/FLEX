#!/bin/bash

# Link a specific header
makeheader() {
    rm "Classes/Headers/$(basename $1)"
    ln -s "../../$1" "Classes/Headers/$(basename $1)"
}

# Link all headers under the given path and in subfolders
generate_headers_recursive() {
    for path in `find "Classes/$1" -not -path "*Headers*" -name "*.h"`; do
        makeheader "$path"
    done
}

# Link all headers directly under the given path, only
generate_headers() {
    for path in `ls "Classes/$1" | grep '\.h'`; do
        if [[ $1 ]]; then
            makeheader "Classes/$1/$path"
        else
            makeheader "Classes/$path"
        fi
    done
}

# The code below MUST match what is public_header_files in the podspec.
# When this file was last updated, this was the content of public_header_files:
#
#    "Classes/*.h", "Classes/Manager/*.h", "Classes/Toolbar/*.h",
#    "Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h",
#    "Classes/Core/**/*.h", "Classes/Utility/Runtime/Objc/**/*.h",
#    "Classes/ObjectExplorers/**/*.h", "Classes/Editing/**/*.h",
#    "Classes/Utility/FLEXMacros.h", "Classes/Utility/Categories/*.h",
#    "Classes/Utility/FLEXAlert.h", "Classes/Utility/FLEXResources.h"

# Include all headers in these folders
generate_headers "" # Top-level headers
generate_headers "Manager"
generate_headers "Toolbar"
generate_headers "Utility/Categories"
generate_headers_recursive "Core"
generate_headers_recursive "Utility/Runtime/Objc"
generate_headers_recursive "ObjectExplorers"
generate_headers_recursive "Editing"

# Include only headers in these specific folders,
# such as those with subfolders that should not be linked
makeheader "Classes/Utility/FLEXMacros.h"
makeheader "Classes/Utility/FLEXAlert.h"
makeheader "Classes/Utility/FLEXResources.h"
makeheader "Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h"

# Print all folders in Classes for use in Package.swift
for folder in `find "Classes" -type d`; do
    echo ".headerSearchPath(\"${folder#Classes/}\"),"
done
