#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="rtc-1 rtc-2"
DATE_SET="2023-12-01 11:11:00"
TOLERANCE_LOW_SEC=10

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS] [-d DATE_SET]" 1>&2
    echo "Example: $0 -s true -t 'rtc-1 rtc-2' -d '2023-12-01 11:11:00'" 1>&2
    exit 1
}

while getopts "s:t:d:h" o; do
    case "$o" in
    s)
        . /etc/os-release
        if [ "${VERSION_ID:-0}" -ge 12 ]; then
            install_deps util-linux-extra
        fi
        ;;
    t) TESTS="${OPTARG}" ;;
    d) DATE_SET="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_hwclock() {
    EXPECTED_TIME="$1"
    TOLERANCE_MINUTES="$2"
    TOLERANCE_SECONDS=$((TOLERANCE_MINUTES * 60))

    if [ "$TOLERANCE_SECONDS" -lt "$TOLERANCE_LOW_SEC" ]; then
        TOLERANCE_SECONDS=$TOLERANCE_LOW_SEC
    fi

    # Convert the date strings to epoch timestamps
    EXPECTED_TIMESTAMP=$(date -d "$EXPECTED_TIME" +%s)
    HWCLOCK_TIMESTAMP=$(date -d "$(hwclock)" +%s)

    # Calculate the difference in seconds between expected and actual timestamps
    TIME_DIFF=$((HWCLOCK_TIMESTAMP - EXPECTED_TIMESTAMP))

    info_msg "Expected timestamp: $EXPECTED_TIMESTAMP"
    info_msg "hwclock timestamp: $HWCLOCK_TIMESTAMP"
    info_msg "Tolerance in seconds: $TOLERANCE_SECONDS"

    # Check if the difference is within the tolerance
    if [ "$TIME_DIFF" -lt "$TOLERANCE_SECONDS" ]; then
        info_msg "hwclock is correct after setting."
        return 0
    else
        warn_msg "hwclock is not correct after setting."
        return 1
    fi
}

rtc_1() {
    local test_case_id=rtc-1

    info_msg "Set hardware clock to $DATE_SET"
    hwclock --set --date "$DATE_SET"
    # Check if hwclock is correct after setting
    if ! check_hwclock "$DATE_SET"; then
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

rtc_2() {
    local test_case_id=rtc-2

    # Disable NTP, set hardware clock to "$DATE_SET"
    timedatectl set-ntp false
    info_msg "Set hardware clock to $DATE_SET"
    hwclock --set --date "$DATE_SET"
    if ! check_hwclock "$DATE_SET"; then
        report_fail "$test_case_id"
        timedatectl set-ntp true
        return 1
    fi

    # Sync hardware clock to system clock and verify
    hwclock --hctosys

    HWCLOCK_TIMESTAMP="$(date -d "$(hwclock --show)" +%s)"
    SYSTEM_TIMESTAMP="$(date +%s)"
    TIME_DIFF=$((HWCLOCK_TIMESTAMP - SYSTEM_TIMESTAMP))
    [ "$TIME_DIFF" -lt 0 ] && TIME_DIFF=$((-TIME_DIFF))

    info_msg "hwclock timestamp: $HWCLOCK_TIMESTAMP"
    info_msg "System timestamp: $SYSTEM_TIMESTAMP"
    info_msg "Difference: $TIME_DIFF seconds"

    timedatectl set-ntp true

    if [ "$TIME_DIFF" -lt "$TOLERANCE_LOW_SEC" ]; then
        report_pass "$test_case_id"
    else
        report_fail "$test_case_id"
        return 1
    fi
}

run() {
    local test="$1"
    test_case_id="${test}"
    info_msg "Running ${test_case_id} test..."

    case "$test" in
    "rtc-1") rtc_1 ;;
    "rtc-2") rtc_2 ;;
    *) error_msg "Invalid test case '$test_case_id'" ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

for t in $TESTS; do
    run "$t"
done

exit 0
