#!/bin/bash

export PATH=/usr/bin/opt/local/bin:/opt/local/sbin:/usr/local/git:$PATH
export SRCROOT="$SRCROOT"

echo "should SCP: -$SHOULD_SCP-"
echo "## check $SRCROOT/postScript.sh for a helpful post script"

# only used if we SCP the deb over, and this only happens if dpkg-deb and fauxsu are installed
ATV_DEVICE_IP=guest-room.local

#say "$SDKROOT"

echo $SDKROOT

BASE_SDK=`basename $SDKROOT`

if [[ $BASE_SDK == *"Simulator"* ]]
then
exit 0
fi

# xcodes path to the the full framework

TARGET_BUILD_FW="$TARGET_BUILD_DIR"/"$PRODUCT_NAME".$WRAPPER_EXTENSION

echo $TARGET_BUILD_FW

DPKG_BUILD_PATH="$SRCROOT"/layout
FW_FOLDER="$DPKG_BUILD_PATH"/Library/Frameworks

echo $FW_FOLDER

FINAL_FW_PATH=$FW_FOLDER/"$PRODUCT_NAME".$WRAPPER_EXTENSION
rm -rf "$FINAL_FW_PATH"
mkdir -p "$FW_FOLDER"
mkdir -p "$FINAL_FW_PATH"
cp -r "$TARGET_BUILD_FW" "$FW_FOLDER"
pushd "$SRCROOT"
find . -name ".DS_Store" | xargs rm -f

EXE_PATH=$FINAL_FW_PATH/$EXECUTABLE_NAME
#exit 0
if [ "$SHOULD_SCP" == "1"  ]; then 
ldid -S $EXE_PATH
rm -rf $FINAL_FW_PATH/_CodeSignature
rm $FW_FOLDER/*.zip
    /usr/local/bin/fakeroot dpkg-deb -b layout
    scp layout.deb root@$ATV_DEVICE_IP:~
    ssh root@$ATV_DEVICE_IP "dpkg -i layout.deb ; killall -9 nitoTV ; lsdtrip launch com.nito.nitoTV4"
fi
exit 0


