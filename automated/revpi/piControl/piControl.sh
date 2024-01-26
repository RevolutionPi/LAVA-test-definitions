#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pc-1 pc-2"
SKIP_INSTALL=false

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS]" 1>&2
    exit 1
}

while getopts "s:t:h" o; do
  case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

install() {
    dist_name

    apt-get update -q
    apt-get -y install coreutils
}

run() {
    # shellcheck disable=SC3043
    local test="$1"
    test_case_id="${test}"
    echo
    info_msg "Running ${test_case_id} test..."

    case "$test" in
      "pc-1")
          info_msg "Image test: pc-1"
          dmesg | grep piControl
          ;;
      "pc-2")
          info_msg "Image test: pc-2"
          ls /dev/piControl*
          ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done
