#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_INSTALL="False"
TESTS="usb-1 usb-2 usb-4 usb-5"
MOUNT_POINT="./mnt_test"
SPEED_DEFAULT_READ_MIN=15
SPEED_DEFAULT_WRITE_MIN=4
SPEED_REGEX="[[:digit:]]+(\.[[:digit:]]+)? MB\/s"

usage() {
    echo "Usage: $0 [-s <true|false>] [-d device] [-m mount_point] [-t test] [-r speed_default_read_min] [-w speed_default_write_min]" 1>&2
    exit 1
}

while getopts "s:d:m:t:r:w:h" o; do
    case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    d) DEVICE="${OPTARG}" ;;
    m) MOUNT_POINT="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    r) SPEED_DEFAULT_READ_MIN="${OPTARG}" ;;
    w) SPEED_DEFAULT_WRITE_MIN="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_available_dev() {
    if [ ! -b "$1" ];then
        warn_msg "Block device $1 not found"
        return 1
    fi

    return 0
}

# usage: ensure_mountable_partition DEVICE PARTITION
ensure_mountable_partition() {
    if ! check_available_dev "$1"; then
        return 1
    fi

    if [ ! -b "$2" ] || ! (file -Ls "$2" | grep -q ext4); then
        partition_disk "${DEVICE%[0-9]}"
        format_partitions "${DEVICE%[0-9]}" ext4
    fi
}

usb_1() {
    local test_case_id=usb-1

    mkdir -p "$MOUNT_POINT"

    if mount "$DEVICE" "$MOUNT_POINT"; then
        report_pass "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
    else
        warn_msg "$test_case_id: Can't mount $DEVICE to $MOUNT_POINT"
        report_fail "$test_case_id"
    fi
}

usb_2() {
    local test_case_id=usb-2

    mkdir -p "$MOUNT_POINT"

    if ! mount "$DEVICE" "$MOUNT_POINT"; then
        warn_msg "$test_case_id: Can't mount $DEVICE to $MOUNT_POINT"
        report_fail "$test_case_id"
        return 1
    fi

    if ! dd if=/dev/urandom of=./testfile bs=1k count=512; then
        warn_msg "$test_case_id: Can't write test file"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! md5sum ./testfile > md5; then
        warn_msg "$test_case_id: Can't write md5sum of testfile to file"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! cp testfile md5 "$MOUNT_POINT"; then
        warn_msg "$test_case_id: Can't copy testfile and md5sum to mount point"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! pushd "$MOUNT_POINT" > /dev/null; then
        warn_msg "$test_case_id: Can't enter $MOUNT_POINT"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! md5sum -c md5; then
        warn_msg "$test_case_id: Checksums don't match"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! popd > /dev/null; then
        warn_msg "$test_case_id: Unable to exit $MOUNT_POINT"
        report_fail "$test_case_id"
        umount "$MOUNT_POINT" \
            || warn_msg "$test_case_id: Unable to unmount $MOUNT_POINT"
        return 1
    fi

    if ! umount "$MOUNT_POINT"; then
        warn_msg "$test_case_id: Unable unmount $MOUNT_POINT"
        report_fail "$test_case_id"
        return 1
    fi

    rmdir "$MOUNT_POINT" \
        || warn_msg "$test_case_id: Unable to remove left over $MOUNT_POINT dir"
    report_pass "$test_case_id"
}

usb_4() {
    local test_case_id=usb-4
    local output=""
    local speed=""
    local result=""

    # Run dd to measure the speed - write
    if ! output="$(dd if=/dev/zero \
        of="$DEVICE" \
        conv=sync \
        iflag=nocache \
        oflag=nocache \
        bs=1k \
        count=100000 2>&1)"; then
        warn_msg "$test_case_id: Unable to write to $DEVICE"
        report_fail "$test_case_id"
        return 1
    fi
    echo "$output"

    if ! speed="$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)"
    then
        warn_msg "$test_case_id: Can't extract speed from output"
        report_fail "$test_case_id"
        return 1
    fi

    if [ "$(echo "$speed >= $SPEED_DEFAULT_WRITE_MIN" | bc -l)" -eq 1 ]; then
        result=pass
        info_msg "Overall write speed is greater than $SPEED_DEFAULT_WRITE_MIN MB/s"
        report_pass "$test_case_id"
    else
        result=fail
        warn_msg "Overall write speed is less than $SPEED_DEFAULT_WRITE_MIN MB/s -> FAIL!"
        report_fail "$test_case_id"
    fi

    add_metric "$test_case_id-metric" "$result" "$speed" MB/s
}

usb_5() {
    local test_case_id=usb-5
    local output=""
    local speed=""
    local result=""

    # Run dd to measure the speed - read
    if ! output="$(dd if="$DEVICE" \
        of=/dev/null \
        conv=sync \
        iflag=nocache \
        oflag=nocache \
        bs=1k \
        count=100000 2>&1)"; then
        warn_msg "$test_case_id: Unable to read from $DEVICE"
        report_fail "$test_case_id"
        return 1
    fi
    echo "$output"

    if ! speed="$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)"
    then
        warn_msg "$test_case_id: Unable to extract speed"
        report_fail "$test_case_id"
        return 1
    fi

    if [ "$(echo "$speed >= $SPEED_DEFAULT_READ_MIN" | bc -l)" -eq 1 ]; then
        result=pass
        info_msg "Overall read speed is greater than $SPEED_DEFAULT_READ_MIN MB/s"
        report_pass "$test_case_id"
    else
        result=fail
        warn_msg "Overall read speed is less than $SPEED_DEFAULT_READ_MIN MB/s -> FAIL!"
        report_fail "$test_case_id"
    fi

    add_metric "$test_case_id-metric" "$result" "$speed" MB/s
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    if mount | grep -q "$DEVICE"; then
        umount "$DEVICE"
        warn_msg "$test_case_id: Left over mount from $DEVICE, not running test"
        report_skip "$test_case_id"
        return 1
    fi

    if ! ensure_mountable_partition "${DEVICE%[0-9]}" "$DEVICE"; then
        warn_msg "$test_case_id: Cannot ensure device is mountable"
        report_fail "$test_case_id"
        return 1
    fi

    case "$test_case_id" in
    "usb-1") usb_1 ;;
    "usb-2") usb_2 ;;
    "usb-4") usb_4 ;;
    "usb-5") usb_5 ;;
    *) error_msg "Invalid test case '$test_case_id'" ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "bc fdisk" "$SKIP_INSTALL"

for t in $TESTS; do
    run "$t"
done

exit 0
