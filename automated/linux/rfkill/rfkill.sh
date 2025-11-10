#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

TESTS="wlan-disabled"

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

check_wlan_disabled() {
    local test_case="check-wlan-disabled"
    local rfkill_output
    local wlan_states
    local wlan_device wlan_soft_state wlan_hard_state

    if ! rfkill_output="$(rfkill --json)"; then
        error_msg "failed to run rfkill"
    fi

    if ! wlan_states="$(echo "$rfkill_output" | jq -r '.rfkilldevices[] | select(.type == "wlan") | [.] | map(.device + ":" + .soft + ":" + .hard) | .[]')"; then
        error_msg "failed to run jq"
    fi

    report_set_start "$test_case"
    for line in $wlan_states; do
        wlan_device="$(echo "$line" | cut -d':' -f1)"
        wlan_soft_state="$(echo "$line" | cut -d':' -f2)"
        wlan_hard_state="$(echo "$line" | cut -d':' -f3)"

        if [ "$wlan_soft_state" = "unblocked" ] \
            && [ "$wlan_hard_state" = "unblocked" ]; then
            report_fail "$test_case-$wlan_device"
        else
            report_pass "$test_case-$wlan_device"
        fi
    done
    report_set_stop
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    "wlan-disabled")
        check_wlan_disabled
        ;;
    *)
        report_fail "Undefined test..."
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "rfkill jq"

for t in $TESTS; do
    run "$t"
done
