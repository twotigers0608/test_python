#!/usr/bin/env bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Varun Sharma(varun.sharma@intel.com)
# @desc     In this script, Testcase :- Legacy Suspend/"SYS_POWER_MANAGEMENT_PWR_TURN_OFF_DISPLAY_WHEN_IDLE" is automated 
# @history  25-9-2017: First version
#Step 1 Connect the DUT to USB.
#Step 2 Clear the sleep_state file
#adb root
#adb shell
#echo clear > /d/suspend_stats
#cat /d/suspend_stats
#Step 3  Press the ignition button to enter S3
#Step 4  Press the ignition button to resume from S3
#Step 5 check with adb command
#adb shell
#cat /d/suspend_stats
#check that Legacy-suspend value is different from 0 (time in second)
#Usage:- ./pm_legacy_suspend.sh
############################# Functions ########################################

test_adb () {
	timeout 10s adb root
	if [ $lavafy == 'yes'  ]; then
		lxc-add-device $DEVID
	fi
	timeout 30s adb wait-for-device
	timeout 30s adb devices|grep -wc device
}
funcname='power_suspend_test'
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
power_suspend_test () {
test_adb
ret=$?
if [[ $ret -eq 1 ]] #no device found, bail out
then
	echo "Device not found: failing"
	result-out $ret
fi

adb shell "echo clear > /d/suspend_stats"
adb shell "cat /d/suspend_stats"
#Step 3  Press the ignition button to enter S3
/share/.new_relays.py toggle_relay 1 3
sleep 10s
#Step 4  Press the ignition button to resume from S3
/share/.new_relays.py toggle_relay 1 3
#Step 5 check with adb command
#If success == 0 && failed_suspend == 0, it means that DUT does not even try to enter suspend state, such as blocked by wake lock.
#Only if failed_suspend > 0,  it means DUT try to enter suspend state but failed due to some issues
#so if  success == 0, that meas suspend didn't happened either due to wakelock or some other issue, echo value of failed_suspend in such case to help developer know
Result=$(adb shell cat /d/suspend_stats|grep "success")
echo $Result
if [[ "$Result" == "success: 0" ]] # success:0 means device  didn't go to suspend
then
	result-out 1 #fail
	adb shell cat /d/suspend_stats # for debugging purpose
else
	result-out 0 #pass
fi
}
power_suspend_test
