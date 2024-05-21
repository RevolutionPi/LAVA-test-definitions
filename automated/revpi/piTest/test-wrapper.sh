#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/piTest.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pt-1"

usage() {
    echo "Usage: $0 [-s <true|false>] [-t test]" 1>&2
    exit 1
}

while getopts "t:s:h" o; do
    case "$o" in
        t) TESTS="${OPTARG}" ;;
        s) SKIP_INSTALL="${OPTARG}" ;;
        h|*) usage ;;
    esac
done

install() {
    :
    # No dependencies to install
}

pt_1() {
    piTest_Check_config "test-pt1-pt2" "$(piTest -d)"
}

test_pt_compact_d_1() {
    piTest_Check_001 "test-compact-pt" "DI1" "DO1"
    piTest_Check_001 "test-compact-pt" "DI2" "DO2"
}

test_pt_compact_a_1() {
    piTest_Check_002 "test-compact-analog-01" "AI1" "AO1"
    piTest_Check_002 "test-compact-analog-01" "AI2" "AO2"
}

test_pt_flat_da_1() {
    piTest_setIOValue "test-flat-digital" "DOut" "1"
    piTest_Check_002 "test-flat-analog" "AIn" "AOut"
    piTest_setIOValue "test-flat-digital" "DOut" "0"
}

test_pt_config_004() {
    piTest_Check_001 "test-pt-config-004" "DI_R1_I1" "DO_R2_O1"
    piTest_Check_001 "test-pt-config-004" "DI_L1_I3" "DO_R2_O3"
    piTest_Check_001 "test-pt-config-004" "DI_L1_I1" "DO_L2_O1"
    piTest_Check_001 "test-pt-config-004" "DI_R1_I3" "DO_L2_O3"
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
        "test_pt_compact_d_1")
            test_pt_compact_d_1
            ;;
        "test_pt_compact_a_1")
            test_pt_compact_a_1
            ;;
        "test_pt_flat_da_1")
            test_pt_flat_da_1
            ;;
        "test_pt_config_004")
            test_pt_config_004
            ;;
        "test_pt_config_006")
            test_pt_DIO_MIO_AIO_01 "test-pt-config-006"
            ;;
        "test_pt_config_011")
            # Same configuration as config006 but with GW
            test_pt_DIO_MIO_AIO_01 "test-pt-config-011"
            ;;
        "test_pt_config_013")
            test_pt_DIO_MIO_AIO_02 "test-pt-config-013"
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

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done
