#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

TESTS="
    wlan-config-country
    wlan-1-nm
    wlan-2-nm-a
    wlan-sleep
    wlan-2-nm-b
    wlan-2-nm-disconnect
"
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

wlan_enable_ext_antenna() {
    local test_case_id=wlan-enable-ext-antenna
    local output=""

    output="$(revpi-config enable external-antenna)"
    if [ "${output}" -ne 0 ]; then
        report_fail "$test_case_id"
    else
        report_pass "$test_case_id"
        # reboot to fully activate antenna
        shutdown -r +1
    fi
}

wlan_config_country() {
    local test_case_id=wlan-config-country

    if ! echo "options cfg80211 ieee80211_regdom=DE" > /etc/modprobe.d/cfg80211.conf; then
        warn_msg "$test_case_id: Unable to write cfg80211 country config"
        report_fail "$test_case_id"
        return 1
    fi
    if ! iw reg set DE; then
        warn_msg "$test_case_id: Unable to set WLAN regulatory domain"
        report_fail "$test_case_id"
        return 1
    fi
    if ! revpi-config enable ieee80211; then
        warn_msg "$test_case_id: Unable to enable WLAN radio"
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

wlan_1_nm() {
    local test_case_id=wlan-1-nm

    if ! nmcli -c no device wifi rescan ifname "${WLAN_INTERFACE}"; then
        warn_msg "$test_case_id: Unable to start WLAN rescan"
        report_fail "$test_case_id"
        return 1
    fi

    sleep 5

    if ! nmcli -f SSID -c no device wifi list ifname "${WLAN_INTERFACE}" \
        | grep -q "${WLAN_SSID}"; then
        warn_msg "$test_case_id: Unable to find $WLAN_SSID in list of SSIDs"
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

wlan_2_nm_a() {
    local test_case_id=wlan-2-nm-a

    if ! nmcli device wifi connect "${WLAN_SSID}" password "${WLAN_PASSWORD}" name TEST; then
        warn_msg "$test_case_id: Unable to connect to SSID: ${WLAN_SSID}"
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

wlan_2_nm_b() {
    local test_case_id=wlan-2-nm-b
    local output=""

    if ! output="$(nmcli -t connection show TEST)"; then
        warn_msg "$test_case_id: Cannot show connection 'TEST'"
        report_fail "$test_case_id"
        return 1
    fi

    if ! echo "${output}" | grep -q "802-11-wireless.ssid:${WLAN_SSID}"; then
        warn_msg "$test_case_id: 802-11-wireless.ssid is not '$WLAN_SSID'"
        report_fail "$test_case_id"
        return 1
    fi
    if ! echo "${output}" | grep -q "802-11-wireless.mode:infrastructure"; then
        warn_msg "$test_case_id: 802-11-wireless.mode is not 'infrastructure'"
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

wlan_2_nm_disconnect() {
    local test_case_id=wlan-2-nm-disconnect

    if ! nmcli connection delete TEST; then
        warn_msg "$test_case_id: Unable to remove connection 'TEST'"
        report_fail "$test_case_id"
        return 1
    fi

    report_pass "$test_case_id"
}

run() {
    local test_case_id="$1"
    local output=""
    info_msg "Running ${test_case_id} test..."

    case "${test_case_id}" in
    "wlan-enable-ext-antenna") wlan_enable_ext_antenna ;;
    "wlan-config-country") wlan_config_country ;;
    "wlan-1-nm") wlan_1_nm ;;
    "wlan-2-nm-a") wlan_2_nm_a ;;
    "wlan-2-nm-b") wlan_2_nm_b ;;
    "wlan-2-nm-disconnect") wlan_2_nm_disconnect ;;
    "wlan-sleep")
        sleep "${WLAN_SLEEP}"
        report_pass "$test_case_id"
        ;;
    *)
        error_msg "Undefined test..."
        ;;
    esac
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

exit 0
