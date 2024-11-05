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
        error_msg "Block device $1 not found"
    fi
}

# usage: ensure_mountable_partition DEVICE PARTITION
ensure_mountable_partition() {
    check_available_dev "$1"

    if [ ! -b "$2" ] || ! (file -Ls "$2" | grep -q ext4); then
        partition_disk "${DEVICE%[0-9]}"
        format_partitions "${DEVICE%[0-9]}" ext4
    fi
}

run() {
    local test_case_id="$1"
    local output=""
    local speed=""
    info_msg "Running ${test_case_id} test..."

    if mount | grep -q "$DEVICE"; then
        umount "$DEVICE"
        exit_on_fail "$test_case_id-umount-left-over-mount"
    fi

    ensure_mountable_partition "${DEVICE%[0-9]}" "$DEVICE"

    case "$test_case_id" in
    "usb-1")
        mkdir -p "$MOUNT_POINT"

        if mount "$DEVICE" "$MOUNT_POINT"; then
            report_pass "$test_case_id"
            umount "$MOUNT_POINT"
        else
            error_msg "$test_case_id FAIL!"
        fi
        ;;
    "usb-2")
        if [ ! -d "$MOUNT_POINT" ]; then
            mkdir "$MOUNT_POINT"
        fi

        mount "$DEVICE" "$MOUNT_POINT"
        exit_on_fail "$test_case_id-mount"

        dd if=/dev/urandom of=./testfile bs=1k count=512
        exit_on_fail "$test_case_id-dd"
        md5sum ./testfile > md5

        cp testfile md5 "$MOUNT_POINT" > /dev/null

        pushd "$MOUNT_POINT" > /dev/null || error_msg "$test_case_id-pushd"
        md5sum -c md5
        check_return "$test_case_id-md5sum"
        popd > /dev/null || error_msg "$test_case_id-popd"

        umount "$MOUNT_POINT"
        rmdir "$MOUNT_POINT"
        ;;
    "usb-4")
        # Run dd to measure the speed - write
        output=$(dd if=/dev/zero \
            of="$DEVICE" \
            conv=sync \
            iflag=nocache \
            oflag=nocache \
            bs=1k \
            count=100000 2>&1)
        echo "$output"
        speed=$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)
        if [ "$(echo "$speed >= $SPEED_DEFAULT_WRITE_MIN" | bc -l)" -eq 1 ]; then
            info_msg "Overall write speed is greater than $SPEED_DEFAULT_WRITE_MIN MB/s"
            add_metric "$test_case_id-write-speed" pass "$speed" MB/s
        else
            warn_msg "Overall write speed is less than $SPEED_DEFAULT_WRITE_MIN MB/s -> FAIL!"
            add_metric "$test_case_id-write-speed" fail "$speed" MB/s
        fi
        ;;
    "usb-5")
        # Run dd to measure the speed - read
        output=$(dd if="$DEVICE" \
            of=/dev/null \
            conv=sync \
            iflag=nocache \
            oflag=nocache \
            bs=1k \
            count=100000 2>&1)
        echo "$output"
        speed=$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)
        if [ "$(echo "$speed >= $SPEED_DEFAULT_READ_MIN" | bc -l)" -eq 1 ]; then
            info_msg "Overall read speed is greater than $SPEED_DEFAULT_READ_MIN MB/s"
            add_metric "$test_case_id-read-speed" pass "$speed" MB/s
        else
            warn_msg "Overall read speed is less than $SPEED_DEFAULT_READ_MIN MB/s -> FAIL!"
            add_metric "$test_case_id-read-speed" fail "$speed" MB/s
        fi
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "bc fdisk" "$SKIP_INSTALL"

for t in $TESTS; do
    run "$t"
done
