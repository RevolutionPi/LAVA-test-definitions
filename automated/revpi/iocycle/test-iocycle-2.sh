#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

SHOW_JSON=$1
MAX_MS=$2
MEASUREMENT_TIME=$3

if ! dpkg-query -W -f='${Status}\n' jq;
then
    apt-get update
    apt-get install -y jq
fi

if [ $MEASUREMENT_TIME -ne 0 ] && [ $MEASUREMENT_TIME -le 300 ]
then
    RET_CYCLE_TIME=$(python3 pibridge-cycle-time -s${MEASUREMENT_TIME})
else
    RET_CYCLE_TIME=$(python3 pibridge-cycle-time)
fi

if [ "$SHOW_JSON" -ne 0 ]
then
    echo "$RET_CYCLE_TIME"
fi

if [ "$(echo "$RET_CYCLE_TIME" | jq '.max_ms')" -eq 0 ]
then
    lava-test-case "$TEST_CASE_NAME-max_ms-zero" --result fail
else
    if [ "$(echo "$RET_CYCLE_TIME" | jq '.max_ms')" -le "$MAX_MS" ]
    then
        lava-test-case "$TEST_CASE_NAME-max_ms" --result pass
    else
        lava-test-case "$TEST_CASE_NAME-max_ms" --result fail
    fi
fi
