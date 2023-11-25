#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/piTest.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

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
    dist_name

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

run() {
    # shellcheck disable=SC3043
    local test="$1"
    test_case_id="${test}"
    echo
    info_msg "Running ${test_case_id} test..."

    case "$test" in
        "pt_1")
            info_msg "Image test: pt-1"
            pt_1
            ;;
        "test_pt_compact_d_1")
            info_msg "Image test: test_pt_compact_d_1"
            test_pt_compact_d_1
            ;;
        "test_pt_compact_a_1")
            info_msg "Image test: test_pt_compact_a_1"
            test_pt_compact_a_1
            ;;
        "test_pt_flat_da_1")
            info_msg "Image test: test_pt_flat_da_1"
            test_pt_flat_da_1
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
