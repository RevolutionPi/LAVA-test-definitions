#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

HW_UPDATE="The\sfirmware\sof\ssome\sI/O\smodules\smust\sbe\supdated."
HW_NOT_PRESENT="Module\sis\sNOT\spresent"

if piTest -x
then
    if piTest -d | grep $HW_NOT_PRESENT
    then
        lava-test-case "$TEST_CASE_NAME-$HW_NOT_PRESENT-pass" --result pass
    else
        lava-test-case "$TEST_CASE_NAME-$HW_NOT_PRESENT-fail" --result fail
    fi

    #Check Module-UPDATE
    if piTest -d | grep $HW_UPDATE
    then
        lava-test-case "$TEST_CASE_NAME-$HW_UPDATE" --result fail
    fi
else
    lava-test-case "$TEST_CASE_NAME-piText-x-fail" --result fail
fi
