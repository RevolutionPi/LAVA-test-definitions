#!/bin/bash

dmesg | grep -i picontrol
if [ $? -eq 0 ]
then
	lava-test-case logfile --result pass
else
	lava-test-case logfile --result fail
	lava-test-raise "Test picontrol FAIL"
fi

ls -l /dev/pi* | grep /dev/piControl0
if [ $? -eq 0 ]
then
	lava-test-case logfile --result pass
else
	lava-test-case logfile --result fail
	lava-test-raise "Test picontrol FAIL"
fi
