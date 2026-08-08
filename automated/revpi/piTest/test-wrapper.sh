#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/piTest.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pt-1"
DIGITAL_IOS=""
ANALOG_IOS=""

usage() {
    echo "Usage: $0 [-s <true|false>] [-t test]" 1>&2
    exit 1
}

while getopts "t:s:d:a:h" o; do
    case "$o" in
    t) TESTS="${OPTARG}" ;;
    s)
        # nothing to install
        ;;
    d) DIGITAL_IOS="${OPTARG}" ;;
    a) ANALOG_IOS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

piTest_Check_config() (
    # $1: TEST_CASE_NAME
    # $2: PIT_TEST_OUTPUT
    test_case_name=$1
    pi_test_output=$2

    # Check if piTest -x fails
    if piTest -x
    then
        report_pass "$test_case_name-piTest-x"
    else
        report_fail "$test_case_name-piTest-x"
    fi

    # Check if a module is NOT configured
    if is_module_configured "$pi_test_output"
    then
        info_msg "$pi_test_output"
        report_fail "$test_case_name-HW_CONFIGURED"
    else
        report_pass "$test_case_name-HW_CONFIGURED"
    fi

    # Check if a module is not physically present
    if is_module_not_present "$pi_test_output"
    then
        info_msg "$pi_test_output"
        report_fail "$test_case_name-HW_NOT_PRESENT"
    else
        report_pass "$test_case_name-HW_NOT_PRESENT"
    fi

    # Check if an update is required
    if is_module_updated "$pi_test_output"
    then
        report_fail "$test_case_name-HW_UPDATE"
    else
        report_pass "$test_case_name-HW_UPDATE"
    fi
)

piTest_Check_001() (
    # $1: TEST_CASE_NAME
    # $2: INPUT
    # $3: OUTPUT
    test_case_name=$1
    input=$2
    output=$3

    # set output to low
    if ! piTest_setIOValue "$output" "$LOW"; then
        report_fail "$test_case_name-$input-low"
        return 1
    fi
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validateIOValue "$input" "$LOW"; then
        report_pass "$test_case_name-$input-low"
    else
        report_fail "$test_case_name-$input-low"
    fi

    # set output to high
    if ! piTest_setIOValue "$output" "$HIGH"; then
        report_fail "$test_case_name-$input-high"
        return 1
    fi
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validateIOValue "$input" "$HIGH"; then
        report_pass "$test_case_name-$input-high"
    else
        report_fail "$test_case_name-$input-high"
    fi
)

piTest_Check_002() (
    # $1: TEST_CASE_NAME
    # $2: INPUT
    # $3: OUTPUT
    test_case_name=$1
    input=$2
    output=$3

    # set output with ANALOG_VALx
    for analog_value in $(seq $ANALOG_START $ANALOG_STEP $ANALOG_END); do
        if ! piTest_setIOValue "$output" "$analog_value"; then
            return 1
        fi
        # Wait for process image
        sleep "$PROCIMG_WAIT"
        if piTest_validateAIOValue "$input" "$analog_value"; then
            report_pass "$test_case_name-$input-$analog_value"
        else
            report_fail "$test_case_name-$input-$analog_value"
        fi
    done

    # reset output to zero
    if ! piTest_setIOValue "$output" "$LOW"; then
        return 1
    fi
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validateAIOValue "$input" "$LOW"; then
        report_pass "$test_case_name-$input-reset"
    else
        report_fail "$test_case_name-$input-reset"
    fi
)

test_pt_connect_digin1_relaisX() (
    # $1: TEST_CASE_NAME
    # $2: NAME VARIABLE RELAY
    local test_case_name="$1"
    local variable_relay="$2"
    local variable_di="RevPiStatus"
    local bit_relay=0
    local bit_di=6
    local val_di=0

    if [ "$variable_relay" = "RevPiLED" ]; then
        bit_relay=6
        val_di=1
    fi

    if [ "$(piTest -v "$variable_relay")" = "Cannot read variable info" ]; then
        report_fail "$test_case_name-variable-$variable_relay"
        report_skip "$test_case_name-relay-low"
        report_skip "$test_case_name-relay-high"
        return 1
    fi
    report_pass "$test_case_name-variable-$variable_relay"

    if [ "$(piTest -v "$variable_di")" = "Cannot read variable info" ]; then
        report_fail "$test_case_name-variable-$variable_di"
        report_skip "$test_case_name-relay-low"
        report_skip "$test_case_name-relay-high"
        return 1
    fi
    report_pass "$test_case_name-variable-$variable_di"

    piTest_set_bit "$variable_relay" "$bit_relay" "$LOW"
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validate_BitStatus "$variable_di" "$bit_di" "$val_di"; then
        report_pass "$test_case_name-relay-low"
    else
        report_fail "$test_case_name-relay-low"
    fi

    piTest_set_bit "$variable_relay" "$bit_relay" "$HIGH"
    # wait for process image
    sleep "$PROCIMG_WAIT"
    if piTest_validate_BitStatus "$variable_di" "$bit_di" $((1 - val_di)); then
        report_pass "$test_case_name-relay-high"
    else
        report_fail "$test_case_name-relay-high"
    fi
)

