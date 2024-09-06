#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/leds.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="led-1 led-2_led-3 led-5"
LED_TIME=1

usage() {
    echo "Usage: $0 [-s <true|false>] [-d device] [-t TESTS] [-l LED_TIME]" 1>&2
    exit 1
}

while getopts "s:d:t:l:h" o; do
    case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    d) DUT="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    l) LED_TIME="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

install() {
    install_deps tree
}

led1() {
    local leds output res=0

    leds=$(get_list_leds "$DUT")
    if [ -z "$leds" ]; then
        error_msg "List of LEDs for DUT $DUT empty"
    fi

    output="$(tree /sys/class/leds)"
    if [ -z "$output" ]; then
        error_msg "No LEDs in /sys/class/leds for DUT $DUT"
    fi

    info_msg "Found LEDs for $DUT: $output"

    for led in $leds; do
        if ! basename "$led" | grep "$led"; then
            report_pass "led1-$led-found"
        else
            report_fail "led1-$led-found"
            res=1
        fi
    done

    return "$res"
}

led2_led3() {
    local brightness=""

    LEDS_STRING=$(get_list_leds "$DUT")
    if [ -z "$LEDS_STRING" ]; then
        warn_msg "No LEDs specified for DUT '$DUT'"
        return 1
    fi

    # shellcheck disable=SC2086
    # Set the positional parameters to the elements of the string
    set -- $LEDS_STRING

    # Iterate over the positional parameters
    for leds_value; do
        # Define the paths for the green and red brightness
        brightness="${leds_value}/brightness"

        # Turn on the LED green (set brightness to 1)
        echo 1 > "$brightness"
        check_return "${brightness}_ON"
        sleep "$LED_TIME"
        # Turn off the LED (set brightness to 0)
        echo 0 > "$brightness"
        check_return "${brightness}_OFF"
    done
}

led5() {
    local test="$1"

    LEDS_STRING=$(get_list_leds "$DUT")
    if [ -z "$LEDS_STRING" ]; then
        warn_msg "No LEDs specified for DUT '$DUT'"
        return 1
    fi

    # shellcheck disable=SC2086
    # Set the positional parameters to the elements of the string
    set -- $LEDS_STRING

    # Iterate over the positional parameters
    for leds_value; do
        # Check if the value represents a directory
        if [ -d "$leds_value" ]; then
            report_pass "${test}_${leds_value}"
        else
            report_fail "${test}_${leds_value}"
        fi
    done
}

run() {
    local test="$1"
    test_case_id="${test}"
    info_msg "Running ${test_case_id} test..."

    case "$test" in
    "led-1")
        led1
        ;;
    "led-2_led-3")
        led2_led3
        ;;
    "led-5")
        led5 "$test"
        ;;
    *)
        error_msg "Invalid test: $test"
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
