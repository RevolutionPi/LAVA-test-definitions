#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="rs485-low-baud"
RSDEV="/dev/ttyRS485-0"
PIBRIDGE_STATS_DIR=/sys/bus/serial/drivers/pi-bridge/stats
RX_ERR_FILE="$PIBRIDGE_STATS_DIR/stat_rx_err"
TX_ERR_FILE="$PIBRIDGE_STATS_DIR/stat_tx_err"
ERR_LIMIT=100

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
        local rx_before rx_after rx_diff
        local tx_before tx_after tx_diff
        local rx_result=pass tx_result=pass
        previous_baud="$(stty -F "$RSDEV" speed)"
        exit_on_fail "$test_case_id-get-baud" "$test_case_id"

        trap 'stty -F "$RSDEV" -echo raw speed "$previous_baud" \
            > /dev/null' EXIT
        trap 'exit 1' HUP INT TERM

        stty -F "$RSDEV" -echo raw speed 1200
        exit_on_fail "$test_case_id-set-baud" \
            "$test_case_id $test_case_id-set-previous-baud"

        [ -r "$RX_ERR_FILE" ] && [ -r "$TX_ERR_FILE" ]
        exit_on_fail "$test_case_id-pibridge-stats" \
            "$test_case_id $test_case_id-set-previous-baud"

        rx_before="$(cat "$RX_ERR_FILE")" \
            && tx_before="$(cat "$TX_ERR_FILE")"
        exit_on_fail "$test_case_id-read-pibridge-stats" \
            "$test_case_id $test_case_id-set-previous-baud"

        for i in $(seq 1 100); do
            if ! echo "test" > "$RSDEV"; then
                warn_msg "Failed to send message on $RSDEV ($i/100)"
                send_fail=$((send_fail + 1))
            fi
        done

        rx_after="$(cat "$RX_ERR_FILE")" \
            && tx_after="$(cat "$TX_ERR_FILE")"
        exit_on_fail "$test_case_id-read-pibridge-stats-after" \
            "$test_case_id $test_case_id-set-previous-baud"
        rx_diff=$((rx_after - rx_before))
        tx_diff=$((tx_after - tx_before))

        if [ "$send_fail" -gt 0 ]; then
            printf "Sending message failed %d times\n" "$send_fail" >&2
        fi

        [ "$rx_diff" -gt "$ERR_LIMIT" ] && rx_result=fail
        [ "$tx_diff" -gt "$ERR_LIMIT" ] && tx_result=fail

        add_metric "$test_case_id-rx-errors" "$rx_result" "$rx_diff" packets
        add_metric "$test_case_id-tx-errors" "$tx_result" "$tx_diff" packets

        if [ "$send_fail" -gt 0 ] \
            || [ "$rx_result" = fail ] || [ "$tx_result" = fail ]; then
            report_fail "$test_case_id"
        else
            report_pass "$test_case_id"
        fi

        stty -F "$RSDEV" -echo raw speed "$previous_baud" > /dev/null
        check_return "$test_case_id-set-previous-baud"
        trap - EXIT HUP INT TERM
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
    *) usage "1" >&2 ;;
    esac
done

shift $((OPTIND-1))

create_out_dir "$OUTPUT"

for t in $TESTS; do
    run "$t"
done

exit 0
