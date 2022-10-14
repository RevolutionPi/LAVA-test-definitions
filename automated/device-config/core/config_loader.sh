#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

cp _config.rsc /var/www/revpi/pictory/projects/_config.rsc
if [ $? -ne 0 ]
then
    lava-test-case "$TEST_CASE_NAME" --result fail
    lava-test-raise "Device configuration ERROR - _config.rsc not found?"
else
    lava-test-case "$TEST_CASE_NAME" --result pass
fi

chown www-data:www-data _config.rsc
piTest -x
