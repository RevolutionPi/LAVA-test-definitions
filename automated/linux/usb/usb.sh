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

install() {
    apt-get update -q
    apt-get -y install bc fdisk
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

    partition_disk "${DEVICE%[0-9]}"
    format_partitions "${DEVICE%[0-9]}" ext4

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
        if lsblk | grep "$(basename "$DEVICE")"
        then
            #Flash disk will be formatted
            if mke2fs -F -t ext4 "$DEVICE"
            then
                if [ ! -d "$MOUNT_POINT" ]
                then
                    mkdir "$MOUNT_POINT"
                fi

                if mount "$DEVICE" "$MOUNT_POINT"
                then
                    dd if=/dev/urandom of=/tmp/testfile bs=4k count=256k
                    md5sum /tmp/testfile > md5

                    cp /tmp/testfile "$MOUNT_POINT"
                    cp md5 "$MOUNT_POINT"

                    if cd "$MOUNT_POINT" && md5sum -c md5
                    then
                        report_pass "$test_case_id md5sum"
                    else
                        error_msg "$test_case_id md5sum FAIL!"
                    fi
                else
                    error_msg "$test_case_id mount FAIL!"
                fi
                cd /
                umount "$MOUNT_POINT"
                rm -r "$MOUNT_POINT"
            else
                error_msg "$test_case_id format FAIL!"
            fi
        else
            error_msg "$test_case_id flash-disk FAIL!"
        fi
        ;;
    "usb-4")
        # Run dd to measure the speed - write
        output=$(dd if=/dev/zero of="$DEVICE" bs=1k count=100000 2>&1)
        echo "$output"
        speed=$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)
        if [ "$(echo "$speed >= $SPEED_DEFAULT_WRITE_MIN" | bc -l)" -eq 1 ]; then
            report_pass "Overall write speed is greater than $SPEED_DEFAULT_WRITE_MIN MB/s"
        else
            error_msg "Overall write speed is less than $SPEED_DEFAULT_WRITE_MIN MB/s -> FAIL!"
        fi
        ;;
    "usb-5")
        # Run dd to measure the speed - read
        output=$(dd if="$DEVICE" of=/dev/null bs=1k count=100000 2>&1)
        echo "$output"
        speed=$(echo "$output" | grep -Eo "$SPEED_REGEX" | cut -d' ' -f1)
        if [ "$(echo "$speed >= $SPEED_DEFAULT_READ_MIN" | bc -l)" -eq 1 ]; then
            report_pass "Overall read speed is greater than $SPEED_DEFAULT_READ_MIN MB/s"
        else
            error_msg "Overall read speed is less than $SPEED_DEFAULT_READ_MIN MB/s -> FAIL!"
        fi
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"


if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done
