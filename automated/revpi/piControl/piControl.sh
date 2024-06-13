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
    apt-get update -q
    apt-get -y install coreutils
}

check_dmesg() {
    local log_level="$1"
    local param_grep="$2"
    local dmesg_output=""
    dmesg_output="$(dmesg -l "$log_level" \
        | grep -E "$param_grep" \
        | grep -v "loading out-of-tree module taints kernel.")"
    if [ -n "$dmesg_output" ]; then
        info_msg "Something went wrong..."
        info_msg "log_level: $log_level"
        info_msg "param_grep: $param_grep"
        echo "$dmesg_output"
        report_fail "piControl error(s) occured. Check output of warning messages above."
        return 1
    fi
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
      "pc-1")
          info_msg "Output piControl in dmesg"
          dmesg | grep piControl

          check_dmesg "emerg,alert,crit,err,warn" "piControl"
          check_return "${test_case_id}"
          # Catch errors or failures from other levels
          check_dmesg "notice,info,debug" "piControl.*fail|piControl.*err|piControl.*incorrect"
          ;;
      "pc-2")
          info_msg "Image test: pc-2"
          if [ -e "/dev/piControl*" ]; then
            report_fail "pc-2 failed: /dev/piControl* doesn't exist"
          fi
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
