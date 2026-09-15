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
TESTS="eth-1 eth-3 eth-4"
ETHERNET_SPEED=1000


usage() {
    echo "Usage: $0 [-s <true|false>] [-d dut] [-i ip_ate] [-t tests] [-b ethernet_speed]" 1>&2
    echo "Tests: eth-1 eth-3 eth-4" 1>&2
    exit 1
}

while getopts "d:s:i:t:b:h" o; do
    case "$o" in
    d) DUT="${OPTARG}" ;;
    s) SKIP_INSTALL="${OPTARG}" ;;
    i) IP_ATE="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    b) ETHERNET_SPEED="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

resolve_iface() {
    if ip link show "$1" > /dev/null 2>&1; then
        echo "$1"
    else
        echo "$2"
    fi
}
ETH0=$(resolve_iface lan0 eth0)
ETH1=$(resolve_iface lan1 eth1)

TRIXIE_VERSION_ID=13

detect_iface_prefix() {
    local version_id=""

    version_id=$(. /etc/os-release && echo "${VERSION_ID:-0}")

    if [ "$version_id" -ge "$TRIXIE_VERSION_ID" ]; then
        echo lan
    else
        echo eth
    fi
}
IFACE_PREFIX=$(detect_iface_prefix)

check_ethtool() {
    local interface="$1"
    local ret_ethtool=0
    ret_ethtool="$(ethtool "$interface")"
    echo "$ret_ethtool"
     # Iterate over the positional parameters
    for param in $ETH_PARAM; do
        echo "$ret_ethtool" | grep -E -o "$param"
        check_return "eth-1_$interface-${param%:*}"
    done
}

check_iperf3() {
    local minimum_bitrate="$1"
    local check_nr="$2"
    local output_iperf3=""
    local bitrate_average=0
    local result=""

    case "$check_nr" in
    1)
        output_iperf3="$(iperf3 -t 1800 -4 -c "$IP_ATE" -t 10 -J)"
        bitrate_average="$(echo "$output_iperf3" | jq -r '.end.sum_sent.bits_per_second' | awk '{ printf "%.2f", $1 / 1000000 }')"
        ;;
    2)
        output_iperf3="$(iperf3 -t 1800 -4 -R -c "$IP_ATE" -t 10 -J)"
        bitrate_average="$(echo "$output_iperf3" | jq -r '.end.sum_received.bits_per_second' | awk '{ printf "%.2f", $1 / 1000000 }')"
        ;;
    *)
        error_msg "Undefined test..."
    esac

    if [ "$(printf "%.0f" "$bitrate_average")" -gt "$minimum_bitrate" ]; then
        result=pass
        info_msg "Bitrate average: $bitrate_average Mbit/s - Bitrate expected: $minimum_bitrate Mbit/s -> eth-3_$check_nr/2 OK"
        report_pass eth-3-"$check_nr"
    else
        result=fail
        warn_msg "Bitrate average: $bitrate_average Mbit/s - Bitrate expected: $minimum_bitrate Mbit/s -> eth-3_$check_nr/2 FAIL"
        report_fail eth-3-"$check_nr"
    fi

    add_metric "eth-3-$check_nr-metric" "$result" "$bitrate_average" "Mbit/s"
}

check_iface_names() {
    local expected_ifaces="${IFACE_PREFIX}0"
    local iface=""
    local ret=0

    case "$DUT" in
    RevPi_Core*)
        # Core (3/3+/S/SE) has a single ethernet port, all others have two
        ;;
    *)
        expected_ifaces="${expected_ifaces} ${IFACE_PREFIX}1"
        ;;
    esac

    info_msg "Expected interfaces: $expected_ifaces"

    for iface in $expected_ifaces; do
        if [ -e "/sys/class/net/$iface" ]; then
            info_msg "Interface $iface is present"
        else
            warn_msg "Interface $iface is missing"
            ret=1
        fi
    done

    # Any further ethernet interface means a rename did not take effect, e.g.
    # an eth0 left over on Trixie or an eth2 on Bookworm.
    for iface in /sys/class/net/*; do
        iface="${iface##*/}"

        case "$iface" in
        eth[0-9]*|lan[0-9]*) ;;
        *) continue ;;
        esac

        case " $expected_ifaces " in
        *" $iface "*) continue ;;
        *) ;;
        esac

        warn_msg "Unexpected interface: $iface"
        ret=1
    done

    if [ "$ret" -eq 0 ]; then
        report_pass eth-4
    else
        report_fail eth-4
    fi
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "eth-1")
        check_ethtool "$ETH0"
        case "$DUT" in
        RevPi_Connect*)
            check_ethtool "$ETH1"
            ;;
        *)
            ;;
        esac
        ;;
    "eth-3")
        output="$(ip a show "$ETH0" | grep inet)"
        info_msg "$output"
        check_iperf3 "$IPERF_SPEED" 1
        check_iperf3 "$IPERF_SPEED" 2
        ;;
    "eth-4")
        check_iface_names
        ;;
    *) error_msg "Invalid test case '$test_case_id'" ;;
    esac

    return 0
}

# Test run.
create_out_dir "${OUTPUT}"

install_deps "iperf3 jq" "$SKIP_INSTALL"

# allow a 10% deviation in speed with iperf3
IPERF_SPEED=$((ETHERNET_SPEED-ETHERNET_SPEED/10))

for t in $TESTS; do
    run "$t"
done

exit 0
