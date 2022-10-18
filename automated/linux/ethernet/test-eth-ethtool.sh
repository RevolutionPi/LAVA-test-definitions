#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

# Waiting for Parameter:
#1- Speed: 100Mb/s
#2- Duplex: Full
#3- Port: Twisted Pair
#4- Auto-negotiation: on
#5- Link detected: yes
declare -a ETH_PARAM=(
	"Speed:\s100"
	"Duplex:\sFull"
	"Port:\sTwisted\sPair"
	"Auto-negotiation:\son"
	"Link\sdetected:\syes"
)

RET_ETHTOOL=$(ethtool eth0)

for i in "${ETH_PARAM[@]}"
do
	echo $RET_ETHTOOL | grep -E -o $i
	if [ "$?" == 0 ]
	then
		lava-test-case "$TEST_CASE_NAME-$i" --result pass
	else
		lava-test-case "$TEST_CASE_NAME-$i" --result fail
	fi
done
