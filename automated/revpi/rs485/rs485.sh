#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_INSTALL="true"
RSDEV="/dev/ttyRS485"
TESTS="rs485-tx rs485-rx"
BAUD=19200
SLEEP_TIME="0.3"
LIMIT=50

usage() {
    echo "Usage: $0 [-s <true|false>] [-t TESTS] [-d RSDEV] [-b BAUD] [-l LIMIT]" 1>&2
    echo "Example: $0 -s true -t 'rs485-tx rs485-rx' -d /dev/ttyRS485 -b 19200 -l 12" 1>&2
    exit 1
}

while getopts "s:t:d:b:l:h" o; do
  case "$o" in
    s) SKIP_INSTALL="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    d) RSDEV="${OPTARG}" ;;
    b) BAUD="${OPTARG}" ;;
    l) LIMIT="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

install() {
    :
    # No dependencies to install
}

get_ack() {
    local expected_ack="$1"
    read -r ack < "$RSDEV"
    ack=$(echo "$ack" | perl -p -e 's/\r//cg')

    if [ "$ack" -ne "$expected_ack" ]; then
        error_msg "rs485 acknowledgment failed!"
    fi
}

rs485() {
    local mode="$1"
    local cnt=0
    local previous_baud

    previous_baud="$(stty -F "$RSDEV" -echo raw speed "$BAUD")"
    exit_on_fail "$test_case_id-set-baud"

    while [ "$cnt" -lt "$LIMIT" ]; do
        if [ "$mode" = "tx" ]; then
            sleep "$SLEEP_TIME"
            echo "$cnt" > "$RSDEV"
            get_ack $((cnt + 1))
            cnt=$((cnt + 1))
        elif [ "$mode" = "rx" ]; then
            get_ack "$cnt"
            cnt=$((cnt + 1))
            sleep "$SLEEP_TIME"
            echo $cnt > "$RSDEV"
        else
            error_msg "Invalid mode: $mode. Use 'tx' or 'rx'."
            exit 1
        fi
    done

    stty -F "$RSDEV" -echo raw speed "$previous_baud" > /dev/null
    chek_return "$test_case_id-set-previous-baud"
}

run() {
    local test="$1"
    test_case_id="${test}"
    info_msg "Running ${test_case_id} test..."

    case "$test" in
        "rs485-tx")
            rs485 tx
            ;;
        "rs485-rx")
            rs485 rx
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

if [ ! -c "$RSDEV" ] ; then
	error_msg "RS485 device $RSDEV not found!"
fi

for t in $TESTS; do
    run "$t"
done
