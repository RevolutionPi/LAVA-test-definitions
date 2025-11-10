#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="initramfs-boot initramfs-tools initramfs-file"

usage() {
    cat << __EOF__
usage: $(basename "$0") [-s <true|false>] [-t test...]
__EOF__
    exit "${1:-0}"
}

while getopts "s:t:h" o; do
    case "$o" in
    s) ;;
    t) TESTS="${OPTARG}" ;;
    h) usage ;;
    *) usage 1 >&2 ;;
    esac
done

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    initramfs-boot)
        grep -q "Freeing initrd memory" /var/log/kern.log
        check_return "$test_case_id"
        ;;
    initramfs-tools)
        dpkg --no-pager -l initramfs-tools >/dev/null 2>&1
        check_return "$test_case_id"
        ;;
    initramfs-file)
        [ -f /boot/firmware/initramfs8 ]
        check_return "$test_case_id"
        ;;
    *)
        error_msg "Unknown test case '$test_case_id'"
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

# initramfs will only be tested for bookworm and newer. versions before bookworm
# skip this test.
. /etc/os-release
if [ "$VERSION_ID" -lt 12 ]; then
    info_msg "Release is $VERSION (<12), skipping all initramfs tests"
    for t in $TESTS; do
        report_skip "$t"
    done

    exit 0
fi

for t in $TESTS; do
    run "$t"
done
