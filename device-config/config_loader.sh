#!/bin/sh

# shellcheck disable=SC1091
. ../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
SKIP_INSTALL="false"

TEST_CASE_NAME=$(basename "$0" .sh)
CONFIG_PATH="/var/www/revpi/pictory/projects"

usage() {
    cat >&2 << EOF
Usage: $0 [-s SKIP_INSTALL] CONFIG

Install a Revolution Pi config from path "CONFIG" to "$CONFIG_PATH" and reload
piControl.
EOF
    exit 1
}

install() {
    apt-get update -q
    apt-get -qy install pitest
}

run() {
    local config="$1"
    local config_path="$2"

    if ! cp "$config" "$config_path"/_config.rsc
    then
        # fail the complete job if setting up the configuration fails
        # if this fails the following jobs most likely fail, too
        error_fatal "$TEST_CASE_NAME-install-config"
    else
        report_pass "$TEST_CASE_NAME-install-config"
    fi

    chown www-data:www-data "$config_path"/_config.rsc

    if ! piTest -x
    then
        error_fatal "$TEST_CASE_NAME-reload-driver"
    else
        report_pass "$TEST_CASE_NAME-reload-driver"
    fi

    # wait for piTest configuration to be loaded
    sleep 1
}

while getopts "s:h" o; do
    case "$o" in
    s) SKIP_INSTALL="$OPTARG" ;;
    h|*) usage ;;
    esac
done

shift $((OPTIND - 1))

CONFIG="$1"

if [ -z "$CONFIG" ]; then
    usage
fi

if [ "$SKIP_INSTALL" = "true" ] || [ "$SKIP_INSTALL" = "True" ]; then
    install
else
    info_msg "Package installation skipped"
fi

create_out_dir "$OUTPUT"

run "$CONFIG" "$CONFIG_PATH"
