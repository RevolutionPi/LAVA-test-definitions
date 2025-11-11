#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="last-partition-resize"

usage() {
    cat << EOF
Usage: $0 -b BLOCKDEV
EOF

    exit "$1"
}

last_partition_resize_check() {
    local blockdev="$1" blockdev_size=""
    local last_partition="" last_partition_start="" last_partition_size=""

    local test_case_id="last-partition-resize"

    if ! blockdev_size="$(cat /sys/block/"$blockdev"/size)"; then
        printf "Unable to read size of blockdev %s\n" "$blockdev" >&2
        report_fail "$test_case_id"
    fi

	# shellcheck disable=SC2012
    if ! last_partition="$(cd /dev && ls -1 "$blockdev"p* | tail -1)"; then
        printf "Unable to find last partition of blockdev %s\n" "$blockdev" >&2
        report_fail "$test_case_id"
    fi

    if ! last_partition_start="$(cat /sys/block/"$blockdev"/"$last_partition"/start)"; then
        printf "Unable to get start of partition %s\n" "$last_partition" >&2
        report_fail "$test_case_id"
    fi

    if ! last_partition_size="$(cat /sys/block/"$blockdev"/"$last_partition"/size)"; then
        printf "Unable to get size of partition %s\n" "$last_partition" >&2
        report_fail "$test_case_id"
    fi

    local last_partition_end="$((last_partition_start + last_partition_size))"
    # tolerance of 4096 blocks
    if [ "$last_partition_end" -lt "$((blockdev_size - 4096))" ]; then
        printf "Last partition is too small: %d, %d (last partition end, blockdev size)\n" "$last_partition_end" "$blockdev_size" >&2
        report_fail "$test_case_id"
    else
        report_pass "$test_case_id"
    fi
}

last_partition_fs_resize_check() {
    local blockdev="$1"
}

run() {
    local test_case_id="$1"
    info_msg "Running $test_case_id test..."

    case "$test_case_id" in
    last-partition-resize)
        last_partition_resize_check "$BLOCKDEV"
        ;;
    *) error_msg "Unknown test case: $test_case_id" ;;
    esac
}

while getopts "b:ht:" o; do
    case "$o" in
    b) BLOCKDEV="$OPTARG" ;;
    h) usage 0 ;;
    t) TESTS="$OPTARG" ;;
    *) usage 1 >&2 ;;
    esac
done

shift $((OPTIND-1))

if [ -z "$BLOCKDEV" ]; then
    printf "Blockdev must be given as argument\n" >&2
    usage 1
fi

create_out_dir "$OUTPUT"

for t in $TESTS; do
    run "$t"
done
