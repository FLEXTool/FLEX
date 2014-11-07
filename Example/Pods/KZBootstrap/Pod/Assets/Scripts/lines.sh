#!/bin/sh


# exclude files with addnotation KZBIgnoreLineCount
exclusion_addnotation="KZBIgnoreLineCount"
allowed_lines=250

find "${SRCROOT}" \( -name "*.h" -or -name "*.m" -or -name "*.swift" \) -and \( -path "${SRCROOT}/Pods/*" -prune -o -print0 \) |
while read -d '' filename
do
  if ! $(grep -qF "${exclusion_addnotation}" "${filename}")
   then
    lines=$(wc -l < "${filename}")
    if [[ ${lines} -gt ${allowed_lines} ]]; then
      echo "${filename}:1: warning: File ${filename} has more than ${allowed_lines} lines (" ${lines} "), consider refactoring or add ${exclusion_addnotation}."
    fi
  fi
done