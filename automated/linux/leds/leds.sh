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

# Validate and get LEDs list for the specified DUT
validate_and_get_leds() {
    local dut="$1" leds

    leds="$(get_list_leds "$dut")"
    if [ -z "$leds" ]; then
        warn_msg "No LEDs specified for DUT '$dut'"
        return 1
    fi

    echo "$leds"
    return 0
}

led1() {
    local leds output res=0

    leds="$(validate_and_get_leds "$DUT")" || return 1

    output="$(tree /sys/class/leds)"
    if [ -z "$output" ]; then
        error_msg "No LEDs in /sys/class/leds for DUT $DUT"
    fi

    info_msg "Found LEDs for $DUT: $output"

    for led in $LEDS_ALL; do
        if ! echo "$leds" | grep -q "$led"; then
            report_skip "led1-$led-found"
        elif ! basename "$led" | grep "$led"; then
            report_pass "led1-$led-found"
        else
            report_fail "led1-$led-found"
            res=1
        fi
    done

    return "$res"
}

led2_led3() {
    local brightness="" leds_string

    leds_string="$(validate_and_get_leds "$DUT")" || return 1

    for led in $LEDS_ALL; do
        # Define the paths for the green and red brightness
        brightness="${led}/brightness"
        if ! echo "$leds_string" | grep -q "$led"; then
            report_skip "${brightness}-toggle"
            continue
        fi

        # Turn on the LED green (set brightness to 1)
        if ! echo 1 > "$brightness"; then
            # writing failed. fail this LED early, continue with the next
            report_fail "${brightness}-toggle"
            continue
        fi
        sleep "$LED_TIME"
        # Turn off the LED (set brightness to 0)
        echo 0 > "$brightness"
        check_return "${brightness}-toggle"
    done
}

led5() {
    local test="$1" leds_string

    leds_string="$(validate_and_get_leds "$DUT")" || return 1

    # shellcheck disable=SC2086
    # Set the positional parameters to the elements of the string
    set -- $leds_string

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

install_deps tree "${SKIP_INSTALL}"

for t in $TESTS; do
    run "$t"
done

# TODO: This test should be modified for external hardware...
