#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib

OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_REBOOT="true"

TESTS="hdmi-status-check start-desktop"

HDMI_ERROR_MSG="Cannot find any crtc or sizes"

usage() {
    echo "Usage: $0 [-t tests]" 1>&2
    exit 1
}

while getopts "r:t:h" o; do
    case "$o" in
    r) SKIP_REBOOT="${OPTARG}" ;;
    t) TESTS="${OPTARG}" ;;
    h|*) usage ;;
    esac
done

check_default_image() {
    local test_case_id="$1"
    local skip_msg="Image is not 'default', exiting test."

    grep -q "default" /etc/revpi/image-release
    exit_on_skip "${test_case_id}" "${skip_msg}"
}

check_desktop() {
    local test_case_id="$1"
    local do_isolate="$2"
    local fail_msg="Desktop environment is not running."

    check_default_image "${test_case_id}_check-default-image"

    if [ "$do_isolate" = "isolate" ]; then
        systemctl isolate graphical.target
    fi

    pgrep -f 'lightdm|lxsession' > /dev/null
    exit_on_fail "${test_case_id}" "${fail_msg}"
}

run() {
    local test_case_id="$1"
    local HDMI_ERROR_MSG="Cannot find any crtc or sizes"
    info_msg "Running ${test_case_id} test..."

    case "$test_case_id" in
    "start-desktop")
        check_desktop "${test_case_id}" "isolate"
        ;;
    "start-desktop-raspi-config")
        check_desktop "${test_case_id}"
        raspi-config nonint do_boot_behaviour B4
        # Reboot DUT if desired
        [ "${SKIP_REBOOT}" = "true" ] || shutdown -r +1
        check_return "${test_case_id}"
        ;;
    "start-desktop-raspi")
        check_desktop "${test_case_id}"
        ;;
    "hdmi-status-check")
        dmesg_output="$(dmesg | grep vc4)"

        if echo "${dmesg_output}" | grep -q "fb0: vc4drmfb frame buffer device"; then
            report_pass "${test_case_id}"
        else
            if echo "${dmesg_output}" | grep -q "$HDMI_ERROR_MSG"; then
                warn_msg "HDMI Issue Detected: $HDMI_ERROR_MSG."
            else
                warn_msg "HDMI status unclear: No clear indicators found."
            fi

            info_msg "${dmesg_output}"
            report_fail "${test_case_id}"
        fi
        ;;
    *)
        error_msg "Invalid test: ${test_case_id}"
        ;;
    esac
}

# Test run
create_out_dir "${OUTPUT}"

for t in $TESTS; do
    run "$t"
done
