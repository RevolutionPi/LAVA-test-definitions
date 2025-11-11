#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="rs485-low-baud"
RSDEV="/dev/ttyRS485-0"

usage() {
    cat << EOF
Usage: $0 [-s SKIP_INSTALL] [-t TESTS] [-d RSDEV]
EOF

    exit "$1"
}

run() {
    local test_case_id="$1"
    info_msg "Running $test_case_id test..."

    case "$test_case_id" in
    "rs485-low-baud")
        local previous_baud
        local send_fail=0
        local errors
        previous_baud="$(stty -F "$RSDEV" -echo raw speed 1200)"
        exit_on_fail "$test_case_id-set-baud" \
            "$test_case_id $test_case_id-set-previous-baud"

        dmesg_capture_start

        for i in $(seq 1 100); do
            if ! echo "test" > "$RSDEV"; then
                warn_msg "Failed to send message on $RSDEV ($i/100)"
                send_fail=$((send_fail + 1))
            fi
        done

        errors="$(dmesg_capture_result | grep "piControl")"

        if [ "$send_fail" -gt 0 ]; then
            printf "Sending message failed %d times\n" "$send_fail" >&2
        fi

        if [ -n "$errors" ]; then
            echo "$errors"
            printf \
                "Errors occured in piControl during rs485 low baud test\n" >&2
        fi

        if [ "$send_fail" -gt 0 ] || [ -n "$errors" ]; then
            report_fail "$test_case_id"
        else
            report_pass "$test_case_id"
        fi

        stty -F "$RSDEV" -echo raw speed "$previous_baud" > /dev/null
        check_return "$test_case_id-set-previous-baud"
        ;;
    *) error_msg "Unknown test $test_case_id" ;;
    esac
}

while getopts "t:d:s:h" o; do
    case "$o" in
    t) TESTS="$OPTARG";;
    d) RSDEV="$OPTARG" ;;
    s)
        # nothing to install
        ;;
    h) usage 0 ;;
    '?') usage "1" >&2 ;;
    esac
done

shift $((OPTIND-1))

create_out_dir "$OUTPUT"

for t in $TESTS; do
    run "$t"
done
