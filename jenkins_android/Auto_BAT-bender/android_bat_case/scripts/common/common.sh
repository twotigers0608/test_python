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

############################# Functions #######################################

source "log.sh"
lxc-add-device () {
  local devid=$1
  print_info "LAVA: Adding device lxc."
#  lava-lxc-device-add
#  print_info "waiting 120s for device..."
#  timeout 120s adb -s $devid wait-for-device
}

root_device() {
  local devid=$1

  if [ -z "$devid" ]; then
    print_err "Empty devid..."
    return 1
  fi

  adb -s $devid root
  if [ $lavafy == 'yes'  ]; then
    lxc-add-device $devid
  fi

  sleep 8s
  print_info "going to sleep for 8 sec"
  adb connect $devid > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    print_info "Device rooted"
    print_info "Waiting 15 seconds..."
    sleep 15
    return 0
  else
    print_err "Device could not be rooted"
    return 1
  fi
}

print_device_info() {
    local devid=$1
    local image=$(adb -s $devid shell getprop ro.bootimage.build.fingerprint)
    local bios=$(adb -s $devid shell getprop ro.boot.bootloader)
    print_info "DEVICE INFORMATION:"
    print_info "-------------------"
    print_info "IMAGE NAME: $image"
    print_info "BIOS NAME: $bios"
}

add_tc_result() {
  local name="$1"
  local result=$2
  local result_str=""

  if [ $result -eq 0 ]; then
    result_str="PASS"
  else
    result_str="FAIL"
  fi
  RESULTS="$RESULTS ${name}:${result_str}"
}

clear_results() {
  RESULTS=
}

print_start_tc() {
  echo "----------------------------- START TC: $(date) -----------------------"
}

print_end_tc() {
  echo "----------------------------- END TC: $(date) -------------------------"
}

print_results() {
  local tmp=

  if [ ! -d "${PWD}/results" ]; then
    print_info "Creating result directory at ${PWD}/results"
    mkdir results
  fi

  if [ ! -f "${PWD}/results/results.csv" ]; then
    print_info "Creating ${PWD}/results/results.csv file"
    touch results/results.csv
  fi

  echo "------------------------------------- RESULTS -------------------------"
  for result in $RESULTS; do
    read -a tmp <<< $(echo $result | tr ":" " ")
    printf "| %s | %s |\n" ${tmp[0]} ${tmp[1]}
    echo "${tmp[0]}, ${tmp[1]}" >> results/results.csv
  done
  echo "----------------------------------- END RESULTS ------------------------"
}

break_point() {
  local msg="$1"
  read -p "| BREAK-POINT | $msg"
  return 0
}

die() {
  local msg="$1"
  print_err "ERROR: $msg"           #调用的log.sh里的函数,返回一个0
  ec=${2:-1}
  exit $ec
}

adb_device_check() {
    if adb devices | grep $1 | grep "device"; then
        return 0
    else
        return 1
    fi
}
run_testcase() {
    tag="$1"
    func=$2
    shift 2
    params=$@
    tc_result=0

    print_start_tc
    print_info "TESTCASE NAME: $tag"
    $func $params
    tc_result=$?
    add_tc_result "$tag" $tc_result
    print_end_tc
}

progress_bar() {
    msg=$1
    timeout=$2
    func=$3
    shift 3
    params=$@
    count=0
    while [ $count -lt $timeout ]; do
        if ($func $params); then
            printf "\n"
            return 0
        fi
        printf "\r$msg: $count / $timeout"
        count=$((count + 1))
        sleep 1
    done
    printf "\n"
    die "TIMEOUT!!!"
}

is_dut_online() {
    devid=$1
    booted=$(adb -s $devid shell getprop sys.boot_completed 2> /dev/null | \
             tr -d '\r')
    test "$booted" == "1" && return 0 || return 1
}

pause() {
    msg="$1"
    print_info "$msg"
    read -n 1 -s
}

enable_wifi() {
    devid=$1
    root_device
    adb -s $devid shell svc wifi enable
    if [ $? -eq 0 ]; then
        print_info "Common.sh: Wifi Enabled"
        return 0
    else
        print_info "Common.sh: Cannot enable WiFi"
        return 1
    fi
}

disable_wifi() {
    devid=$1
    root_device
    adb -s $devid shell svc wifi disable
    if [ $? -eq 0 ]; then
        print_info "Common.sh: Wifi disabled"
        return 0
    else
        print_info "Common.sh: Cannot disable WiFi"
        return 1
    fi
}

enable_bluetooth() {
    devid=$1
    root_device
    adb -s $devid shell service call bluetooth_manager 6
    if [ $? -eq 0 ]; then
        print_info "Common.sh: Bluetooth Enabled"
        return 0
    else
        print_info "Common.sh: Cannot enable Bluetooth"
        return 1
    fi
}

disable_bluetooth() {
    devid=$1
    root_device
    adb -s $devid shell service call bluetooth_manager 8
    if [ $? -eq 0 ]; then
        print_info "Common.sh: Bluetooth disabled"
        return 0
    else
        print_info "Common.sh: Cannot disable Bluetooth"
        return 1
    fi
}

RESULTS=
