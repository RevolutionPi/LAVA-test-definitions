#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="pibridge-error"
WAIT_TIME=20

RX_ERR_HARD_LIMIT=100
TX_ERR_HARD_LIMIT=100

PIBRIDGE_STATS_DIR=/sys/bus/serial/drivers/pi-bridge/stats
PIBRIDGE_STATS_RX_ERR_FILE="$PIBRIDGE_STATS_DIR"/stat_rx_err
PIBRIDGE_STATS_TX_ERR_FILE="$PIBRIDGE_STATS_DIR"/stat_tx_err

usage() {
    cat << EOF
Usage: $0 [-s true|false] [-w WAIT_TIME]
EOF

    exit "$1"
}

pibridge_error() {
    local test_case_id=pibridge-error
    local rx_err_before=0 tx_err_before=0
    local rx_err_after=0 tx_err_after=0
    local rx_err_diff=0 tx_err_diff=0
    local rx_result=pass tx_result=pass

    if [ ! -d "$PIBRIDGE_STATS_DIR" ]; then
        warn_msg "$test_case_id: stats dir '$PIBRIDGE_STATS_DIR' non-existent"
        report_fail "$test_case_id"
        return 1
    fi

    if [ ! -r "$PIBRIDGE_STATS_RX_ERR_FILE" ] \
        || [ ! -r "$PIBRIDGE_STATS_TX_ERR_FILE" ]; then
        warn_msg "$test_case_id: pi-bridge error statistics not readable"
        report_fail "$test_case_id"
        return 1
    fi

    if ! rx_err_before="$(cat "$PIBRIDGE_STATS_RX_ERR_FILE")" \
        || ! tx_err_before="$(cat "$PIBRIDGE_STATS_TX_ERR_FILE")"; then
        warn_msg "$test_case_id: error reading statistics file"
        report_fail "$test_case_id"
        return 1
    fi

    # let the piBridge communicate
    info_msg "$test_case_id: sleeping for $WAIT_TIME seconds"
    sleep "$WAIT_TIME"

    if ! rx_err_after="$(cat "$PIBRIDGE_STATS_RX_ERR_FILE")" \
        || ! tx_err_after="$(cat "$PIBRIDGE_STATS_TX_ERR_FILE")"; then
        warn_msg "$test_case_id: error reading statistics file"
        report_fail "$test_case_id"
        return 1
    fi

    rx_err_diff=$((rx_err_after - rx_err_before))
    tx_err_diff=$((tx_err_after - tx_err_before))

    printf "%15s\t%10s\t%10s\t%10s\n" statistic before after diff
    printf "%15s\t%10d\t%10d\t%10d\n" \
        "$(basename "$PIBRIDGE_STATS_RX_ERR_FILE")" \
        "$rx_err_before" "$rx_err_after" "$rx_err_diff"
    printf "%15s\t%10d\t%10d\t%10d\n" \
        "$(basename "$PIBRIDGE_STATS_TX_ERR_FILE")" \
        "$tx_err_before" "$tx_err_after" "$tx_err_diff"

    if [ "$rx_err_diff" -gt 0 ]; then
        warn_msg "$test_case_id: $rx_err_diff receive errors occurred"
    fi
    if [ "$rx_err_diff" -gt "$RX_ERR_HARD_LIMIT" ]; then
        warn_msg "$test_case_id: more receive errors than the hard limit of $RX_ERR_HARD_LIMIT occurred"
        rx_result=fail
    fi

    if [ "$tx_err_diff" -gt 0 ]; then
        warn_msg "$test_case_id: $tx_err_diff transmit errors occurred"
    fi
    if [ "$tx_err_diff" -gt "$TX_ERR_HARD_LIMIT" ]; then
        warn_msg "$test_case_id: more transmit errors than the hard limit of $TX_ERR_HARD_LIMIT occurred"
        tx_result=fail
    fi

    add_metric "$test_case_id-rx-err-metric" "$rx_result" "$rx_err_diff" packets
    add_metric "$test_case_id-tx-err-metric" "$tx_result" "$tx_err_diff" packets

    if [ "$rx_result" = fail ] || [ "$tx_result" = fail ]; then
        report_fail "$test_case_id"
    else
        report_pass "$test_case_id"
    fi
}

run() {
    local test_case_id="$1"
    info_msg "Running $test_case_id test..."

    case "$test_case_id" in
    pibridge-error) pibridge_error ;;
    *) error_msg "Unknown test case: $test_case_id" ;;
    esac
}

while getopts "hs:t:w:" o; do
    case "$o" in
    h) usage 0 ;;
    # nothing to install
    s) ;;
    t) TESTS="$OPTARG" ;;
    w) WAIT_TIME="$OPTARG" ;;
    *) usage 1 >&2 ;;
    esac
done

shift $((OPTIND-1))

create_out_dir "$OUTPUT"

for t in $TESTS; do
    run "$t"
done

exit 0
