#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="cpu-governor"
SKIP_INSTALL=false
GOVERNOR="performance"

usage() {
    cat << EOF
Usage: $0 [-s] [-g GOVERNOR]
EOF

    exit "$1"
}

install() {
    :
}

run() {
    local test_case_id="$1"
    info_msg "Running $test_case_id test..."

    case "$test_case_id" in
    "cpu-governor")
        gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        run_test_case \
            "[ '$gov' = '$GOVERNOR' ]" \
            "$test_case_id-$GOVERNOR"
        ;;
    *) error_msg "Unknown test case: $test_case_id" ;;
    esac
}

while getopts "s:g:h" o; do
    case "$o" in
    s) SKIP_INSTALL="$OPTARG" ;;
    g) GOVERNOR="$OPTARG" ;;
    h) usage 0 ;;
    '?') usage 1 >&2 ;;
    esac
done

shift $((OPTIND-1))

create_out_dir "$OUTPUT"

if [ "$SKIP_INSTALL" = "true" ] || [ "$SKIP_INSTALL" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in $TESTS; do
    run "$t"
done
