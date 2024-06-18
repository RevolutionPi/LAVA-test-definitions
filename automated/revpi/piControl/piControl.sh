#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pc-1 pc-2"
SKIP_INSTALL=false
PICONTROL_DEV="/dev/piControl0"

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
        warn_msg "piControl error(s) occured. Check output of warning messages above."

        return "$(echo "$dmesg_output" | wc -l)"
    fi
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
          if [ -e "$PICONTROL_DEV" ]; then
              report_pass "$test_case_id"
          else
              report_fail "$test_case_id failed: $PICONTROL_DEV doesn't exist"
          fi
          ;;
    esac
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
