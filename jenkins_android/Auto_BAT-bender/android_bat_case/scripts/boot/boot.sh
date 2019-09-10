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

source "common.sh"

function tc-boot-first_boot {
    adb -s $DEVID shell dmesg > dmesg_firstboot.log &      #查看设备内核信息
    adb -s $DEVID logcat -d > logcat_firstboot.log &       #查看设备所有log
    sleep 30
    if [ -s dmesg_firstboot.log -a -s logcat_firstboot.log ]; then  #如果有log证明设备起来了
        print_info "First boot to $DEVID successfully"
    else
        print_err "Empty! Can not first boot to $DEVID"
        rm -f dmesg_firstboot.log
        rm -f logcat_firstboot.log
        return 1
    fi
    rm -f dmesg_firstboot.log
    rm -f logcat_firstboot.log
    return 0                                               #返回0代表成功
}

function tc-boot-check_boot_GUI {
    if adb -s $DEVID shell ps | grep com.android.systemui; then    #adb shell ps是查看设备里的进程,过滤出com.android.systemui就返回成功
        print_info "The device $DEVID can boot to UI"
    else
        print_err "The device $DEVID can't boot to UI"
        return 1
    fi
    return 0                                                       #返回0就是成功
}

function tc-boot-reboot {
    print_info "Start reboot"
    adb -s $DEVID reboot &           #测试设备重启
    sleep 30s
    if [ $lavafy == 'yes'  ]; then
      lxc-add-device $DEVID
    fi
    sleep 10
    adb -s $DEVID kill-server        #在这边linux主机上关闭adb服务
    adb -s $DEVID start-server       #再开启adb服务
    print_info "Executing ADB reboot...Waiting adb reconnect..."
    if [ $DEVID == "localhost:5558" ]; then
        sleep 300
    else
        sleep 30
    fi
    adb connect $DEVID > /dev/null 2>&1  #连接设备
    adb -s $DEVID root > /dev/null 2>&1  #使用root用户
    if [ $lavafy == 'yes'  ]; then
      lxc-add-device $DEVID
    fi
    adb connect $DEVID > /dev/null 2>&1  #连接设备
    if adb devices | grep $DEVID | grep "offline"; then
       print_err "The device $DEVID status is offline, can't check reboot status"
       return 1
    fi
    adb -s $DEVID shell dmesg > dmesg_reboot.log &
    adb -s $DEVID logcat -d > logcat_reboot.log &
    sleep 30
    if [ -s dmesg_reboot.log -a -s logcat_reboot.log ]; then   #设备成功启动就有日志输出就会返回一个0就是成功
        print_info "ADB reboot successfully"
    else
        print_err "ADB reboot has been failed"
        return 1
    fi
    rm -f dmesg_reboot.log
    rm -f logcat_reboot.log
    return 0
}

################################ CLI Params ####################################
# Please use getopts
while getopts  :t:vh arg                       #只是为了获取执行脚本后面的参数代码0 1之类的
do case $arg in
  t)  TESTCASE="$OPTARG";;                     #只是为了获取执行脚本后面的参数代码0 1之类的
  :)  die "$0: Must supply an argument to -$OPTARG.";;
  \?) die "Invalid Option -$OPTARG ";;
esac
done

############################### MODULE LOGIC ###################################
adb_device_check $DEVID || die "Can not connect device $DEVICE" 2   #调用的common.sh脚本里的adb_device_check这个函数,这个函数检查是否存在设备如果存在返回0不存在返回1,返回0没有错误,返回1连接不上设备,退出
root_device $DEVID || die "Cannot root device $DEVID" 2             #就是检查以下device能不能root,没什么用
if [ $lavafy == 'yes'  ]; then                                      #这步不会执行,lavafy是no
  lxc-add-device $DEVID
fi

#${FILE_ADB_PUSH:=file_to_upload}

case $TESTCASE in
  0)  tc-boot-first_boot  && exit 0 || exit 1;;
  1)  tc-boot-check_boot_GUI && exit 0 || exit 1;;
  2)  tc-boot-reboot && exit 0 || exit 1;;
  *)  echo "Invalid Option!!!"; exit 1;;
esac
