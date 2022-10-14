#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

HW_UPDATE="The\sfirmware\sof\ssome\sI/O\smodules\smust\sbe\supdated."
HW_NOT_PRESENT="Module\sis\sNOT\spresent"

piTest -x
RET=$?
if [ $RET -eq 0 ]
then
    piTest -d | grep $HW_NOT_PRESENT
    RET=$?

    if [ $RET -ne 0 ]
    then
        lava-test-case "$TEST_CASE_NAME-$HW_NOT_PRESENT-pass" --result pass
    else
        lava-test-case "$TEST_CASE_NAME-$HW_NOT_PRESENT-fail" --result fail
        lava-test-raise "$TEST_CASE_NAME FAIL: DUT constellation must be checked! At least one module is NOT present, data is NOT available: $RET"
    fi

    #Check Module-UPDATE
    piTest -d | grep $HW_UPDATE
    if [ $? -eq 0 ]
    then
        lava-test-case "$TEST_CASE_NAME-$HW_UPDATE" --result fail
    fi
else
    lava-test-case "$TEST_CASE_NAME-piText-x-fail" --result fail
    lava-test-raise "$TEST_CASE_NAME FAIL: piTest -x ERROR: $RET"
fi
