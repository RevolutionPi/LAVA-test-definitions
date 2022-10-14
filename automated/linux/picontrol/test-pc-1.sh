#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

dmesg | grep -i picontrol
if [ $? -eq 0 ]
then
	lava-test-case "$TEST_CASE_NAME-1" --result pass
else
	lava-test-case "$TEST_CASE_NAME-1" --result fail
	lava-test-raise "$TEST_CASE_NAME FAIL"
fi

ls -l /dev/pi* | grep /dev/piControl0
if [ $? -eq 0 ]
then
	lava-test-case "$TEST_CASE_NAME-2" --result pass
else
	lava-test-case "$TEST_CASE_NAME-2" --result fail
	lava-test-raise "$TEST_CASE_NAME FAIL"
fi
