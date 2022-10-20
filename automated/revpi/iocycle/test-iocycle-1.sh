#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

if [ "$(piTest -q -1 -rRevPiIOCycle)" -le 10 ]
then
    lava-test-case "$TEST_CASE_NAME-pass" --result pass
else
    lava-test-case "$TEST_CASE_NAME-fail" --result fail
fi
