#!/bin/bash

LOW=0
HIGH=1

#Configuration left side
INPUT_L_1="I_1"
INPUT_L_2="I_3"
OUTPUT_L_1="O_1"
OUTPUT_L_2="O_3"

#Configuration right side
INPUT_R_1="I_1_i03"
INPUT_R_2="I_3_i03"
OUTPUT_R_1="O_1_i05"
OUTPUT_R_2="O_3_i05"

piTest_setIOValue()
{
  piTest -w $1,$2
}

piTest_validateIOValue()
{
	RET=$(piTest -q -1 -r $1)
	if [ $RET -ne $2 ]
	then
		lava-test-case logfile --result fail
		lava-test-raise "Test pb-1 FAIL - piTest_validateIOValue()  $1: $RET"
	else
		lava-test-case logfile --result pass
	fi	
}

#Set output LOW
VALUE=$LOW
piTest_setIOValue $OUTPUT_L_1 $VALUE
piTest_setIOValue $OUTPUT_L_2 $VALUE
piTest_setIOValue $OUTPUT_R_1 $VALUE
piTest_setIOValue $OUTPUT_R_2 $VALUE
sleep 1

#Check inputs with LOW
VALUE=$LOW
piTest_validateIOValue $INPUT_L_1 $VALUE
piTest_validateIOValue $INPUT_L_2 $VALUE
piTest_validateIOValue $INPUT_R_1 $VALUE
piTest_validateIOValue $INPUT_R_2 $VALUE

#Set output HIGH
VALUE=$HIGH
piTest_setIOValue $OUTPUT_L_1 $VALUE
piTest_setIOValue $OUTPUT_L_2 $VALUE
piTest_setIOValue $OUTPUT_R_1 $VALUE
piTest_setIOValue $OUTPUT_R_2 $VALUE
sleep 1

#Check inputs with HIGH
VALUE=$HIGH
piTest_validateIOValue $INPUT_L_1 $VALUE
piTest_validateIOValue $INPUT_L_2 $VALUE
piTest_validateIOValue $INPUT_R_1 $VALUE
piTest_validateIOValue $INPUT_R_2 $VALUE

#Set output LOW
VALUE=$LOW
piTest_setIOValue $OUTPUT_L_1 $VALUE
piTest_setIOValue $OUTPUT_L_2 $VALUE
piTest_setIOValue $OUTPUT_R_1 $VALUE
piTest_setIOValue $OUTPUT_R_2 $VALUE
sleep 1
