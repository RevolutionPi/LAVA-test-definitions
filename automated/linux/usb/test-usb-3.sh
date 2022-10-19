#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

if dd if=/dev/sda1 of=/dev/null status=progress conv=sync iflag=nocache oflag=nocache bs=1k count=1M
then
    lava-test-case "$TEST_CASE_NAME" --result pass
else
    lava-test-case "$TEST_CASE_NAME" --result fail
fi
