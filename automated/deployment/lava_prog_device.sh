#!/usr/bin/env bash

# Writes an image which is stored in folder /lava-lxc onto a RevPi.
# After the image is written onto the device, it is verified with a
# checksum against the original image from the source archive.

# This script relies on features from LAVA and can't be run on a
# user controlled setup without changes.

# shellcheck disable=SC1091
. ../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

usage() {
    echo "Usage: $0 [-s <true|false>]" 1>&2
    exit 1
}

while getopts "s:" o; do
  case "${o}" in
    s) ;;
    *) usage ;;
  esac
done

prog_device() {
    set +x

    # find image and extract
    cd /lava-lxc || exit

    IMAGE=$(find . -maxdepth 1 -iname "*.xz" -type f)
    image_size=$(xz --robot --list "${IMAGE}" | awk 'NR==2{print $5}')

    info_msg "${IMAGE} will be programmed onto the DUT"

    usb_disk=$(find /sys/devices -iname "${LAVA_STATIC_INFO_0_usb_path:?}" -exec find {} -iname block -print0 \; 2>/dev/null | xargs -0 ls)
    disk=$(lsblk -I 8 -dno NAME,RM | awk '{ if  ($2 == 1) { print $1 } }')

    if [ ! "${usb_disk}" == "${disk}" ]; then
        error_fatal "Blockdevice from lsblk and sysfs are different (${disk} - ${usb_disk})"
        return $?
    fi

    info_msg "$(date "+%Y-%m-%d_%H-%M-%S"): programming the image on storage device /dev/${disk}"
    md5_img=$(xz -dc "${IMAGE}" | tee >(dd of=/dev/sda bs=1M) | md5sum | cut -d ' ' -f 1)
    sync
    info_msg "$(date "+%Y-%m-%d_%H-%M-%S"): programmed image onto storage device /dev/${disk}"

    info_msg "verifying disk vs image"
    md5_disk=$(dd if="/dev/${disk}" bs=1M count="${image_size}" iflag=count_bytes | md5sum | awk '{ print $1 }')
    info_msg "md5 checksum of image: ${md5_img}"
    info_msg "md5 checksum of disk: ${md5_disk}"

    if [ "${md5_img}" != "${md5_disk}" ]; then
        error_fatal "md5 checksums of image and disk don't match!"
        return $?
    fi
}

# Test run.
create_out_dir "${OUTPUT}"

prog_device
check_return "prog_device"
