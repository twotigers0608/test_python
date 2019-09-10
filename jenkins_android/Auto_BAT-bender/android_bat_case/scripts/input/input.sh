#!/bin/bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Wenjie Yu(wenjiex.yu@intel.com)
# @desc     Bat for ADB
# @history  2017-01-11: First version

############################# Functions ########################################

source "log.sh"
source "common.sh"

tc-input-all_devices() {
    local devid=$1
    if (adb -s $devid shell dumpsys input | grep -e "Event Hub State" -e "Device" > /dev/null); then   #找到input服务,过滤Event Hub State
      print_info "Event Hub State section was found in Dumpsys info"
      return 0
    else
      print_err "unable to found input devices"
      return 1
    fi
}

tc-input-touchscreen_driver(){
    local devid=$1
    for i in $(adb -s $devid shell ls /sys/class/input | grep input)
    do
      i=$(echo $i | tr -d '\r')
      j=$(adb -s $devid shell cat /sys/class/input/$i/name)
      if (echo $j | grep  "Touch" > /dev/null); then
        print_info "touch input device found"
        return 0
      fi
    done
    print_err "touch input device not found"
    return 1
}

tc-input-touchscreen() {                                     #这项测试是半自动的,所有没有执行这项测试
    local devid=$1
    adb -s $devid shell getevent -l > temp &                 #getevent会输出所有event设备的信息,包括重力传感器,耳机,按钮之类的
    print_info "This tc is semi-auto"
    pause "Touch the device screen, then press enter to continue"
   adb shell kill $(adb -s $devid shell ps | grep getevent | awk '{print $2}')
   if (cat temp | grep BTN_TOUCH > /dev/null); then
     rm temp
     print_info "Touch event detected"
     return 0
   else
     rm temp
     print_err "Did not detect the touch event"
     return 1
   fi

}

while getopts  :t:vh arg
do case $arg in
  t)  TESTCASE="$OPTARG";;
  :)  die "$0: Must supply an argument to -$OPTARG.";;
  \?) die "Invalid Option -$OPTARG ";;
esac
done

adb_device_check $DEVID || die "Can not connect device $DEVICE" 2
root_device $DEVID || die "Cannot root device $DEVID" 2
if [ $lavafy == 'yes'  ]; then
  lxc-add-device $DEVID
fi

case $TESTCASE in
  0)  tc-input-all_devices $DEVID && exit 0 || exit 1;;
  1)  tc-input-touchscreen_driver $DEVID && exit 0 || exit 1;; #这项测试会执行两遍
  2)  tc-touchscreen $DEVID && exit 0 || exit 1;;              #这项并不会执行,没有传过来2这个参数,而且tc-touchscreen并没有找到
  *)  echo "Invalid Option!!!"; exit 1;;
esac

