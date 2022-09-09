#!/bin/bash

cp _config.rsc /var/www/revpi/pictory/projects/_config.rsc
if [ $? -ne 0 ]
then
    lava-test-case logfile --result fail
    lava-test-raise "Device configuration ERROR - _config.rsc not found?"
else
    lava-test-case logfile --result pass
fi

chown www-data:www-data _config.rsc
piTest -x
