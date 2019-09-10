#!/usr/bin/env bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Varun Sharma(varun.sharma@intel.com)
# @desc     Bat for Image Zoom Test[Sensor's]
# @history  22-9-2017: First version
# Note:  com.intel.sensor_zoom_pkt_test should be present in same directory
############################# Functions ########################################

source "common.sh"

test_adb () {
	timeout 10s adb root
	if [ $lavafy == 'yes'  ]; then
		lxc-add-device $DEVID
	fi
	timeout 30s adb wait-for-device
	timeout 30s adb devices|grep -wc device
}
funcname='sensor_zoom_test'
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

Swipe_Screen_GP ()
{
	Dev_y=`adb shell dumpsys display  | grep mOverrideDisplayInfo | grep height | cut -d',' -f11| egrep -o "[0-9]+"`
	echo $Dev_y
	mid_seg_y=$((Dev_y / 2 ))
	echo $mid_seg_y
#IN GP, need to select owner after booting to get main screen
	output=$(adb shell getprop|grep ro.product.board | awk '{print $2}')
if [ "$output" = "[gordon_peak]" ];then
#	echo "GP"
	y_coed_owner=$((Dev_y - (Dev_y / 7))) #approximate co-ord for owner tap
	echo $y_coed_owner
	#using swipe instead of tap, as it covers more area
	adb shell input swipe 100 $y_coed_owner 250 $y_coed_owner
fi
}

Tap_Screen_zoom()
{
	Dev_x=`adb shell dumpsys display  | grep mOverrideDisplayInfo | grep width | cut -d',' -f10| egrep -o "[0-9]+"`
	Dev_y=`adb shell dumpsys display  | grep mOverrideDisplayInfo | grep height | cut -d',' -f11| egrep -o "[0-9]+"`
	echo $Dev_x
	echo $Dev_y
	mid_seg_x=$((Dev_x / 2 ))
	mid_seg_y=$((Dev_y / 2 ))
	echo $mid_seg_x
	echo $mid_seg_y
#Zoom in
	adb shell input tap $mid_seg_x $mid_seg_y
	adb shell input tap $mid_seg_x $mid_seg_y
	sleep 2s
#Zoom out
	adb shell input tap $mid_seg_x $mid_seg_y
	adb shell input tap $mid_seg_x $mid_seg_y
}

sensor_zoom_test () {
test_adb
ret=$?
if [[ $ret -eq 1 ]] #no device found, bail out
then
	echo "Device not found: failing"
	result-out $ret
	exit 1
fi
adb shell pm list packages|grep sensor_zoom_pkt
if [[ $? -eq 0 ]] #cleanup before starting
then
	adb uninstall com.intel.sensor_zoom_pkt_test
fi

adb shell timeout 10s logcat -c
adb install com.intel.sensor_zoom_pkt_test.apk
sleep 1s
echo "Starting app"
sleep 1s
#IN GP, need to select owner after booting to get main screen
Swipe_Screen_GP
#start app
adb shell am start -n com.intel.sensor_zoom_pkt_test/.ZoomInZoomOut
#Do double tap for Zoom in/out
Tap_Screen_zoom

adb shell timeout 10s logcat |grep "Zooming"
#Uninstall package
adb shell pm list packages|grep sensor_zoom_pkt
if [[ $? -eq 0 ]] #cleanup before exiting
then
	adb uninstall com.intel.sensor_zoom_pkt_test
fi
ret=$?
result-out $ret
}

sensor_zoom_test