pt_1() {
    piTest_Check_config "pt1-pt2" "$(piTest -d)"
}

pt_test_digital_ios() {
    local ios="$1"
    local input
    local output
    local power

    # TODO: skipping this is still reported as pass in the calling context

    if [ -z "$ios" ]; then
        info_msg "No digital IOs defined. Skipping test."
        report_skip "digital-ios"

        return 0
    fi

    # substitute the ';' to '\n' to not have to set IFS and potentially break
    # other loops called later
    ios="$(echo "$ios" | tr ';' '\n')"
    for line in $ios; do
        input="$(echo "$line" | cut -d',' -f1)"
        output="$(echo "$line" | cut -d',' -f2)"
        power="$(echo "$line" | cut -d',' -f3)"

        # turn on power before testing
        if [ -n "$power" ]; then
            if ! piTest_setIOValue "$power" "$HIGH"; then
                report_fail "$input-$output"
                continue
            fi
        fi

        piTest_Check_001 "$input-$output" "$input" "$output"

        if [ -n "$power" ]; then
            if ! piTest_setIOValue "$power" "$LOW"; then
                report_fail "$input-$output"
                continue
            fi
        fi
    done
}

pt_test_analog_ios() {
    local ios="$1"
    local input
    local output

    if [ -z "$ios" ]; then
        info_msg "No analog IOs defined. Skipping test."
        report_skip "analog-ios"

        return 0
    fi

    ios="$(echo "$ios" | tr ';' '\n')"
    for line in $ios; do
        input="$(echo "$line" | cut -d',' -f1)"
        output="$(echo "$line" | cut -d',' -f2)"

        piTest_Check_002 "$input-$output" "$input" "$output"
    done
}

test_pt_compact_d_1() {
    piTest_Check_001 "compact-pt" "DI1" "DO1"
    piTest_Check_001 "compact-pt" "DI2" "DO2"
}

test_pt_compact_a_1() {
    piTest_Check_002 "compact-analog-01" "AI1" "AO1"
    piTest_Check_002 "compact-analog-01" "AI2" "AO2"
}

test_pt_flat_da_1() {
    if ! piTest_setIOValue "DOut" "1"; then
        report_fail "flat-dout"
        return 1
    fi
    piTest_Check_002 "flat-analog" "AIn" "AOut"
    if ! piTest_setIOValue "DOut" "0"; then
        report_fail "flat-dout"
    fi
}

test_pt_DIO_MIO_AIO_01() {
    local test_case_name="$1"
    piTest_Check_001 "$test_case_name" "DIO_L3_I1" "DIO_R3_O1"
    piTest_Check_001 "$test_case_name" "DIO_R3_I1" "DIO_L3_O1"
    piTest_Check_002 "$test_case_name" "MIO_L2_AI1" "MIO_R2_AO7"
    piTest_Check_002 "$test_case_name" "MIO_R2_AI2" "MIO_L2_AO7"
}

test_pt_DIO_MIO_AIO_02() {
    local test_case_name="$1"
    piTest_Check_001 "$test_case_name" "DIO_L3_I1" "DIO_L3_O2"
    piTest_Check_001 "$test_case_name" "DIO_L3_I2" "DIO_L3_O1"
}

run() {
    local test_case_id="$1"
    echo
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "pt-1")
        pt_1
        ;;
    "pt_test_digital_ios")
        pt_test_digital_ios "$DIGITAL_IOS"
        ;;

    "pt_test_analog_ios")
        pt_test_analog_ios "$ANALOG_IOS"
        ;;
    "test_pt_compact_d_1")
        test_pt_compact_d_1
        ;;
    "test_pt_compact_a_1")
        test_pt_compact_a_1
        ;;
    "test_pt_flat_da_1")
        test_pt_flat_da_1
        ;;
    "test_pt_config_006")
        test_pt_DIO_MIO_AIO_01 "pt-config-006"
        ;;
    "test_pt_config_011")
        # Same configuration as config006 but with GW
        test_pt_DIO_MIO_AIO_01 "pt-config-011"
        ;;
    "test_pt_config_010")
        test_pt_DIO_MIO_AIO_02 "pt-config-010"
        ;;
    "test_pt_config_013")
        test_pt_DIO_MIO_AIO_02 "pt-config-013"
        ;;
    "test_pt_connect_digin-1_relais-3")
        test_pt_connect_digin1_relaisX "relais-3" "RevPiOutput"
        ;;
    "test_pt_connect_digin-1_relais-5")
        test_pt_connect_digin1_relaisX "relais-5" "RevPiLED"
        ;;
    *)
        report_fail "Undefined test..."
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

for t in $TESTS; do
    run "$t"
done

exit 0
