#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

#LED_TIME: LED on/off time.
LED_TIME=1

LED_BASE="/sys/class/leds"

declare -a LEDS_CORE=(
	"$LED_BASE/a1_green"
	"$LED_BASE/a1_red"
	"$LED_BASE/a2_green"
	"$LED_BASE/a2_red"
	"$LED_BASE/default-on"
	"$LED_BASE/mmc0"
	"$LED_BASE/power_red"
)

declare -a LEDS_CONNECT=(
	"$LED_BASE/a1_green"
	"$LED_BASE/a1_red"
	"$LED_BASE/a2_green"
	"$LED_BASE/a2_red"
	"$LED_BASE/a3_green"
	"$LED_BASE/a3_red"
	"$LED_BASE/default-on"
	"$LED_BASE/leds/mmc0"
	"$LED_BASE/power_red"
)

declare -a LEDS_COMPACT=("${LEDS_CORE[@]}")

case "$1" in
RevPi_Compact)
	LEDS=( "${LEDS_COMPACT[@]}" )
	;;
RevPi_Connect)
	LEDS=( "${LEDS_CONNECT[@]}" )
	;;
RevPi_Core*)
	LEDS=( "${LEDS_CORE[@]}" )
	;;
*)
	;;
esac

for i in "${LEDS[@]}"
do
	if [[ -d "$i" ]]
	then
		lava-test-case "$TEST_CASE_NAME-$i" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i" --result fail
	fi

	if echo 1 > "$i"/brightness
	then
		lava-test-case "$TEST_CASE_NAME-$i/brightness-green" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i/brightness-green" --result fail
	fi

	sleep $LED_TIME
	if echo 0 > "$i"/brightness
	then
		lava-test-case "$TEST_CASE_NAME-$i/brightness-red" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i/brightness-red" --result fail
	fi
	# TODO: This test should be modified for external hardware...
done
