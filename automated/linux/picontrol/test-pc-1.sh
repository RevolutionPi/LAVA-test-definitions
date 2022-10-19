#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

if dmesg | grep -i picontrol
then
	lava-test-case "$TEST_CASE_NAME-1" --result pass
else
	lava-test-case "$TEST_CASE_NAME-1" --result fail
fi

if ls -l /dev/piControl0*
then
	lava-test-case "$TEST_CASE_NAME-2" --result pass
else
	lava-test-case "$TEST_CASE_NAME-2" --result fail
fi
