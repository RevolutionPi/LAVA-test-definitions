#!/bin/sh

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_INSTALL=false
SKIP_REBOOT=false

usage() {
    cat >&2 << EOF
"Usage: $0 PKG-NAME PKG-URL [-s <true|false>] [-r <true|false>]" 1>&2
EOF

    exit 1
}

install() {
    apt-get update -q
    apt-get install -qy wget
}

while getopts "r:s:h" o; do
  case "$o" in
    r) SKIP_REBOOT="${OPTARG}" ;;
    s) SKIP_INSTALL="${OPTARG}" ;;
    h|*) usage ;;
  esac
done

shift $((OPTIND - 1))

if [ "$#" -lt 1 ]; then
    error_msg "At least 1 URL needs to be given"
fi

# Test run.
create_out_dir "${OUTPUT}"

if [ "$SKIP_INSTALL" = "True" ] || [ "$SKIP_INSTALL" = "true" ]; then
    info_msg "Package installation skipped"
else
    install
fi

wget -nv "$@"
exit_on_fail "pkg-install-download"

info_msg "Installing package(s)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y ./*.deb
check_return "Install-Package"

rm -f ./*.deb

# Reboot DUT if desired
[ "${SKIP_REBOOT}" = "true" ] || [ "${SKIP_REBOOT}" = "True" ] || shutdown -r +1
