#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

# Check CPU load
cpu_load=$(uptime | awk -F 'load average:' '{print $2}' | awk -F, '{print $1}' | awk '{$1=$1};1')

# Check if CPU load check failed
if [[ -z $cpu_load ]]; then
  lava-test-case "$TEST_CASE_NAME-cpu-load" --result fail
else
  echo "CPU Load: $cpu_load"
  lava-test-case "$TEST_CASE_NAME-cpu-load" --result pass
fi


# Check available memory
free_mem=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')

# Check if available memory check failed
if [[ -z $free_mem ]]; then
  lava-test-case "$TEST_CASE_NAME-available-memory" --result fail
else
  echo "Available Memory: $free_mem"
  lava-test-case "$TEST_CASE_NAME-available-memory" --result pass
fi


# Check disk space
disk_space=$(df -h / | awk 'NR==2{printf "%s", $5}')

# Check if disk space check failed
if [[ -z $disk_space ]]; then
  lava-test-case "$TEST_CASE_NAME-disk-space" --result fail
else
  echo "Disk Space: $disk_space"
  lava-test-case "$TEST_CASE_NAME-disk-space" --result pass
fi
