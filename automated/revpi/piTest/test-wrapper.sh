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

check_io() {
    local test_name="$1" output="$2" input="$3"
    if ! piTest_setIOValue "$output" "$LOW"; then
        report_fail "$test_name"
        return 1
    fi
    if ! piTest_validateIOValue "$input" "$LOW"; then
        report_fail "$test_name"
        return 1
    fi
    if ! piTest_setIOValue "$output" "$HIGH"; then
        report_fail "$test_name"
        return 1
    fi
    piTest_validateIOValue "$input" "$HIGH"
    check_return "$test_name"
}

check_aio() {
    local test_name="$1" output="$2" input="$3" value="$4"
    if ! piTest_setIOValue "$output" "$value"; then
        report_fail "$test_name"
        return 1
    fi
    piTest_validateAIOValue "$input" "$value"
    check_return "$test_name"
}

check_aio_range() {
    local prefix="$1" output="$2" input="$3"
    local analog_value
    local ret=0
    for analog_value in $(seq "$ANALOG_START" "$ANALOG_STEP" "$ANALOG_END"); do
        check_aio "$prefix-$analog_value" "$output" "$input" "$analog_value" || ret=$?
    done
    check_aio "$prefix-reset" "$output" "$input" "$LOW" || ret=$?
    return "${ret}"
}

pt_1() {
    local pi_test_output
    pi_test_output=$(piTest -d)
    info_msg "$pi_test_output"

    run_test_case 'piTest -x' "pt1-pt2-piTest-x"
    run_test_case "! is_module_configured \"$pi_test_output\"" "pt1-pt2-HW_CONFIGURED"
    run_test_case "! is_module_not_present \"$pi_test_output\"" "pt1-pt2-HW_NOT_PRESENT"
    run_test_case "! is_module_updated \"$pi_test_output\"" "pt1-pt2-HW_UPDATE"
}

pt_test_digital_ios() {
    local ios="$1"
    local input
    local output
    local power
    local ret=0

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
                ret=1
                continue
            fi
        fi

        check_io "$input-$output" "$output" "$input" || ret=$?

        if [ -n "$power" ]; then
            piTest_setIOValue "$power" "$LOW"
        fi
    done
    return "${ret}"
}

pt_test_analog_ios() {
    local ios="$1"
    local input
    local output
    local ret=0

    if [ -z "$ios" ]; then
        info_msg "No analog IOs defined. Skipping test."
        report_skip "analog-ios"
        return 0
    fi

    ios="$(echo "$ios" | tr ';' '\n')"
    for line in $ios; do
        input="$(echo "$line" | cut -d',' -f1)"
        output="$(echo "$line" | cut -d',' -f2)"

        check_aio_range "$input-$output-$input" "$output" "$input" || ret=$?
    done
    return "${ret}"
}

test_pt_compact_d_1() {
    local ret=0
    check_io "compact-pt-DI1" "DO1" "DI1" || ret=$?
    check_io "compact-pt-DI2" "DO2" "DI2" || ret=$?
    return "${ret}"
}

test_pt_compact_a_1() {
    local ret=0
    check_aio_range "compact-analog-01-AI1" "AO1" "AI1" || ret=$?
    check_aio_range "compact-analog-01-AI2" "AO2" "AI2" || ret=$?
    return "${ret}"
}

test_pt_flat_da_1() {
    local ret=0
    if ! piTest_setIOValue "DOut" "1"; then
        report_fail "flat-dout"
        return 1
    fi
    check_aio_range "flat-analog-AIn" "AOut" "AIn" || ret=$?
    piTest_setIOValue "DOut" "0"
    check_return "flat-dout" || ret=$?
    return "${ret}"
}

test_pt_DIO_MIO_AIO_01() {
    local test_case_name="$1"
    local ret=0
    check_io "$test_case_name-DIO_L3_I1" "DIO_R3_O1" "DIO_L3_I1" || ret=$?
    check_io "$test_case_name-DIO_R3_I1" "DIO_L3_O1" "DIO_R3_I1" || ret=$?
    check_aio_range "$test_case_name-MIO_L2_AI1" "MIO_R2_AO7" "MIO_L2_AI1" || ret=$?
    check_aio_range "$test_case_name-MIO_R2_AI2" "MIO_L2_AO7" "MIO_R2_AI2" || ret=$?
    return "${ret}"
}

test_pt_DIO_MIO_AIO_02() {
    local test_case_name="$1"
    local ret=0
    check_io "$test_case_name-DIO_L3_I1" "DIO_L3_O2" "DIO_L3_I1" || ret=$?
    check_io "$test_case_name-DIO_L3_I2" "DIO_L3_O1" "DIO_L3_I2" || ret=$?
    return "${ret}"
}

test_pt_connect_digin_1_relais_3() {
    local variable_relay="RevPiOutput"
    local variable_di="RevPiStatus"
    local bit_relay=0
    local bit_di=6
    local val_di=0

    if ! piTest_checkVariable "$variable_relay" > /dev/null; then
        report_fail "relais-3"
        return 1
    fi
    if ! piTest_checkVariable "$variable_di" > /dev/null; then
        report_fail "relais-3"
        return 1
    fi
    if ! piTest_set_bit "$variable_relay" "$bit_relay" "$LOW"; then
        report_fail "relais-3"
        return 1
    fi
    if ! piTest_validate_BitStatus "$variable_di" "$bit_di" "$val_di"; then
        report_fail "relais-3"
        return 1
    fi
    if ! piTest_set_bit "$variable_relay" "$bit_relay" "$HIGH"; then
        report_fail "relais-3"
        return 1
    fi
    piTest_validate_BitStatus "$variable_di" "$bit_di" $((1 - val_di))
    check_return "relais-3"
}

test_pt_connect_digin_1_relais_5() {
    local variable_relay="RevPiLED"
    local variable_di="RevPiStatus"
    local bit_relay=6
    local bit_di=6
    local val_di=1

    if ! piTest_checkVariable "$variable_relay" > /dev/null; then
        report_fail "relais-5"
        return 1
    fi
    if ! piTest_checkVariable "$variable_di" > /dev/null; then
        report_fail "relais-5"
        return 1
    fi
    if ! piTest_set_bit "$variable_relay" "$bit_relay" "$LOW"; then
        report_fail "relais-5"
        return 1
    fi
    if ! piTest_validate_BitStatus "$variable_di" "$bit_di" "$val_di"; then
        report_fail "relais-5"
        return 1
    fi
    if ! piTest_set_bit "$variable_relay" "$bit_relay" "$HIGH"; then
        report_fail "relais-5"
        return 1
    fi
    piTest_validate_BitStatus "$variable_di" "$bit_di" $((1 - val_di))
    check_return "relais-5"
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
        test_pt_connect_digin_1_relais_3
        ;;
    "test_pt_connect_digin-1_relais-5")
        test_pt_connect_digin_1_relais_5
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
