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

run() {
    local test_case_id="$1"
    local piserial_output=""
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "tpm-1")
        piserial_output="$(piSerial -s)"
        info_msg "piSerial serial number: $piserial_output"
        run_test_case \
            "[ '$piserial_output' = '$PISERIAL_SERIAL_NR' ]" \
            "$test_case_id-serial"

        piserial_output="$(piSerial -p)"
        info_msg "piSerial password: $piserial_output"
        run_test_case \
            "[ '$piserial_output' = '$PISERIAL_PASS' ]" \
            "$test_case_id-password"
        ;;
    "tpm-2")
        run_test_case \
            'tpm2_getcap --capability="properties-fixed"' \
            "$test_case_id"
        ;;
    "tpm-2b")
        run_test_case \
            'tpm2_getcap properties-fixed' \
            "$test_case_id"
        ;;
    esac
}

# Test run
create_out_dir "${OUTPUT}"

if [ -z "$PISERIAL_SERIAL_NR" ] || [ -z "$PISERIAL_PASS" ]; then
    echo "Options -S and -P are mandatory." >&2
    usage
fi

install_deps "piserial tpm2-tools" "$SKIP_INSTALL"

for t in $TESTS; do
    run "$t"
done
