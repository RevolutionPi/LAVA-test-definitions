#!/bin/bash

source ../../../lib/piTest.sh

test-pt-compact-d-1() {
    piTest_Check_001 "test-compact-pt" "DI1" "DO1"
    piTest_Check_001 "test-compact-pt" "DI2" "DO2"
}

test-pt-compact-a-1() {
    piTest_Check_002 "test-compact-analog-01" "AI2" "AO1"
    piTest_Check_002 "test-compact-analog-01" "AI1" "AO2"
}

test-pt-flat-da-1() {
    piTest_setIOValue "test-flat-digital" "DOut" "1"
    piTest_Check_002 "test-flat-analog" "AIn" "AOut"
    piTest_setIOValue "test-flat-digital" "DOut" "0"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 TEST_CASE_NAME INPUT OUTPUT" >&2
    exit 1
fi

# call given function
$1
