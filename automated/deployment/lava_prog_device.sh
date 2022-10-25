#!/usr/bin/env bash

# Writes an image which is stored in folder /lava-lxc onto a RevPi.
# After the image is written onto the device, it is verified with a
# checksum against the original image from the source archive.

# This script relies on features from LAVA and can't be run on a
# user controlled setup without changes.

set +x

# shellcheck disable=SC2005
absdirname () { echo "$(cd "$(dirname "$1")" && pwd)"; }
SRC_ROOT="$(absdirname "${BASH_SOURCE[0]}")"

# include echo helper
# shellcheck disable=SC1090
. "$SRC_ROOT/tools/echohelper.sh"

TEST_NAME="image_deployment"

# find image and extract
cd /lava-lxc || exit

ARCHIVE=$(find . -iname "*tar*")
tar xzvf "$ARCHIVE"
rm "$ARCHIVE"

IMAGE=$(find . -iname "*.img")
echo "$IMAGE"

echoinfo "please wait, calculating md5sum for image"
md5_img=$(md5sum "$IMAGE" | awk '{ print $1 }' )

usb_disk=$(find /sys/devices -iname "${LAVA_STATIC_INFO_0_usb_path:?}" -exec find {} -iname block -print0 \; 2>/dev/null | xargs -0 ls)
disk=$(lsblk -I 8 -dno NAME,RM | awk '{ if  ($2 == 1) { print $1 } }')

if [ ! "$usb_disk" == "$disk" ]; then
  echoerr "Blockdevice from lsblk and sysfs are different ($disk - $usb_disk)"
  lava-test-raise "$TEST_NAME+disk-device"
fi

echoinfo "programming the image on storage device /dev/$disk"
dd if="$IMAGE" of="/dev/$disk" bs=64k status=progress
sync

echoinfo "verifying disk vs image"
md5_disk=$(dd if="/dev/$disk" bs=64k count="$(stat -c %s "$IMAGE")" iflag=count_bytes status=progress | md5sum | awk '{ print $1 }' )
echo "$md5_img"
echo "$md5_disk"

if [[ "$md5_img" != "$md5_disk" ]]; then
  echoerr "image on disk seems to have errors"
  lava-test-raise "$TEST_NAME+md5sum"
fi

lava-test-case "$TEST_NAME" --result pass

