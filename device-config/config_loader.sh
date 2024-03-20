#!/bin/bash

TEST_CASE_NAME=$(basename "$0" .sh)

CONFIG_PATH="/var/www/revpi/pictory/projects"

CONFIG="$1"

if ! cp "$CONFIG" "$CONFIG_PATH"/_config.rsc
then
    # fail the complete job if setting up the configuration fails
    # if this fails the following jobs most likely fail, too
    lava-test-raise "$TEST_CASE_NAME-install-config"
else
    lava-test-case "$TEST_CASE_NAME-install-config" --result pass
fi

chown www-data:www-data "$CONFIG_PATH"/_config.rsc

if ! piTest -x
then
    lava-test-raise "$TEST_CASE_NAME-reload-driver"
else
    lava-test-case "$TEST_CASE_NAME-reload-driver" --result pass
fi

# wait for piTest configuration to be loaded
sleep 1
