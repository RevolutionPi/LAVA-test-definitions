#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pileft-1 pileft-2 dmesg"

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS]" 1>&2
    exit 1
}

while getopts "s:t:h" o; do
    case "$o" in
    s)
        # nothing to install
        ;;
    t) TESTS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_iface1() {
    local iface_name="$1"
    if [ -d "/sys/class/net/${iface_name}" ]; then
        info_msg "$iface_name found"
    else
        error_msg "$iface_name not found!"
    fi
}

check_iface2() {
    local iface_name="$1"
    if ! ip addr show "$1" ; then
        error_msg "$iface_name not found!"
    fi
}

check_dmesg() {
    local dmesg_output=""
    local set_error=0
    dmesg_output=$(dmesg | grep -E "pileft|piright")
    if [ -n "$dmesg_output" ]; then
        info_msg "pileft|piright outputs in dmesg"
        echo "$dmesg_output"

        if echo "$dmesg_output" | grep "received data packet without connection"; then
            warn_msg "received data packet without connection"
            set_error=1
        fi

        if echo "$dmesg_output" | grep "no process image synchronization"; then
            warn_msg "no process image synchronization"
            set_error=1
        fi

        if echo "$dmesg_output" | grep "timeout"; then
            warn_msg "timeout"
            set_error=1
        fi

        if [ "$set_error" -eq 1 ]; then
            error_msg "error(s) ocurred.. Check output of dmesg or warning messages above"
        fi

    fi
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "pileft-1")
        check_iface1 pileft
        ;;
    "pileft-2")
        check_iface2 pileft
        ;;
    "piright-1")
        check_iface1 piright
        ;;
    "piright-2")
        check_iface2 piright
        ;;
    "dmesg")
        check_dmesg
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

for t in $TESTS; do
    run "$t"
done
