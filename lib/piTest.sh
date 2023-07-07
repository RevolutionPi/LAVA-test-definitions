#!/bin/bash

# shellcheck disable=SC2034
LOW=0
HIGH=1

# Function for setting the IO value
piTest_setIOValue() (
  test_case_name=$1
  variable=$2
  value=$3

  output=$(piTest -w "$variable","$value")
  ret=$?

  # XXX: hack: piTest is broken:
  #  - no proper exit code on failure
  #  - no usage of stderr for error messages

  if echo "$output" | grep -E "(Cannot find variable)|(Wrong arguments)"
  then
    lava-test-case "$test_case_name-piTest" --result fail
    return
  fi

  # XXX: piTest never seems to return an error code
  if [ $ret -ne 0 ]
  then
    lava-test-case "$test_case_name-piTest-write" --result fail
    return
  fi
)

# Function for checking the IO value
piTest_validateIOValue() (
  if [ "$(piTest -v "$2")" != "Cannot read variable info" ]
  then
    if [ "$(piTest -q -1 -r "$2")" -ne "$3" ]
    then
      lava-test-case "$1-$2" --result fail
    else
      lava-test-case "$1-$2" --result pass
    fi
  else
    lava-test-case "$1-variable-not-found-$2" --result fail
  fi
)

piTest_Check_001() (
  # $1: TEST_CASE_NAME
  # $2: INPUT
  # $3: OUTPUT
  test_case_name=$1
  input=$2
  output=$3

  # set output to low
  piTest_setIOValue "$test_case_name" "$output" "$LOW"
  # wait for process image
  sleep 1
  piTest_validateIOValue "$test_case_name" "$input" "$LOW"

  # set output to high
  piTest_setIOValue "$test_case_name" "$output" "$HIGH"
  # wait for process image
  sleep 1
  piTest_validateIOValue "$test_case_name" "$input" "$HIGH"
)
