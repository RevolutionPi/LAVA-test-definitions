#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

dd if=/dev/sda1 of=/dev/null status=progress conv=sync iflag=nocache oflag=nocache bs=1k count=1M
RET=$?

if [ $RET -eq 0 ]
then
    lava-test-case "$TEST_CASE_NAME" --result pass
else
    lava-test-case "$TEST_CASE_NAME" --result fail
    lava-test-raise "$TEST_CASE_NAME FAIL - Unable to read from USB flash disk"
fi
