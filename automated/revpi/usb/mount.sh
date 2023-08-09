#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

usage() {
    echo "Usage: $0 [-s <true|false>] [-d device]" 1>&2
    exit 1
}

while getopts "d:s:h" o; do
  case "$o" in
    d) DEVICE="${OPTARG}" ;;
    s) SKIP_INSTALL="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

install() {
    dist_name

    # No dependencies to install
}

# Test run.
create_out_dir "${OUTPUT}"

install

mkdir -p /mnt/usb
info_msg "Image test: USB-1"
mount "$DEVICE" /mnt/usb
check_return "USB-1"
