#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_REBOOT="false"

usage() {
    echo "Usage: $0 [-n kernel-name] [-u kernel-url] [-r <true|false>]" 1>&2
    exit 1
}

while getopts "n:u:r:h" o; do
  case "$o" in
    n) KERNEL_name="${OPTARG}" ;;
    u) KERNEL_url="${OPTARG}" ;;
    r) SKIP_REBOOT="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

# Test run.
create_out_dir "${OUTPUT}"

wget -nv "${KERNEL_url}"
unzip ./"${KERNEL_name}"
info_msg "Installing Kernel ${KERNEL_name}..."
DEBIAN_FRONTEND=noninteractive apt-get install -y ./*.deb
check_return "Install-Kernel"
rm -f ./*.deb ./*.zip
# Reboot DUT if desired
[ "${SKIP_REBOOT}" = "true" ] || [ "${SKIP_REBOOT}" = "True" ] || shutdown -r +1
