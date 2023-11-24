#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/leds.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="led-1 led-2_led-3 led-5"

usage() {
    echo "Usage: $0 [-s <true|false>] [-d device] [-t TESTS]" 1>&2
    exit 1
}

while getopts "s:d:t:h" o; do
  case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    d) DUT="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

install() {
    dist_name

    tree
}

run() {
    # shellcheck disable=SC3043
    local test="$1"
    test_case_id="${test}"
    info_msg "Running ${test_case_id} test..."

    case "$test" in
        "led-1")
            output=$(tree /sys/class/leds)
            info_msg "$output"
            ;;
        "led-2_led-3")
            LEDS_STRING=$(get_list_leds "$DUT")
            info_msg "$LEDS_STRING"
            # shellcheck disable=SC2086
            # Set the positional parameters to the elements of the string
            set -- $LEDS_STRING

            # Iterate over the positional parameters
            for LEDS_VALUE; do
                # Define the paths for the green and red brightness
                LED_BRIGHTNESS="${LEDS_VALUE}/brightness"

                # Turn on the LED green (set brightness to 1)
                echo 1 > "$LED_BRIGHTNESS"
                check_return "${LED_BRIGHTNESS}_ON"
                sleep "$LED_TIME"
                # Turn off the LED (set brightness to 0)
                echo 0 > "$LED_BRIGHTNESS"
                check_return "${LED_BRIGHTNESS}_OFF"
                sleep "$LED_TIME"
            done
            ;;
        "led-5")
            LEDS_STRING=$(get_list_leds "$DUT")
            # shellcheck disable=SC2086
            # Set the positional parameters to the elements of the string
            set -- $LEDS_STRING

            # Iterate over the positional parameters
            for LEDS_VALUE; do
                # Check if the value represents a directory
                if [ -d "$LEDS_VALUE" ]; then
                    report_pass "${test}_${LEDS_VALUE}"
                else
                    report_fail "${test}_${LEDS_VALUE}"
                fi
            done
            ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done

# TODO: This test should be modified for external hardware...
