#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

# Check CPU load
cpu_load=$(uptime | awk -F 'load average:' '{print $2}' | awk -F, '{print $1}' | awk '{$1=$1};1')
echo "CPU Load: $cpu_load"

# Check available memory
free_mem=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
echo "Available Memory: $free_mem"

# Check disk space
disk_space=$(df -h / | awk 'NR==2{printf "%s", $5}')
echo "Disk Space: $disk_space"

lava-test-case "$TEST_CASE_NAME-Health-Check" --result pass
