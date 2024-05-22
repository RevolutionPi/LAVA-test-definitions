#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
TESTS="dsa-config dsa-1 dsa-2"
SKIP_INSTALL="False"
SKIP_REBOOT="False"
SERVER_1=""
SERVER_2=""
SERVER_3=""
BITRATE_DEFAULT_FORWARD=70
BITRATE_DEFAULT_REVERSE=90

usage() {
    echo "Usage: $0 [-sr] [-t TESTS] [-F expected_bitrate_forward] [-R expected_bitrate_reverse] IPERF_SERVER_1 IPERF_SERVER_2 IPERF_SERVER_3" 1>&2
    exit 1
}

install() {
    apt-get update -q
    apt-get -qy install iperf3 jq
}

run_iperf_test() {
    local test_name="$1"
    local remote_server="$2"
    local reverse="$3"
    local output_iperf3=""
    local bitrate_average=""
    local bitrate_default=""

    if [ "${reverse}" = "True" ]; then
        output_iperf3="$(iperf3 -4 -R -c "${remote_server}" -t 10 -J)"
        bitrate_average="$(echo "${output_iperf3}" \
            | jq -r '.end.sum_received.bits_per_second' \
            | awk '{ printf "%.2f", $1 / 1000000 }')"
        bitrate_default="${BITRATE_DEFAULT_REVERSE}"
    else
        output_iperf3="$(iperf3 -4 -c "${remote_server}" -t 10 -J)"
        bitrate_average="$(echo "${output_iperf3}" \
            | jq -r '.end.sum_sent.bits_per_second' \
            | awk '{ printf "%.2f", $1 / 1000000 }')"
        bitrate_default="${BITRATE_DEFAULT_FORWARD}"
    fi

    echo "${output_iperf3}"

    if [ "$(printf "%.0f" "${bitrate_average}")" -gt "${bitrate_default}" ]; then
        info_msg "Bitrate average: ${bitrate_average} Mbit/s - Bitrate expected: ${bitrate_default} Mbit/s -> ${test_name} OK"
        return 0
    else
        warn_msg "Bitrate average: ${bitrate_average} Mbit/s - Bitrate expected: ${bitrate_default} Mbit/s -> ${test_name} FAIL"
        return 1
    fi
}

dsa_config() {
    # Detect distribution
    local debian_version=""
    debian_version="$(cat /etc/debian_version)"
    local debian_version_major=""
    debian_version_major="${debian_version%%.*}"
    debian_version_major=$((debian_version_major))

    if [ "${debian_version_major}" -ge 12 ]; then
        CONFIG_FILE="/boot/firmware/config.txt"
    else
        CONFIG_FILE="/boot/config.txt"
    fi
    # Check if the file exists
    if [ ! -f "${CONFIG_FILE}" ]; then
        error_msg "The file ${CONFIG_FILE} does not exist."
    fi
    # Insert 'dtparam=dsa' at the beginning of the file
    sed -i '1i dtparam=dsa' "${CONFIG_FILE}"
    info_msg "Modification completed in ${CONFIG_FILE}."

    [ "${SKIP_REBOOT}" = "true" ] || [ "${SKIP_REBOOT}" = "True" ] || shutdown -r +1
}

dsa_1() {
    # List of interfaces to check
    local interfaces="swp1 swp2 swp3"
    # Initialize the result variable
    local result=0
    # Initialize a string for missing interfaces
    local missing_interfaces=""

    # Iterate over each interface in the list
    for iface in ${interfaces}; do
        # Check if the interface exists
        if ip link show "${iface}" >/dev/null 2>&1; then
            # Check if the interface has a MAC address configured
            if ! ip link show "${iface}" | grep -q "link/ether"; then
                # If it does not have a MAC -> Fail
                result=1
                # Add the interface to the missing interfaces string
                missing_interfaces="${missing_interfaces} ${iface}"
            fi
        else
            # If the interface does not exist -> Fail
            result=1
            # Add the interface to the missing interfaces string
            missing_interfaces="${missing_interfaces} ${iface}"
        fi
    done

    if [ "${result}" -ne 0 ]; then
        info_msg "The following interfaces are missing or do not have a MAC address:"
        for missing in ${missing_interfaces}; do
            info_msg "${missing}"
        done
        return "${result}"
    fi
    return "${result}"
}

dsa_2() {
    local output_iperf3=""
    local bitrate_average=0
    local error=0

    nmcli connection add type ethernet ifname swp1 con-name swp1 ip4 10.100.1.1/24
    nmcli connection add type ethernet ifname swp2 con-name swp2 ip4 10.100.2.1/24
    nmcli connection add type ethernet ifname swp3 con-name swp3 ip4 10.100.3.1/24
    nmcli connection up swp1
    nmcli connection up swp2
    nmcli connection up swp3

    run_iperf_test "sda-iperf3-server-1" "${SERVER_1}" &
    local pid1=$!
    run_iperf_test "sda-iperf3-server-2" "${SERVER_2}" &
    local pid2=$!
    run_iperf_test "sda-iperf3-server-3" "${SERVER_3}" &
    local pid3=$!
    wait "${pid1}" "${pid2}" "${pid3}" || error=1

    run_iperf_test "sda-iperf3-server-1-revert" "${SERVER_1}" True &
    local pid4=$!
    run_iperf_test "sda-iperf3-server-2-revert" "${SERVER_2}" True &
    local pid5=$!
    run_iperf_test "sda-iperf3-server-3-revert" "${SERVER_3}" True &
    local pid6=$!
    wait "${pid4}" "${pid5}" "${pid6}" || error=1

    if [ "${error}" -ne 0 ]; then
        warn_msg "Something went wrong or the performance is not as expected. Please check the tests performed previously."
    fi

    return "${error}"
}

run() {
    local test_case_id="$1"
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    "dsa-config")
        dsa_config
        ;;
    "dsa-1")
        dsa_1
        ;;
    "dsa-2")
        dsa_2
        ;;
    *)
        error_msg "Undefined test..."
    esac

    check_return "${test_case_id}"
}

while getopts ":srt:F:R:h" o; do
    case "${o}" in
    s) SKIP_INSTALL="True" ;;
    r) SKIP_REBOOT="True" ;;
    t) TESTS="${OPTARG}" ;;
    F) BITRATE_DEFAULT_FORWARD="${OPTARG}" ;;
    R) BITRATE_DEFAULT_REVERSE="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

shift $((OPTIND-1))

# Check if the correct number of positional arguments are provided
if [ $# -ne 3 ]; then
    echo "Options IPERF_SERVER_1, IPERF_SERVER_2 and IPERF_SERVER_3 are mandatory." >&2
    usage
fi

SERVER_1="$1"
SERVER_2="$2"
SERVER_3="$3"

# Test run.
create_out_dir "${OUTPUT}"

info_msg "IPERF_SERVER_1: ${SERVER_1}"
info_msg "IPERF_SERVER_2: ${SERVER_2}"
info_msg "IPERF_SERVER_3: ${SERVER_3}"

if [ "${SKIP_INSTALL}" = "true" ] || [ "${SKIP_INSTALL}" = "True" ]; then
    info_msg "Package installation skipped"
else
    install
fi

for t in ${TESTS}; do
    run "${t}"
done
