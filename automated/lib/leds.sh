#!/bin/sh

#LED_TIME: LED on/off time.
LED_TIME=1
LED_BASE="/sys/class/leds"

LEDS_CORE="
    $LED_BASE/a1_green
    $LED_BASE/a1_red
    $LED_BASE/a2_green
    $LED_BASE/a2_red
    $LED_BASE/default-on
    $LED_BASE/mmc0
    $LED_BASE/power_red
"

LEDS_CONNECT="
    $LED_BASE/a1_green
    $LED_BASE/a1_red
    $LED_BASE/a2_green
    $LED_BASE/a2_red
    $LED_BASE/a3_green
    $LED_BASE/a3_red
    $LED_BASE/default-on
    $LED_BASE/leds/mmc0
    $LED_BASE/power_red
"

LEDS_FLAT="
    $LED_BASE/a1_green
    $LED_BASE/a1_red
    $LED_BASE/a2_green
    $LED_BASE/a2_red
    $LED_BASE/a3_green
    $LED_BASE/a3_red
    $LED_BASE/a4_green
    $LED_BASE/a4_red
    $LED_BASE/a5_green
    $LED_BASE/a5_red
    $LED_BASE/default-on
    $LED_BASE/mmc0
    $LED_BASE/power_red
"

LEDS_COMPACT="$LEDS_CORE"

get_list_leds() {
    case "$1" in
        RevPi_Compact)
            LEDS="$LEDS_COMPACT"
            ;;
        RevPi_Connect)
            LEDS="$LEDS_CONNECT"
            ;;
        RevPi_Core*)
            LEDS="$LEDS_CORE"
            ;;
        RevPi_Flat)
            LEDS="$LEDS_FLAT"
            ;;
        *)
            ;;
    esac

    echo "$LEDS"
}
