#!/bin/bash

# shellcheck disable=SC2034
LOW=0
HIGH=1

ANALOG_START=0
ANALOG_END=9000
ANALOG_STEP=1000
ANALOG_RANGE=250

PROCIMG_WAIT=0.1

# Function to check if a module is NOT configured
is_module_configured() {
    info_msg "$1" | grep -q "but NOT CONFIGURED"
}

# Function to check if a module is not physically present
is_module_not_present() {
    info_msg "$1" | grep -q "Module is NOT present"
}

# Function to check if a update for modules is needed
is_module_updated() {
    info_msg "$1" | grep -q "The firmware of some I/O modules must be updated."
}


# Function for setting the IO value
# $1: variable name
# $2: value to write
# Returns 0 on success, 1 on failure.
piTest_setIOValue() (
    variable=$1
    value=$2

    output=$(piTest -w "$variable","$value")
    ret=$?

    # XXX: hack: piTest is broken:
    #  - no proper exit code on failure
    #  - no usage of stderr for error messages
    if [ "$ret" -ne 0 ]; then
        echo "piTest_setIOValue '$variable': exit $ret" >&2
        return 1
    fi

    # older versions of piTest don't return error codes
    if echo "$output" | grep -qE "(Cannot find variable)|(Wrong arguments)"; then
        echo "piTest_setIOValue '$variable': $output" >&2
        return 1
    fi

    sleep "$PROCIMG_WAIT"
    return 0
)

# Read a process image variable value.
# $1: variable name
# Prints value to stdout. Returns 0 on success, 1 on failure.
piTest_readValue() {
    local var="$1"
    local value
    if ! value="$(piTest -q -1 -r "$var")"; then
        echo "piTest_readValue '$var': piTest -r failed" >&2
        return 1
    fi
    echo "$value"
}

# Check that a piTest variable exists and can be read.
# $1: variable name
# Returns 0 on success, 1 otherwise.
piTest_checkVariable() {
    local var="$1"
    local output
    local ret
    output="$(piTest -v "$var")"
    ret=$?
    if [ "$ret" -ne 0 ]; then
        echo "piTest_checkVariable '$var': exit $ret" >&2
        return 1
    fi
    if echo "$output" | grep -q "Cannot read variable info"; then
        echo "piTest_checkVariable '$var': variable not found" >&2
        return 1
    fi
    return 0
}

# Function for checking digital IO value
# $1: variable name
# $2: expected value
# Returns 0 on match, 1 otherwise
piTest_validateIOValue() (
    variable=$1
    expected=$2

    if ! piTest_checkVariable "$variable" > /dev/null; then
        return 1
    fi

    actual=$(piTest_readValue "$variable") || return 1

    if [ "$actual" -ne "$expected" ]; then
        return 1
    fi

    return 0
)

piTest_getOffset() {
    # $1: Variable name
    local var="$1"
    local info
    local offset
    piTest_checkVariable "$var" || return 1
    if ! info="$(piTest -v "$var")"; then
        echo "piTest_getOffset '$var': piTest -v failed" >&2
        return 1
    fi
    offset=$(echo "$info" | grep -oP '(?<=offset:\s)\d+')
    echo "$offset"
}

piTest_set_bit() (
    # $1: Variable name
    # $2: Bit number (bi0-bit7)
    # $3: Status to set the bit to (0 or 1)
    local var="$1"
    local bit="$2"
    local bit_status="$3"
    local offset=0
    offset=$(piTest_getOffset "$var") || return 1
    piTest -s "$offset","$bit","$bit_status" || return 1
    sleep "$PROCIMG_WAIT"
)

# Function for checking digital IO bit status
piTest_validate_BitStatus() (
    # $1: Variable name
    # $2: Bit number (bi0-bit7)
    # $3: Expected status of the bit (0 or 1)
    local var="$1"
    local bit="$2"
    local bit_status="$3"
    local offset=0
    local val=0
    offset=$(piTest_getOffset "$var") || return 1
    if ! val=$(piTest -qg "$offset","$bit"); then
        echo "piTest_validate_BitStatus '$var': piTest -qg failed" >&2
        return 1
    fi
    if [ "$val" = "$bit_status" ]; then
        return 0
    else
        return 1
    fi
)

# Function for checking analog IO value
# $1: variable name
# $2: expected value
# Returns 0 on match, 1 otherwise
piTest_validateAIOValue() (
    variable=$1
    expected=$2

    if ! piTest_checkVariable "$variable" > /dev/null; then
        return 1
    fi

    value=$(piTest_readValue "$variable") || return 1
    range_low=$(( expected - ANALOG_RANGE ))
    range_high=$(( expected + ANALOG_RANGE ))

    if [ $range_low -lt 0 ]; then
        range_low=0
    fi

    if [ "$value" -ge "$range_low" ] && [ "$value" -le "$range_high" ]; then
        return 0
    else
        return 1
    fi
)

