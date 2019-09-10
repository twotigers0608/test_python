#!/usr/bin/env bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Varun Sharma(varun.sharma@intel.com)
# @desc     Bat for Swipe Test[Sensor's]
# @history  22-9-2017: First version
############################# Functions ########################################

test_adb () {
	timeout 10s adb root
	timeout 30s adb wait-for-device
	timeout 30s adb devices|grep -wc device
}
funcname='sensor_swipe_test'
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

Swipe_screen()
{
	Dev_x=`adb shell dumpsys display  | grep mOverrideDisplayInfo | grep width | cut -d',' -f10| egrep -o "[0-9]+"`
	Dev_y=`adb shell dumpsys display  | grep mOverrideDisplayInfo | grep height | cut -d',' -f11| egrep -o "[0-9]+"`
	echo $Dev_x
	echo $Dev_y
	mid_seg_x=$((Dev_x / 2 ))
	mid_seg_y=$((Dev_y / 2 ))
	echo $mid_seg_x
	echo $mid_seg_y
	y_coed_swipe=$((mid_seg_y - (mid_seg_y/2)))
#	echo $y_coed_swipe
#swipe down
adb shell input swipe $mid_seg_x $mid_seg_y $mid_seg_x $y_coed_swipe
sleep 1
#swipe up
adb shell input swipe $mid_seg_x $y_coed_swipe $mid_seg_x $mid_seg_y
}


sensor_swipe_test () {
test_adb
ret=$?
if [[ $ret -eq 1 ]] #no device found, bail out
then
	echo "Device not found: failing"
	result-out $ret
	exit 1
fi
adb shell am start -a android.settings.SETTINGS

sleep 3s
adb shell logcat -c
Swipe_screen
adb shell timeout 10s logcat |grep "action=ACTION_MOVE" >> /dev/null
ret=$?
result-out $ret
#press home button
adb shell input keyevent 3
}

sensor_swipe_test
