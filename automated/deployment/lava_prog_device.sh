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
    s)
        # parameter for SKIP_INSTALL, ignored as nothing is installed
        ;;
    *) usage ;;
    esac
done

get_uncompressed_image_size() {
    local compression_format="$1"
    local file="$2"

    case "$compression_format" in
        xz)
            printf "%d" "$(xz --robot --list "$file" | awk 'NR==2{print $5}')"
            ;;
        zstd)
            printf "%d" "$(zstd --list -vv "$file" 2>/dev/null | awk '/Decompressed Size:/ { print $3 }')"
            ;;
        *)
            printf "Unsupported compression: %s\n" "$compression_format" >&2
            return 1
    esac
}

get_decompress_prog() {
    local compression_format="$1"

    case "$compression_format" in
        xz)
            printf "xz -dcT0"
            ;;
        zstd)
            printf "zstd -dcfT0"
            ;;
        *)
            printf "Unsupported compression %s\n" "$compression_format" >&2
            return 1
            ;;
    esac
}

prog_device() {
    # find image and extract
    cd /lava-lxc || exit

    IMAGE_COMPRESSION=xz
    IMAGE=$(find . -maxdepth 1 -iname "*.xz" -type f)
    if [ -z "$IMAGE" ]; then
        # fallback to zstd compressed image
        IMAGE_COMPRESSION=zstd
        IMAGE=$(find . -maxdepth 1 -iname "*.zst" -type f)
        if [ -z "$IMAGE" ]; then
            error_fatal "No image found. Aborting."
        fi
    fi
    info_msg "${IMAGE} will be programmed onto the DUT"
    if [ "$(echo "$IMAGE" | wc -l)" -gt 1 ]; then
        error_fatal "Multiple images found. Aborting."
    fi

    local image_size=
    if ! image_size="$(get_uncompressed_image_size "$IMAGE_COMPRESSION" "$IMAGE")"; then
        error_fatal "Unable to get uncompressed image size"
    fi
    local decompress_cmd=
    if ! decompress_cmd="$(get_decompress_prog "$IMAGE_COMPRESSION")"; then
        error_fatal "Unable to obtain decompression arguments"
    fi

    usb_disk=/dev/blockDUT
    if [ ! -b "${usb_disk}" ]; then
        error_fatal "Blockdevice not found: ${usb_disk}"
    fi

    info_msg "$(date "+%Y-%m-%d_%H-%M-%S"): programming the image on storage device ${usb_disk}"
    md5_img=$($decompress_cmd "${IMAGE}" | tee >(dd of="$usb_disk" bs=1M) | md5sum | cut -d ' ' -f 1)
    sync
    info_msg "$(date "+%Y-%m-%d_%H-%M-%S"): programmed image onto storage device ${usb_disk}"

    info_msg "verifying disk vs image"
    md5_disk=$(dd if="${usb_disk}" \
        bs=1M count="${image_size}" \
        iflag=count_bytes \
        | md5sum \
        | awk '{ print $1 }')
    info_msg "md5 checksum of image: ${md5_img}"
    info_msg "md5 checksum of disk: ${md5_disk}"

    if [ "${md5_img}" != "${md5_disk}" ]; then
        error_fatal "md5 checksums of image and disk don't match!"
    fi
}

# Test run.
create_out_dir "${OUTPUT}"

prog_device
check_return "prog_device"
