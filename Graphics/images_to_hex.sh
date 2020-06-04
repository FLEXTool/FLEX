#!/usr/bin/bash

# Converts every image *.png to *.txt as an ASCII hex representation of the image.
#
# This script simply runs image_to_code.py on each of the folders containing
# our images and writes the hex of each image to a text file. Instead of updating
# the original script, I left it to be generic as it was originally intended
# in case someone else finds it useful. The original python script outputs
# header and implementation files, which this script removes after it is run.
#
# Run this command to remove the hex files: find . -type f -name "*.txt" | xargs rm
#
# Usage: ./images_to_hex.sh [one or more folders in a quoted string]
# Examples:
#     bash images_to_hex.sh
#     bash images_to_hex.sh toolbar
#     bash images_to_hex.sh "toolbar filetypes"
#

if [[ $1 ]]; then
    imageFolders="$1"
else
    imageFolders="filetypes range-slider toolbar misc"
fi

for dir in $imageFolders; do
    rm $dir/*.txt
    for image in `ls $dir`; do
        name=`basename $image .png`
        outfile=$dir/$name.txt
        echo "Output file: $outfile"
        ./image_to_code.py -i $dir/$image -c $name > "$outfile"
    done
done

rm -rf *PNG.[hm]
