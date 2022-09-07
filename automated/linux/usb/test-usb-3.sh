#!/bin/bash

dd if=/dev/sda1 of=/dev/null status=progress conv=sync iflag=nocache oflag=nocache bs=1k count=1M
RET=$?

if [ $RET -eq 0 ]
then
    lava-test-case logfile --result pass
else
    lava-test-case logfile --result fail
    lava-test-raise "Test usb-3 FAIL - Unable to read from USB flash disk"
fi
