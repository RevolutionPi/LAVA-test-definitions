#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

echo "Test echo with script - LAVA for RevPi Devices"

# Each test case has a name and a result.
# Optionally, test cases can have measurements and units.
# lava-test-case will not halt the test job immediately if result fail.
lava-test-case "$TEST_CASE_NAME-example-pass" --result pass
lava-test-case "$TEST_CASE_NAME-example-fail" --result fail

# Custom scripts should check the return code of setup operations
# and use lava-test-raise to halt the test job immediately
# if a setup error occurs.
# This makes triage much easier as it puts the failure much closer
# to the actual cause within the log file.
# Use: lava-test-raise "message from test shell".
# The rest of the test job will not run.
# Example:
#lava-test-raise "Error title. State of Job will show as Incompleted.FAIL"
