#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="picontrol-usage picontrol-usage-write picontrol-usage-stress"
TEST_PROG_VERSION="HEAD"
TEST_GIT_URL=https://gitlab.com/revolutionpi/internal-tools/benchmark.git
TEST_PROGRAM=revpi-benchmark
TEST_DIR="$(pwd)/${TEST_PROGRAM}"
TEST_SCRIPT_DIR="${TEST_DIR}/picontrol_usage"
RUNTIME_SEC=60
BYTES=512
MAX_MS=5
PROCESSES=1

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS] [-r RUNTIME_SEC] [-b BYTES] [-m MAX_MS] [-p PROCESSES]" 1>&2
    exit 1
}

while getopts "s:t:r:b:m:p:h" o; do
    case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    r) RUNTIME_SEC="${OPTARG}" ;;
    b) BYTES="${OPTARG}" ;;
    m) MAX_MS="${OPTARG}" ;;
    p) PROCESSES="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "picontrol-usage")
        # Basic read-only test
        "${TEST_SCRIPT_DIR}"/picontrol-usage -t "${RUNTIME_SEC}" -b "${BYTES}" -m "${MAX_MS}"
        check_return "$test_case_id"
        ;;
    "picontrol-usage-write")
        # Read/write test (simulates CODESYS/RevPiModIO)
        "${TEST_SCRIPT_DIR}"/picontrol-usage -w -t "${RUNTIME_SEC}" -b "${BYTES}" -m "${MAX_MS}"
        check_return "$test_case_id"
        ;;
    "picontrol-usage-stress")
        # Multi-process stress test with CPU load
        stress --cpu 4 &
        "${TEST_SCRIPT_DIR}"/picontrol-usage -w -t "${RUNTIME_SEC}" -b "${BYTES}" -m "${MAX_MS}" -p "${PROCESSES}"
        check_return "$test_case_id"

        pkill stress
        ;;
    *) error_msg "Unknown test case: ${test_case_id}" ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "git stress python3" "${SKIP_INSTALL}"

get_test_program "${TEST_GIT_URL}" "${TEST_DIR}" "${TEST_PROG_VERSION}" "${TEST_PROGRAM}"

for t in $TESTS; do
    run "$t"
done
