#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

TESTS="bt-1 bt-2 bt-remove"
BT_SCAN_TIMEOUT=30
BT_REMOTE=""


usage() {
    echo "Usage: $0 [-t tests] [-S bt_scan_timeout] -B <bt_remote>" 1>&2
    exit 1
}

while getopts "t:S:B:h" o; do
    case "$o" in
    t) TESTS="${OPTARG}" ;;
    S) BT_SCAN_TIMEOUT="${OPTARG}" ;;
    B) BT_REMOTE="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

get_mac_address() {
    local param="$1"
    echo "${param}" | grep -oE '[[:xdigit:]]{2}(:[[:xdigit:]]{2}){5}'
}

run() {
    local test_case_id="$1"
    local device_info=""
    local mac_address=""
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    "bt-1")
        hcitool scan
        ;;
    "bt-2")
        device_info="$(bluetoothctl --timeout "${BT_SCAN_TIMEOUT}" scan on | grep "NEW.* ${BT_REMOTE}")"
        if [ -z "${device_info}" ]; then
           err_msg "No device info available... Check Bluetooth in Worker!"
        fi
        mac_address="$(get_mac_address "${device_info}")"
        bluetoothctl pair "${mac_address}"
        device_info="$(bluetoothctl info "${mac_address}")"
        echo "${device_info}" | grep -q "Paired: yes"
        ;;
    "bt-remove")
        device_info="$(bluetoothctl devices | grep "${BT_REMOTE}")"
        mac_address="$(get_mac_address "${device_info}")"
        bluetoothctl remove "${mac_address}"
        ;;
    *)
        report_fail "Undefined test..."
        ;;
    esac

    check_return "${test_case_id}"
}

# Test run.
create_out_dir "${OUTPUT}"

if [ -z "$BT_REMOTE" ]; then
    echo "Option -B is mandatory." >&2
    usage
fi

for t in $TESTS; do
    run "$t"
done
