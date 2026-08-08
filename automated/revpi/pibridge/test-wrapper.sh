#!/bin/bash

# shellcheck disable=SC2317,SC2329

# shellcheck disable=SC1091
source ../../lib/piTest.sh

piTest_Check_001() (
    # $1: TEST_CASE_NAME
    # $2: INPUT
    # $3: OUTPUT
    test_case_name=$1
    input=$2
    output=$3

    # set output to low
    if ! piTest_setIOValue "$output" "$LOW"; then
        report_fail "$test_case_name-$input-low"
        return 1
    fi
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validateIOValue "$input" "$LOW"; then
        report_pass "$test_case_name-$input-low"
    else
        report_fail "$test_case_name-$input-low"
    fi

    # set output to high
    if ! piTest_setIOValue "$output" "$HIGH"; then
        report_fail "$test_case_name-$input-high"
        return 1
    fi
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validateIOValue "$input" "$HIGH"; then
        report_pass "$test_case_name-$input-high"
    else
        report_fail "$test_case_name-$input-high"
    fi
)

test-pb-3() {
    piTest_Check_001 "pb-3" "DIO_R1_I1" "DIO_R1_O1"
}

test-pb-4() {
    piTest_Check_001 "pb-4" "DIO_L1_I1" "DIO_L1_O1"
}

test-pb-5() {
    piTest_Check_001 "pb-5" "MIO_R1_DI2" "MIO_R1_DO1"
}

test-pb-6() {
    piTest_Check_001 "pb-6" "MIO_L1_DI2" "MIO_L1_DO1"
}

test-pb-7() {
    piTest_Check_001 "pb-7-mio" "MIO_L2_DI2" "MIO_L2_DO1"
    piTest_Check_001 "pb-7-dio" "DIO_L1_I1" "DIO_L1_O1"
}

test-pb-8() {
    piTest_Check_001 "pb-8-mio" "MIO_R2_DI2" "MIO_R2_DO1"
    piTest_Check_001 "pb-8-dio" "DIO_R1_I1" "DIO_R1_O1"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 TEST_CASE_NAME INPUT OUTPUT" >&2
    exit 1
fi

# call given function
$1

exit 0
