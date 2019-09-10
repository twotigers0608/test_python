#!/usr/bin/env bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Varun Sharma(varun.sharma@intel.com)
# @desc     Bat for IIO Test[Sensor's]
# @history  12-2-2018: First version
############################# Functions ########################################

while getopts d: option
do
	case "${option}"
		in
		d) DEVID=${OPTARG}
			export ADB="adb -s "$DEVID
			echo $ADB
		;;
	esac
done

test_adb () {
	timeout 10s adb root
	timeout 30s adb devices|grep -w device|grep $DEVID
}
funcname='iio_sensor_test'
result-out () {
ret=$1
if [ $ret == 0 ]
then
	test_value='pass'
	echo "pass"
else
	test_value='fail'
	echo "fail"
fi
if [ $ret == 3 ]
then
	test_value='skip'
	echo "skip"
fi
lava-test-case $funcname --result $test_value
}

iio_sensor_test () {
echo "...adb connection test..."
test_adb
ret=$?
if [[ $ret -eq 1 ]] #no device found, bail out
then
	echo "Device not found: failing"
	result-out $ret
	exit 1
else
	echo $DEV_ID
fi
result-out $ret
rm -rf  /tmp/iio_results/
mkdir -p /tmp/iio_results/
./test_script.sh -d $DEVID -l 4 -e . -r /data/tmp -o /tmp/iio_results -s "$PWD"/test.txt
#echo "Script o/p is:"$?

sleep 3s
grep -inr "failed" /tmp/iio_results/|grep tests_results
if [[ $? -eq 1 ]]
then
    ret=0
else
    ret=1
fi
result-out $ret
}
iio_sensor_test
