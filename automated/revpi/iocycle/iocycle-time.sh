#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="iocycle-time iocycle-time-stress"
TEST_PROG_VERSION="HEAD"
TEST_GIT_URL=https://gitlab.com/revolutionpi/internal-tools/benchmark.git
TEST_PROGRAM=revpi-benchmark
TEST_DIR="$(pwd)/${TEST_PROGRAM}"
TEST_SCRIPT_DIR="${TEST_DIR}/pibridge_cycle_time"
C_TIME=300
MEAN_MS=20
stress_pid=""

stop_stress() {
    if [ -n "$stress_pid" ]; then
        kill "$stress_pid" 2>/dev/null || true
        wait "$stress_pid" 2>/dev/null || true
        stress_pid=""
    fi
}

trap stop_stress EXIT HUP INT TERM

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS]" 1>&2
    exit 1
}

while getopts "s:t:c:T:h" o; do
    case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    c) C_TIME="${OPTARG}" ;;
    T) MEAN_MS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

run() {
    local test_case_id="$1"
    local result=""
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "iocycle-time")
        ;;
    "iocycle-time-stress")
        # using background_process_start and *_stop doesn't work here as stress
        # spawns multiple processes in a weird way. Killing one doesn't stop the
        # others.
        stress --cpu "$(nproc)" &
        stress_pid=$!
        ;;
    *) error_msg "Invalid test case '$test_case_id'" ;;
    esac

    if ! output=$("${TEST_SCRIPT_DIR}"/pibridge-cycle-time -s "${C_TIME}"); then
        warn_msg "cycle-time measurement failed"
        report_fail "$test_case_id"
        stop_stress
        return 1
    fi
    echo "$output"
    if ! mean_ms=$(echo "$output" | jq -er '.mean_ms | numbers'); then
        warn_msg "cycle-time measurement returned invalid JSON"
        report_fail "$test_case_id"
        stop_stress
        return 1
    fi
    if [ "$(echo "$mean_ms > $MEAN_MS" | bc)" -eq "1" ]; then
        result=fail
        report_fail "$test_case_id"
    else
        result=pass
        report_pass "$test_case_id"
    fi
    add_metric "${test_case_id}-metric" "$result" "$mean_ms" milliseconds

    if [ "$test_case_id" = "iocycle-time-stress" ]; then
        stop_stress
    fi
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "git stress python3-revpimodio2 jq bc" "$SKIP_INSTALL"

get_test_program "${TEST_GIT_URL}" "${TEST_DIR}" "${TEST_PROG_VERSION}" "${TEST_PROGRAM}"

for t in $TESTS; do
    run "$t"
done

exit 0
