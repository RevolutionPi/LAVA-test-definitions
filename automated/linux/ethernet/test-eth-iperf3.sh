#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

#Worker Host IP_ADDRESS!
IP_ATE="192.168.168.73"

ip a show eth0 | grep inet

echo "Connecting with ATE IP-Address: $IP_ATE"
if iperf3 -t 1800 -4 -c $IP_ATE -t 10;
then
    lava-test-case "$TEST_CASE_NAME-iperf3-1/2" --result pass
else
    lava-test-case "$TEST_CASE_NAME-iperf3-1/2" --result fail
fi

if iperf3 -t 1800 -4 -R -c $IP_ATE -t 10;
then
    lava-test-case "$TEST_CASE_NAME-iperf3-2/2" --result pass
else
    lava-test-case "$TEST_CASE_NAME-iperf3-2/2" --result fail
fi
