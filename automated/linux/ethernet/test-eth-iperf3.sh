#!/bin/bash
source "../test_format.sh"

#Worker Host IP_ADDRESS!
IP_ATE="192.168.168.73"

ip a show eth0 | grep inet

echo "$TXT_Section1"
echo "Connecting with ATE IP-Address: $IP_ATE"
echo "$TXT_Section1"
echo "$TXT_Section2"
echo "Start: 1/2"
echo "$TXT_Section2"
iperf3 -t 1800 -4 -c $IP_ATE -t 10
if [ $? -eq 0 ]
then
    lava-test-case logfile --result pass
else
    lava-test-case logfile --result fail
	lava-test-raise "Test iperf3 FAIL - Run server: $ iperf3 -s"
fi

echo "$TXT_Section2"
echo "Start: 2/2"
echo "$TXT_Section2"
iperf3 -t 1800 -4 -R -c $IP_ATE -t 10
if [ $? -eq 0 ]
then
    lava-test-case logfile --result pass
else
    lava-test-case logfile --result fail
	lava-test-raise "Test iperf3 FAIL - Run server: $ iperf3 -s"
fi
