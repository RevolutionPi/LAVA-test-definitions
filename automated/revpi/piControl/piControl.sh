#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="dmesg dev"

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
    # shellcheck disable=SC2154
    case "${dist}" in
      debian) install_deps "coreutils" "${SKIP_INSTALL}";;
      unknown|*) warn_msg "Unsupported distro: package install skipped" ;;
    esac
}

run() {
    # shellcheck disable=SC3043
    local test="$1"
    test_case_id="${test}"
    echo
    info_msg "Running ${test_case_id} test..."

    case "$test" in
      "dmesg")
          info_msg "Image test: PC-1"
          dmesg | grep piControl
          ;;
      "dev")
          info_msg "Image test: PC-2"
          ls /dev/piControl*
          ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

install
for t in $TESTS; do
    run "$t"
done
