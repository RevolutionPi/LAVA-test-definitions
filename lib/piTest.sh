#!/bin/bash

# shellcheck disable=SC2034
LOW=0
HIGH=1

# Function for setting the IO value
piTest_setIOValue() {
  piTest -w "$1","$2"
}

# Function for checking the IO value
piTest_validateIOValue() {
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
}

piTest_Check_001() {
  # $1: TEST_CASE_NAME
  # $2: INPUT
  # $3: OUTPUT

  # set output to low
  piTest_setIOValue "$3" "$LOW"
  # wait for process image
  sleep 1
  piTest_validateIOValue "$1" "$2" "$LOW"

  # set output to high
  piTest_setIOValue "$3" "$HIGH"
  # wait for process image
  sleep 1
  piTest_validateIOValue "$1" "$2" "$HIGH"

}
