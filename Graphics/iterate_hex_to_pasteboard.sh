#!/usr/bin/bash

# I use this script to loop over the contents of each text file
# produced by images_to_hex.sh and copy it to the clipboard.
# This makes adding or updating graphics to the project faster.
#
# You can edit the $folder variable below to work in a certain
# subdirectory, and you can edit the wildcard expression below
# to only work with a certain image size, like "*@3x.txt"

folder=.
for file in `find $folder -type f -name "*.txt"`; do
    cat $file | pbcopy
    read -p "Copied $file, press any key to continue..."
done
