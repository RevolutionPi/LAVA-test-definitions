#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

TESTS="wlan-config-nm wlan-1-nm wlan-2-nm-a wlan-sleep wlan-2-nm-b wlan-2-nm-disconnect"
WLAN_INTERFACE="wlan0"
WLAN_SSID=""
WLAN_PASSWORD=""
WLAN_SLEEP=10

usage() {
    echo "Usage: $0 [-t tests] [-I wlan_interface] [-S wlan_sleep] -W <wlan_ssid> -P <wlan_password>" 1>&2
    exit 1
}

while getopts "t:I:S:W:P:h" o; do
    case "$o" in
    t) TESTS="${OPTARG}" ;;
    I) WLAN_INTERFACE="${OPTARG}" ;;
    S) WLAN_SLEEP="${OPTARG}" ;;
    W) WLAN_SSID="${OPTARG}" ;;
    P) WLAN_PASSWORD="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

run() {
    local test_case_id="$1"
    local output=""
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    "wlan-enable-ext-antenna")
        output="$(revpi-config enable external-antenna)"
        [ "${output}" -ne 0 ] || shutdown -r +1
        ;;
    "wlan-config-nm")
        echo "country=DE" >> /etc/NetworkManager/NetworkManager.conf
        systemctl restart NetworkManager
        # Wait a few seconds after configuration
        sleep 5
        ;;
    "wlan-1-nm")
        nmcli -c no device wifi rescan ifname "${WLAN_INTERFACE}"
        sleep 5
        nmcli -f SSID -c no device wifi list ifname "${WLAN_INTERFACE}" | grep "${WLAN_SSID}"
        ;;
    "wlan-2-nm-a")
        nmcli device wifi connect "${WLAN_SSID}" password "${WLAN_PASSWORD}" name TEST
        output="$?"
        if [ "${output}" -ne 0 ]; then
            error_msg "Unable to connect to SSID: ${WLAN_SSID}. Test aborted"
        fi
        ;;
    "wlan-2-nm-b")
        output="$(nmcli -t connection show TEST)"
        if ! echo "${output}" | grep -q "802-11-wireless.ssid:${WLAN_SSID}"; then
            report_fail "802-11-wireless.ssid should be ${WLAN_SSID}"
        fi
        if ! echo "${output}" | grep -q "802-11-wireless.mode:infrastructure"; then
            report_fail "802-11-wireless.mode NOT infrastructure!"
        fi
        ;;
    "wlan-2-nm-disconnect")
        nmcli connection delete TEST
        ;;
    "wlan-sleep")
        sleep "${WLAN_SLEEP}";
        ;;
    *)
        report_fail "Undefined test..."
        ;;
    esac

    check_return "${test_case_id}-${WLAN_SSID}"
}

# Test run.
create_out_dir "${OUTPUT}"

if [ -z "$WLAN_SSID" ] || [ -z "$WLAN_PASSWORD" ]; then
  echo "Options -W and -P are mandatory." >&2
  usage
fi

for t in $TESTS; do
    run "$t"
done
