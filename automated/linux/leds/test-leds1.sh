#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

declare -a LEDS_CORE_TREE=(
	"├── a1_green -> ../../devices/platform/leds/leds/a1_green"
	"├── a1_red -> ../../devices/platform/leds/leds/a1_red"
	"├── a2_green -> ../../devices/platform/leds/leds/a2_green"
	"├── a2_red -> ../../devices/platform/leds/leds/a2_red"
	"├── default-on -> ../../devices/virtual/leds/default-on"
	"├── mmc0 -> ../../devices/virtual/leds/mmc0"
	"└── power_red -> ../../devices/platform/leds/leds/power_red"
)

RET_TREE=$(tree /sys/class/leds)
for i in "${LEDS_CORE_TREE[@]}"
do
	echo "$RET_TREE" | grep -o "$i"
	if [ "$?" == 0 ]
	then
		lava-test-case "$TEST_CASE_NAME-$i" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i" --result fail
	fi
done
