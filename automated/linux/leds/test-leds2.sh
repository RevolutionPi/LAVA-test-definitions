#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

#LED_TIME: LED on/off time.
LED_TIME=1

LEDS_CORE=(
	"a1_green"
	"a1_red"
	"a2_green"
	"a2_red"
)

for i in {0..3}
do
	echo ${LEDS_CORE[$i]}
	echo 1 > /sys/class/leds/${LEDS_CORE[$i]}/brightness
	sleep $LED_TIME
	echo 0 > /sys/class/leds/${LEDS_CORE[$i]}/brightness
done

# TODO: This test should be modified for external hardware...
lava-test-case "$TEST_CASE_NAME" --result pass
