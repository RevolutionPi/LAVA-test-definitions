#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

declare -a LEDS_CORE=(
	"/sys/class/leds/a1_green"
	"/sys/class/leds/a1_red"
	"/sys/class/leds/a2_green"
	"/sys/class/leds/a2_red"
	"/sys/class/leds/default-on"
	"/sys/class/leds/mmc0"
	"/sys/class/leds/power_red"
)

for i in "${LEDS_CORE[@]}"
do
	if [[ -d "$i" ]];
	then
		lava-test-case "$TEST_CASE_NAME-$i" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i" --result fail
	fi
done
