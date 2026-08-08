#!/bin/bash

# shellcheck disable=SC2317,SC2329

# shellcheck disable=SC1091
source ../../lib/piTest.sh

check_io() {
    local test_name="$1" output="$2" input="$3"
    if ! piTest_setIOValue "$output" "$LOW"; then
        report_fail "$test_name"
        return 1
    fi
    if ! piTest_validateIOValue "$input" "$LOW"; then
        report_fail "$test_name"
        return 1
    fi
    if ! piTest_setIOValue "$output" "$HIGH"; then
        report_fail "$test_name"
        return 1
    fi
    piTest_validateIOValue "$input" "$HIGH"
    check_return "$test_name"
}

test-pb-3() {
    check_io "pb-3-DIO_R1_I1" "DIO_R1_O1" "DIO_R1_I1"
}

test-pb-4() {
    check_io "pb-4-DIO_L1_I1" "DIO_L1_O1" "DIO_L1_I1"
}

test-pb-5() {
    check_io "pb-5-MIO_R1_DI2" "MIO_R1_DO1" "MIO_R1_DI2"
}

test-pb-6() {
    check_io "pb-6-MIO_L1_DI2" "MIO_L1_DO1" "MIO_L1_DI2"
}

test-pb-7() {
    local ret=0
    check_io "pb-7-mio-MIO_L2_DI2" "MIO_L2_DO1" "MIO_L2_DI2" || ret=$?
    check_io "pb-7-dio-DIO_L1_I1"  "DIO_L1_O1"  "DIO_L1_I1"  || ret=$?
    return "${ret}"
}

test-pb-8() {
    local ret=0
    check_io "pb-8-mio-MIO_R2_DI2" "MIO_R2_DO1" "MIO_R2_DI2" || ret=$?
    check_io "pb-8-dio-DIO_R1_I1"  "DIO_R1_O1"  "DIO_R1_I1"  || ret=$?
    return "${ret}"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 TEST_CASE_NAME INPUT OUTPUT" >&2
    exit 1
fi

# call given function
$1

exit 0
