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

source "common.sh"

tc-security-disk_encryption() {
    local devid=$1
    if (adb -s $devid shell getprop | grep -i crypt | grep encrypted); then   #测试磁盘加密
      print_info "The disk state is encypted"
      return 0
    else
      print_err "The disk state is not encrypted"
      return 1
    fi
}

tc-security-keymaster_1() {
    local devid=$1
    if (adb -s $devid logcat -d | grep -i keymaster | grep Keymaster\ 1.0); then
      print_info "Find Keymaster 1.0"
      return 0
    else
      print_err "Can not find Keymaster 1.0"
      return 1
    fi
}

tc-security-selinux_support() {
    local devid=$1
    mode=$(adb -s $devid shell getenforce)
    echo "The present Android SELinux mode is : $mode"
    if [ $mode == "Enforcing" ]; then
        echo "Switch SELinux mode to Permissive"
	if (adb -s $devid shell setenforce 0);then
            print_info "Switch SELinux mode to Permissive successfully"
            return 0
        else
	    print_err "Switch SELinux mode to Permissive failed"
	    return 1
        fi

    elif [ $mode == "Permissive" ]; then
        echo "Switch SELinux mode to Enforcing"
	if (adb -s $devid shell setenforce 1);then
	    print_info "Switch SELinux mode to Enforcing successfully"
	    return 0
	else
	    print_err "Switch SELinux mode to Enforcing failed"
	    return 1
	fi
    else
	print_err "Unknown SELinux mode"
	return 1
    fi
}

ts-security-secure_adb() {
   local devid=$1
    if (adb -s $devid shell cat /adb_keys > /dev/null); then
      print_info "Can display adb keys"
      return 0
    else
      print_err "Can not display adb keys"
      return 1
    fi
}

tc-security-system_mount_readonly() {
    local devid=$1
    if(adb -s $devid shell getprop | grep "ro.product.device" | grep "\[icl_presi\]"); then
      #Test device is icl-simics, it can't find the device after "adb reboot"
      print_info "Need reboot manually and test command with "adb shell mkdir /system/test""
      return 1
    else
      #Why we need to reboot:
      #We always test all BAT test cases together.
      #Some of the previous test cases(for example: adb remount) will affect this test case
      print_info "Adb reboot, Wait 2 mins to clean environment..."
      adb -s $devid reboot
      if [ $lavafy == 'yes'  ]; then
        lxc-add-device $devid
      fi
      sleep 120
      adb_device_check $devid || die "Can not connect device $devid" 2
      root_device $devid || die "Cannot root device $devid" 2
      if [ $lavafy == 'yes'  ]; then
        lxc-add-device $devid
      fi
      adb -s $devid shell mkdir /system/test
      if [ $? != "0" ] ; then
        print_info "System mounts are read-only"
        return 0
      else
        print_err "System mounts are not read-only"
        adb -s $devid shell rm -fr /system/test
        return 1
      fi
    fi
}

tc-security-meltdown() {
    local devid=$1
    meltdown_path="../android_domain_case/security/meltdown"
    meltdown_log=meltdown.log
    ./${meltdown_path}/run_meltdown.sh -d $devid
    if [ $? -eq 0 ] ; then
        print_info "meltdown test run success"
        attack_result=$(cat results/${meltdown_log} | grep "NOT VULNERABLE")
        [ -n "$attack_result" ] && return 0 || return 1
	if [ -n "$attack_result" ]; then
            echo -e "You device is NOT VULNERABLE"
	    return 0
	else
            echo -e "You device is VULNERABLE !!!"
	    return 1
	fi
    else
        print_err "meltdown test run failed"
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
  0)  tc-security-disk_encryption $DEVID && exit 0 || exit 1;;
  1)  tc-security-keymaster_1 $DEVID && exit 0 || exit 1;;
  2)  tc-security-selinux_support $DEVID && exit 0 || exit 1;;
  3)  ts-security-secure_adb $DEVID && exit 0 || exit 1;;
  4)  tc-security-system_mount_readonly $DEVID && exit 0 || exit 1;;
  5)  tc-security-meltdown $DEVID && exit 0 || exit 1;;
  *)  echo "Invalid Option!!!"; exit 1;;
esac

