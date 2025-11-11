#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pc-1 pc-2 pc-perms pc-cycle-time-sample"
SKIP_INSTALL=false
PICONTROL_DEV="/dev/piControl0"
PICONTROL_SYSFS_PATH="/sys/class/piControl/piControl0"
EFFECTIVE_MIN_CYCLE_TIME=15000

usage() {
    echo "Usage: $0 [-e <min cycle time in us] [-s <true|false>] [-t TESTS]" 1>&2
    exit 1
}

while getopts "e:s:t:h" o; do
    case "$o" in
    e) EFFECTIVE_MIN_CYCLE_TIME="${OPTARG}" ;;
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_dmesg() {
    local log_level="$1"
    local param_grep="$2"
    local dmesg_output=""

    dmesg_output="$(dmesg -l "$log_level" \
        | grep -E "$param_grep" \
        | grep -v "loading out-of-tree module taints kernel.")"

    # Check existance of HAT EEPROM according to document:
    # https://gitlab.com/revolutionpi/revpi-hat-eeprom/blob/master/docs/RevPi-HAT-EEPROM-Format.md#custom-atoms
    if [ ! -e /proc/device-tree/hat/custom_1 ]; then
        dmesg_output="$(echo "$dmesg_output" \
            | grep -v "No HAT eeprom detected: Fallback to default serial")"
    fi

    if [ -n "$dmesg_output" ]; then
        info_msg "Something went wrong..."
        info_msg "log_level: $log_level"
        info_msg "param_grep: $param_grep"
        echo "$dmesg_output"
        warn_msg "piControl error(s) occured. Check output of warning messages above."

        return "$(echo "$dmesg_output" | wc -l)"
    fi
}

pc_cycle_time_sample() {
    local last_cycle_time cycle_duration cycle_diff

    last_cycle_time="$(cat $PICONTROL_SYSFS_PATH/last_cycle)"
    cycle_duration="$(cat $PICONTROL_SYSFS_PATH/cycle_duration)"

    # the cycle_duration can be set as low as 500 microseconds, which is "as
    # fast as possible". devices usually hover around 12000-15000 microseconds
    # depending on the setup, so make sure the lowest realistic value is taken
    # for the test
    if [ "$cycle_duration" -lt "$EFFECTIVE_MIN_CYCLE_TIME" ]; then
        cycle_duration="$EFFECTIVE_MIN_CYCLE_TIME"
    fi

    cycle_diff="$(printf "%d" \
        "$((last_cycle_time - cycle_duration))" | cut -d'-' -f2)"

    info_msg "cycle_duration: $cycle_duration, last_cycle_time: $last_cycle_time, cycle_diff: $cycle_diff"

    [ "$cycle_diff" -lt 1500 ]
    check_return pc-cycle-time-sample
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "pc-1")
        local errors
        local res

        info_msg "Output piControl in dmesg"
        dmesg | grep piControl

        check_dmesg "emerg,alert,crit,err,warn" "piControl"
        errors=$?
        if [ $errors -gt 0 ]; then
            res=fail
        else
            res=pass
        fi
        add_metric "$test_case_id-errors" "$res" "$errors" lines

        # Catch errors or failures from other levels
        check_dmesg "notice,info,debug" "piControl.*fail|piControl.*err|piControl.*incorrect"
        errors=$?
        if [ $errors -gt 0 ]; then
            res=fail
        else
            res=pass
        fi
        add_metric "$test_case_id-missed-errors" "$res" "$errors" lines
        ;;
    "pc-2")
        run_test_case "[ -e '$PICONTROL_DEV' ]" "$test_case_id"
        ;;
    "pc-perms")
        # permissions for /dev/piControl0 have only been introduced in
        # bookworm. skip this test for all versions before bookworm.
        . /etc/os-release
        if [ "$VERSION_ID" -lt 12 ]; then
            info_msg "Release is $VERSION (<12), skipping $test_case_id"
            report_skip "$test_case_id-picontrol-dev-permissions-660"
            report_skip "$test_case_id-picontrol-dev-group-picontrol"
            return
        fi

        run_test_case \
            "[ '$(stat -c "%a" "$PICONTROL_DEV")' = '660' ]" \
            "$test_case_id-picontrol-dev-permissions-660"

        run_test_case \
            "[ '$(stat -c "%G" "$PICONTROL_DEV")' = 'picontrol' ]" \
            "$test_case_id-picontrol-dev-group-picontrol"
        ;;
    pc-cycle-time-sample) pc_cycle_time_sample ;;
    *) error_msg "Invalid test case '$test_case_id'" ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps coreutils "$SKIP_INSTALL"

for t in $TESTS; do
    run "$t"
done
