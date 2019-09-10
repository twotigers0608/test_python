#!/usr/bin/env bash
################################################################################
# Copyright (C) 2018 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################
# @Author   Zhanghui Yuan(zhanghuix.yuan@intel.com)
# @history  28-06-2018: Second version
# @desc     check the power status about suspend resume
#           Step 1: Connect the DUT and Debug board (only for GP) to USB.
#           Step 2: Check the suspend value before suspend/resume
#           Step 3: Remove power wake lock
#           Step 4: Enable initcall_debug function for kernel
#           Step 5: Setup the loglevel for kernel message
#           Step 6: Disable the console suspend when systerm occurs IPANIC issue
#           Step 7: Start to suspend and resume from ioc console
#           Step 8: Check the suspend value after suspend/resume
#           Step 9: Check the dmesg log about S3 mode
############################# Functions ########################################
source "common.sh"

function tc-check-adb() {
    device_status=$(adb devices | grep $DEVID | cut -f 2)
    if [[ $device_status == "device" ]]; then
        echo "device $DEVID is connected"
        return 0
    elif [[ $device_status == "offline" ]]; then
        echo "device is offline"
        return 1
    else
        echo "device can not been found"
        return 1
    fi
}

function tc-pm-suspend-resume() {
    echo -e "\nSetup Before Suspend/Resume Test ...\n"
    tc-check-adb || exit 1
    adb -s $DEVID root
    sleep 5
    adb -s $DEVID wait-for-device
    echo "Remove power wake lock"
    adb -s $DEVID shell "echo pyunit > /sys/power/wake_unlock"
    sleep 2
    echo "Enable initcall_debug function for kernel"
    adb -s $DEVID shell "echo 1 > /sys/module/kernel/parameters/initcall_debug"
    adb -s $DEVID shell "cat /sys/module/kernel/parameters/initcall_debug"
    sleep 2
    echo "Setup the loglevel=9 for kernel message"
    adb -s $DEVID shell "echo 9 > /proc/sys/kernel/printk"
    adb -s $DEVID shell "cat /proc/sys/kernel/printk"
    sleep 2
    echo "Disable the console suspend when systerm occurs IPANIC issue"
    adb -s $DEVID shell "echo N > /sys/module/printk/parameters/console_suspend"
    adb -s $DEVID shell "cat /sys/module/printk/parameters/console_suspend"

    suspend_value_before=$(adb -s $DEVID shell cat /d/suspend_stats | grep "success:" | cut -d ":" -f 2)
    echo -e "\nSuspend value is $suspend_value_before before suspend/resume\n"
    product_name=$(adb -s $DEVID shell getprop | grep "ro.product.board" | cut -d ":" -f 2 | sed 's/\[//g' | sed 's/\]//g')
    echo -e "\nThe product name is $product_name\n"

    lasttime=$(adb -s $DEVID shell dmesg | tail -1 | cut -d']' -f1 | sed 's/.*\[\|\s//g')
    boot_gui=$(adb -s $DEVID shell ps -ef | grep "com.android.systemui")
    sleeptime=20

    if [[ $product_name =~ "gordon_peak" ]]; then
        chmod 777 /dev/ttyUSB2
        successcount=$(adb -s $DEVID shell cat /d/suspend_stats | grep "success:" | cut -d ":" -f 2)
        failedcount=$(adb -s $DEVID shell cat /d/suspend_stats | grep "fail:" | cut -d ":" -f 2)
        if [ $successcount -lt 1 ] && [ $failedcount -lt 1 ]; then
            loop=0
            sleeptime=60
            echo -e "\nFirst time to run suspend/resume test, try ignition button press 5 times\n"
            while [ $loop -lt 5 ]; do
                echo g >/dev/ttyUSB2
                sleep $sleeptime
                tc-check-adb
                device_status=$?
                if [[ $device_status -ne 1 ]]; then
                    echo -e "\nIn loop $loop, device can't suspend, re-try\n"
                    let loop=$loop+1
                else
                    echo -e "\nSuspend seems working after loop $loop\n"
                    break
                fi
            done
            if [[ $loop==5 ]] && [[ $device_status -ne 1 ]]; then
                echo -e "\nSuspend/resume failed after try 5 times\n"
                return 1
            else
                echo g >/dev/ttyUSB2
                sleep $sleeptime
            fi
        else
            echo -e "\nSuspend/resume through IOC console and sleep $sleeptime s ...\n"
            echo g >/dev/ttyUSB2
            sleep $sleeptime
            echo g >/dev/ttyUSB2
            sleep $sleeptime
        fi
   else
        echo -e "Suspend/resume through 'echo mem > /sys/power/pm_test' and sleep 30s ..."
        adb -s $DEVID shell "echo core > /sys/power/pm_test"
        adb -s $DEVID shell "echo mem > /sys/power/pm_test"
        sleep 30
    fi

    tc-check-adb || exit 1
    adb -s $DEVID root
    sleep 5
    suspend_value_after=$(adb -s $DEVID shell cat /d/suspend_stats | grep "success:" | cut -d ":" -f 2)
    echo -e "\nsuspend value is $suspend_value_after after suspend/resume\n"
    suffix=`date +%F_%H_%M_%S`
    result=$(adb -s $DEVID shell dmesg | sed "1,/$lasttime/d")
    echo "latest dmesg is: $result" >>results/dmesg-$suffix.log

    if [[ $boot_gui =~ "com.android.systemui" ]]; then
        if [[ $suspend_value_after -gt $suspend_value_before ]]; then
            if cat results/dmesg-$suffix.log | grep "ACPI: Waking up from system sleep state S3"; then
                 print_info "suspend/resume success"
            else
                 print_err "suspend/resume failed"
             fi
        else
            print_err "device can not go to suspend/resume"
            return 1
        fi
   else
       print_err "device can not boot to GUI after suspend/resume test"
   fi
}

function tc-pm-suspend-resume-stress(){
    counter=0
    while [ $counter -lt 20 ]; do
        echo "--------------- Loop $counter Suspend & Resume Test ---------------"
        tc-pm-suspend-resume || exit 1
        let counter=counter+1
   done
}

################################ CLI Params ####################################
# Please use getopts
while getopts  :t:vh arg
do case $arg in
  t)  TESTCASE="$OPTARG";;
  :)  die "$0: Must supply an argument to -$OPTARG.";;
  \?) die "Invalid Option -$OPTARG ";;
esac
done

############################### MODULE LOGIC ###################################
case $TESTCASE in
  0)  tc-check-adb && exit 0 || exit 1;;
  1)  tc-pm-suspend-resume && exit 0 || exit 1;;
  2)  tc-pm-suspend-resume-stress && exit 0 || exit 1;;
  *)  echo "Invalid Option!!!"; exit 1;;
esac
