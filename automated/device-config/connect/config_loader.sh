#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

if ! cp _config.rsc /var/www/revpi/pictory/projects/_config.rsc
then
    lava-test-case "$TEST_CASE_NAME" --result fail
else
    lava-test-case "$TEST_CASE_NAME" --result pass
fi

chown www-data:www-data _config.rsc
piTest -x
