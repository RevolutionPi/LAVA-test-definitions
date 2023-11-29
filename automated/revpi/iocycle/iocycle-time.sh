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

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS]" 1>&2
    exit 1
}

while getopts "s:t:c:h" o; do
  case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    c) C_TIME="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

install() {
    dist_name

    apt-get update -q
    apt-get -y install git stress python3-revpimodio2 jq bc
}

run() {
    # shellcheck disable=SC3043
    local test="$1"
    test_case_id="${test}"
    info_msg "Running ${test_case_id} test..."

    case "$test" in
        "iocycle-time")
            ;;
        "iocycle-time-stress")
            stress --cpu 4 &
            ;;
    esac

    output=$("${TEST_SCRIPT_DIR}"/pibridge-cycle-time -s "${C_TIME}" 2>/dev/null)
    echo "$output"
    mean_ms=$(echo "$output" | jq -r '.mean_ms')
    if [ "$(echo "$mean_ms > 20" | bc)" -eq "1" ]; then
        error_msg "${test_case_id}-mean_ms-${mean_ms}"
    else
        info_msg "${test_case_id}-mean_ms-${mean_ms}"
    fi

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

get_test_program "${TEST_GIT_URL}" "${TEST_DIR}" "${TEST_PROG_VERSION}" "${TEST_PROGRAM}"

for t in $TESTS; do
    run "$t"
done
