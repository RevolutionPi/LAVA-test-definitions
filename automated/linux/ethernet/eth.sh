#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
. ../../lib/eth.sh
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
DUT=""
IP_ATE="10.42.11.150"
SKIP_INSTALL="True"
TESTS="eth-1 eth-3"
BITRATE_DEFAULT=90


usage() {
    echo "Usage: $0 [-s <true|false>] [-d dut] [-i ip_ate] [-t tests] [-b expected_bitrate]" 1>&2
    exit 1
}

while getopts "d:s:i:t:b:B:h" o; do
    case "$o" in
    d) DUT="${OPTARG}" ;;
    s) SKIP_INSTALL="${OPTARG}" ;;
    i) IP_ATE="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    b) BITRATE_DEFAULT="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_ethtool() {
    local interface="$1"
    local ret_ethtool=0
    ret_ethtool=$(ethtool "$interface")
    echo "$ret_ethtool"
     # Iterate over the positional parameters
    for param in $ETH_PARAM; do
        if echo "$ret_ethtool" | grep -E -o "$param"
        then
            report_pass "eth-1_$interface-${param%:*}"
        else
            report_fail "eth-1_$interface-${param%:*}"
        fi
    done
}

check_iperf3() {
    local check_nr="$1"
    local output_iperf3=""
    local bitrate_average=0
    case "$check_nr" in
    1)
        output_iperf3=$(iperf3 -t 1800 -4 -c "$IP_ATE" -t 10 -J)
        bitrate_average=$(echo "$output_iperf3" | jq -r '.end.sum_sent.bits_per_second' | awk '{ printf "%.2f", $1 / 1000000 }')
        ;;
    2)
        output_iperf3=$(iperf3 -t 1800 -4 -R -c "$IP_ATE" -t 10 -J)
        bitrate_average=$(echo "$output_iperf3" | jq -r '.end.sum_received.bits_per_second' | awk '{ printf "%.2f", $1 / 1000000 }')
        ;;
    *)
        error_msg "Undefined test..."
    esac

    if [ "$(printf "%.0f" "$bitrate_average")" -gt "$BITRATE_DEFAULT" ]; then
        info_msg "Bitrate average: $bitrate_average Mbit/s - Bitrate expected: $BITRATE_DEFAULT Mbit/s -> eth-3_$check_nr/2 OK"
        add_metric "eth-3-$check_nr" pass "$bitrate_average" "Mbit/s"
    else
        error_msg "Bitrate average: $bitrate_average Mbit/s - Bitrate expected: $BITRATE_DEFAULT Mbit/s -> eth-3_$check_nr/2 FAIL"
        add_metric "eth-3-$check_nr" fail "$bitrate_average" "Mbit/s"
    fi
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "eth-1")
        check_ethtool eth0
        case "$DUT" in
        RevPi_Connect)
            check_ethtool eth1
            ;;
        *)
            ;;
        esac
        check_return "${test_case_id}"
        ;;
    "eth-3")
        output=$(ip a show eth0 | grep inet)
        info_msg "$output"
        check_iperf3 1
        check_iperf3 2
        ;;
    esac
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "iperf3 jq" "$SKIP_INSTALL"

for t in $TESTS; do
    run "$t"
done
