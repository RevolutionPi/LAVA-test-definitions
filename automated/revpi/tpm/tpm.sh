#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="tpm-1"
SKIP_INSTALL="false"
PISERIAL_SERIAL_NR=""
PISERIAL_PASS=""

usage() {
    echo "Usage: $0 [-s <true|false>] [-t test] -S <device-serial-nr> -P <revpi-password>" 1>&2
    exit 1
}

while getopts "s:t:S:P:h" o; do
    case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    S) PISERIAL_SERIAL_NR="${OPTARG}" ;;
    P) PISERIAL_PASS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

install() {
    install_deps "piserial tpm2-tools"
}

run() {
    local test_case_id="$1"
    local piserial_output=""
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "tpm-1")
        piserial_output="$(piSerial -s)"
        echo "piSerial serial number: $piserial_output"
        if [ "$piserial_output" != "$PISERIAL_SERIAL_NR" ]; then
            error_msg "${test_case_id} Serial number not ok! (output: $piserial_output, actual: $PISERIAL_SERIAL_NR)"
        fi

        piserial_output="$(piSerial -p)"
        echo "piSerial password: $piserial_output"
        if [ "$piserial_output" != "$PISERIAL_PASS" ]; then
            error_msg "${test_case_id} Password not ok! (output: $piserial_output, actual: $PISERIAL_PASS)"
        fi
        ;;
    "tpm-2")
        if ! tpm2_getcap --capability="properties-fixed" ; then
            error_msg "${test_case_id} fail!"
        fi
        ;;
    "tpm-2b")
        if ! tpm2_getcap properties-fixed ; then
            error_msg "${test_case_id} fail!"
        fi
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run
create_out_dir "${OUTPUT}"

if [ -z "$PISERIAL_SERIAL_NR" ] || [ -z "$PISERIAL_PASS" ]; then
  echo "Options -S and -P are mandatory." >&2
  usage
fi

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done
