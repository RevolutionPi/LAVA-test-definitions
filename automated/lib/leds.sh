#!/bin/sh

LED_BASE="/sys/class/leds"

LEDS_CORE="
    $LED_BASE/a1_green
    $LED_BASE/a1_red
    $LED_BASE/a2_green
    $LED_BASE/a2_red
    $LED_BASE/power_red
"

LEDS_CONNECT="
    $LED_BASE/a1_green
    $LED_BASE/a1_red
    $LED_BASE/a2_green
    $LED_BASE/a2_red
    $LED_BASE/a3_green
    $LED_BASE/a3_red
    $LED_BASE/power_red
"

LEDS_CONNECT_4="
    $LED_BASE/a1:blue:status
    $LED_BASE/a1:green:status
    $LED_BASE/a1:red:status
    $LED_BASE/a2:blue:status
    $LED_BASE/a2:green:status
    $LED_BASE/a2:red:status
    $LED_BASE/a3:blue:status
    $LED_BASE/a3:green:status
    $LED_BASE/a3:red:status
    $LED_BASE/a4:blue:status
    $LED_BASE/a4:green:status
    $LED_BASE/a4:red:status
    $LED_BASE/a5:blue:status
    $LED_BASE/a5:green:status
    $LED_BASE/a5:red:status
    $LED_BASE/power:1:fault
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
    $LED_BASE/power_red
"

LEDS_COMPACT="$LEDS_CORE"

# shellcheck disable=SC2034
LEDS_ALL="$(echo "
    $LEDS_CORE
    $LEDS_CONNECT
    $LEDS_CONNECT_4
    $LEDS_FLAT
    $LEDS_COMPACT
    " | sort -u | sed -e '/^[[:space:]]*$/d')"

get_list_leds() {
    case "$1" in
    RevPi_Compact)
        LEDS="$LEDS_COMPACT"
        ;;
    RevPi_Connect)
        LEDS="$LEDS_CONNECT"
        ;;
    RevPi_Connect_4)
        LEDS="$LEDS_CONNECT_4"
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
