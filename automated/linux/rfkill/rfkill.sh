#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

TESTS="wlan-disabled bluetooth-disabled"

usage() {
    echo "Usage: $0 [-t tests]"
    exit "$1"
}

while getopts "t:h" o; do
    case "$o" in
    t) TESTS="${OPTARG}" ;;
    h) usage ;;
    *) usage 1 >&2 ;;
    esac
done

# check device states
rfkill_check_devices_state() {
    local test_case_id="$1"
    local dev_type="$2"
    local state="$3"
    local rfkill_output
    local dev_ifs dev_ifs_len dev_idx=0
    local dev_if dev_if_state dev_if_dev
    local failed=""

    if ! rfkill_output="$(rfkill --json)"; then
        error_msg "failed to run rfkill"
    fi

    if ! dev_ifs="$(echo "$rfkill_output" |
        jq -r ".rfkilldevices | map(select(.type == \"$dev_type\"))")"; then
        printf "Unable to get devices of type '%s'\n" "$dev_type" >&2
        report_fail "$test_case_id"
        return 1
    fi

    if ! dev_ifs_len="$(printf "%s\n" "$dev_ifs" | jq -r '. | length')"; then
        printf "Unable to determine amount of devices of type '%s'\n" \
            "$dev_type" >&2
        report_fail "$test_case_id"
        return 1
    fi

    if [ "$dev_ifs_len" -eq 0 ]; then
        printf "No devices of type '%s' found, skipping\n" "$dev_type"
        report_skip "$test_case_id"
        return 0
    fi

    report_set_start "$test_case_id-devices"
    while [ "$dev_idx" -lt "$dev_ifs_len" ]; do
        dev_if="$(printf "%s\n" "$dev_ifs" | jq -r ".[$dev_idx]")"
        dev_if_state="$(printf "%s\n" "$dev_if" | jq -r '.soft')"
        dev_if_dev="$(printf "%s\n" "$dev_if" | jq -r '.device')"
        if [ "$dev_if_state" != "$state" ]; then
            printf "%s dev '%s' has wrong state (expected: %s, actual: %s)\n" \
                "$dev_type" "$dev_if_dev" "$state" "$dev_if_state"
            failed=true
            report_fail "$test_case_id-$dev_if_dev"
        else
            report_pass "$test_case_id-$dev_if_dev"
        fi

        dev_idx=$((dev_idx + 1))
    done
    report_set_stop

    if [ "$failed" ]; then
        report_fail "$test_case_id"
    else
        report_pass "$test_case_id"
    fi

    return 0
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    wlan-disabled)
        rfkill_check_devices_state wlan-disabled wlan blocked
        ;;
    bluetooth-disabled)
        rfkill_check_devices_state bluetooth-disabled bluetooth blocked
        ;;
    *)
        report_fail "Undefined test..."
        ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "rfkill jq"

for t in $TESTS; do
    run "$t"
done
