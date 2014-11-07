#!/bin/sh

git=`sh /etc/profile; which git`
build_num=`"$git" rev-list --all |wc -l`
branch=`"$git" rev-parse --abbrev-ref HEAD`
commit=`"$git" rev-parse --short HEAD`
version=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`

if [[ $CONFIGURATION == *Debug* ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_num-$branch" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
else
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_num" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
fi
echo "Updated ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
