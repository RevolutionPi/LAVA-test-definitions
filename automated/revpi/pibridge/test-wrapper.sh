#!/bin/bash

source ../../lib/piTest.sh

test-pb-3() {
    piTest_Check_001 "test-pb-3" "DIO_R1_I1" "DIO_R1_O1"
}

test-pb-4() {
    piTest_Check_001 "test-pb-4" "DIO_L1_I1" "DIO_L1_O1"
}

test-pb-5() {
    piTest_Check_001 "test-pb-5" "MIO_R1_DI2" "MIO_R1_DO1"
}

test-pb-6() {
    piTest_Check_001 "test-pb-6" "MIO_L1_DI2" "MIO_L1_DO1"
}

test-pb-7() {
    piTest_Check_001 "test-pb-7-mio" "MIO_L2_DI2" "MIO_L2_DO1"
    piTest_Check_001 "test-pb-7-dio" "DIO_L1_I1" "DIO_L1_O1"
}

test-pb-8() {
    piTest_Check_001 "test-pb-8-mio" "MIO_R2_DI2" "MIO_R2_DO1"
    piTest_Check_001 "test-pb-8-dio" "DIO_R1_I1" "DIO_R1_O1"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 TEST_CASE_NAME INPUT OUTPUT" >&2
    exit 1
fi

# call given function
$1
