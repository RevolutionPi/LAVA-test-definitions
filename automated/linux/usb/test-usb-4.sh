#!/bin/bash

dd if=/dev/zero of=/dev/sda1 status=progress conv=sync iflag=nocache oflag=nocache bs=1k count=1M
RET=$?

if [ $RET -eq 0 ]
then
    lava-test-case logfile --result pass
else
    lava-test-case logfile --result fail
    lava-test-raise "Test usb-4 FAIL - Unable to write from USB flash disk"
fi
