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

function dehumanize {
    local data=$1
    local i=$((${#data}-1))
    local last=${data:$i:1}
    case $last in
        G)data=$(($(echo $data | tr -d $last)*1024));;
        K)data=$(($(echo $data | tr -d $last)/1024));;
        M)data=$(echo $data | tr -d $last);;
    esac
    return $data
}

function tc-generics-check_image_version {
    print_info "Image Version:"
    if adb -s $DEVID shell getprop | grep "ro.build.description"; then
        print_info "Success!"
    else
        print_err "Can't get image version"
        return 1
    fi
    return 0
}

function tc-generics-check_bios_version {
    print_info "Bios Version:"
    if adb -s $DEVID shell getprop | grep "ro.boot.bootloader" | grep "kernelflinger"; then
        print_info "Success!"
    else
        print_err "Can't get bios version"
        return 1
    fi
    return 0
}

function tc-generics-check_kernel_version {
    print_info "Kernel Version:"
    if adb -s $DEVID shell cat /proc/version | grep "version" | grep "Linux version"; then
        print_info "Success!"
    else
        print_err "Can't get kernel version"
        return 1
    fi
    return 0
}

function tc-generics-check_board_version {
    print_info "Board Version:"
    if adb -s $DEVID shell getprop | grep "ro.product.board"; then
        print_info "Success!"
    else
        print_err "Can't get board version"
        return 1
    fi
    return 0
}

function tc-generics-check_kernel_warning {
    adb connect $DEVID
    print_info "Kernel Warning Number:"
    if adb -s $DEVID shell dmesg | grep -i warning | wc -l; then
        print_info "Success!"
    else
        print_err "Can't get kernel warning"
        return 1
    fi
    return 0
}

function tc-generics-android_processes {
    PROCESSES_ARR=( zygote system_server surfaceflinger mediaserver )
    for process in ${PROCESSES_ARR[*]}; do
        local process_info=$(adb -s $DEVID shell "ps" | grep $process)
        local pid=$(echo $process_info | awk "{print $2}")
        local ppid=$(echo $process_info | awk "{print $3}")
        local status=$(echo $process_info | awk "{print $8}")

        if [ "x$pid" == "x" ]; then
            print_err "there is no pid for $process process"
            return 1
        fi

        if [ "x$ppid" == "x" ]; then
            print_err "there is no ppid for $process process"
            return 1
        fi

        if [ "$status" == "Z" ]; then
            print_err "the process $process is a zombie process"
        fi
    done
    return 0
}

function tc-generics-test_screen_capture {
    if adb -s $DEVID shell "screencap -p $SCREEN_CAPTURE_PATH/$SCREEN_CAPTURE_NAME"; then
        print_info "screencap executed without problems"
    else
        print_err "screencap cannot be executed"
        return 1
    fi

    size_picture=$(adb -s $DEVID shell "ls -l  $SCREEN_CAPTURE_PATH" | grep $SCREEN_CAPTURE_NAME | awk '{print $5}')
    if [ "$size_picture" != "0" ]; then
        print_info "image was saved successfully"
    else
        print_err "there was problems of the image"
        return 1
    fi

    adb -s $DEVID shell "rm $SCREEN_CAPTURE_PATH/$SCREEN_CAPTURE_NAME" > /dev/null
    return 0
}

function tc-generics-test_kernel_cmdline {
    KERNEL_CMDLINE=$(adb -s $DEVID shell cat /proc/cmdline)
    local CMDLINE_PARAMS=(firmware_class.path=/vendor/firmware \
	vga=current console=ttyS2,115200n8)

    echo $KERNEL_CMDLINE >tmp.txt
    for i in ${!CMDLINE_PARAMS[*]}; do
        if  cat tmp.txt | grep ${CMDLINE_PARAMS[$i]}; then
            print_info "the parameter ${CMDLINE_PARAMS[$i]} is in cmdline path"
        else
            print_err "the parameter ${CMDLINE_PARAMS[$i]} not exist in cmdline patch"
            return 1
        fi
    done
    rm tmp.txt
    return 0;
}

function tc-generics-test_partitions {
    adb -s $DEVID shell "df" | {
        while IFS='' read -r line; do
            local size=$(echo $line | awk '{print $4}')
            local partition=$(echo $line | awk '{print $1}')
            if echo $size | grep -E "K|M|G"; then
                size=$(dehumanize $size)
            fi
	    print_info $size
            if [ "$size" \< "100" ]; then
                print_err "the partition $partition is smaller than 100MB"
                return 1
            fi
        done
    }
    return 0
}

function tc-generics-test_mount {

# list of devices to verify rights read-only(ro) read-write(rw) and so on
local MOUNTED_DEVICES=("/data" "/system")
local MOUNTED_DEVICES_RIGHTS=(rw ro)
    adb -s $DEVID shell "mount" | {
        while IFS='' read -r line; do
            for i in ${!MOUNTED_DEVICES[*]}; do
                local mountpoint=$(echo $line | awk "{print $2}")
                local rights=$(echo $line | awk "{print $4}")
                if echo $line | grep ${MOUNTED_DEVICES[$i]}; then
                    if  !( echo $rights | grep ${MOUNTED_DEVICES_RIGHTS[$i]} ); then
                        print_err "the mountoint ${MOUNTED_DEVICES[$i]} "\
                            "doesn't have the rights ${MOUNTED_DEVICES_RIGHTS[$i]}"
                        return 1
                    fi
                fi
            done
        done
    }
    return 0
}

function tc-generics-test_cpuinfo {
    CPU_ATTRIBUTES=()
    CPU_VALUES=()
    adb -s $DEVID shell "cat $CPUINFO_PATH" | {
        while IFS='' read -r line; do
            for i in ${!CPU_ATTRIBUTES[*]}; do
                if echo $line | grep ${CPU_ATTRIBUTES[$i]}; then
                    if !(echo $line | grep ${CPU_VALUES[$i]}); then
                        print_err "the attribute ${CPU_ATTRIBUTES[$i]} "\
                            "doesn't have the value ${CPU_VALUES[$i]}"
                        return 1
                    fi
                fi
            done
        done
    }
    return 0
}

function tc-generics-tombstones {
    local pid=$(adb -s $DEVID shell "ps" | grep surfaceflinger | awk '{print $2}')
    if adb -s $DEVID shell "kill -6 $pid"; then
        print_info "signal 6 sent to pid($pid)"
    else
        print_err "error sending signal 6 to pid($pid)"
        return 1
    fi

    sleep 5
    if adb -s $DEVID shell "ls $TOMBSTONES_PATH" | grep tombstone; then
        print_info "tombstones was created"
    else
        print_err "error tombstones was not created"
        return 1
    fi
    return 0
}

function tc-generics-trace {
    local pid=$(adb -s $DEVID shell "ps" | grep system_server | awk '{print $2}')
    if adb -s $DEVID shell "kill -3 $pid"; then
        print_info "signal 3 sent to pid($pid)"
    else
        print_err "error sending signal 3 to pid($pid)"
        return 1
    fi

    sleep 5
    if adb -s $DEVID shell "ls $TRACE_PATH" | grep "^trace_"; then
        print_info "trace logs found without problems"
    else
        print_err "error finding trace logs"
        return 1
    fi
    return 0
}

function tc-generics-panic {
    print_info "Testing force crash. Wait 5mins to reboot..."
    adb -s $DEVID shell "echo c > /proc/sysrq-trigger">/dev/null 2>&1 &
    sleep 300
    adb -s $DEVID kill-server
    adb -s $DEVID start-server
    print_info "kill and start server again,please wait..."
    adb connect $DEVID > /dev/null 2>&1
    adb -s $DEVID root > /dev/null 2>&1
    if [ $lavafy == 'yes'  ]; then
        lxc-add-device $DEVID
    fi
    adb connect $DEVID > /dev/null 2>&1
    if adb -s $DEVID shell "ps" | grep com.android.systemui; then
        print_info "Find the 'com.android.systemui' process"
        print_info "successfully reboot to homescreen"
    else
        print_err "error reboot to homescreen"
        return 1
    fi
    return 0
}

function tc-generics-check_kernel_config {
    KERNEL_VERSION=$(adb -s $DEVID shell uname -a | cut -d " " -f 3)
    print_info "Check the current user account ..."
    USER=$(env | grep USER=root| cut -d "=" -f 2)
    if [ "$USER" == "root" ]; then
        print_info "Current user account is root"
        if [ ! -f "/usr/bin/python3" ]; then
            apt-get install -y python3
        fi
        if [ ! -f "/usr/bin/git" ]; then
            apt-get install -y git
        fi
        print_info "Download kernel-config-checker tool from TeamForge otc_kernel_services projects"
        if [ -d "otc_kernel_services-kcc" ]; then
            rm -rf otc_kernel_services-kcc
        fi
        unset http_proxy
        unset https_proxy
        # Please confirm that the test host is using the private key of sys_oak
        # or you can manually use your own user rights.
        git clone ssh://sys_sysoakro@git-ccr-1.devtools.intel.com:29418/otc_kernel_services-kcc
        cd otc_kernel_services-kcc
        /usr/bin/python3 setup.py build
        /usr/bin/python3 setup.py install
        cd ..
        kcc -h > /dev/null 2>&1
        if [ $? == 0 ]; then
            print_info "Kcc tool installed successfully !"
        else
            print_err "Kcc tool installation failed! Please check the Kcc installation!"
        fi
        adb pull /proc/config.gz
        mv config.gz results/config-$KERNEL_VERSION.gz
        zcat results/config-$KERNEL_VERSION.gz | kcc --query >results/kccr-$KERNEL_VERSION.txt
        if cat results/kccr-$KERNEL_VERSION.txt | grep "is not set but is required to be set to y" || cat kccr-$KERNEL_VERSION.txt | grep "is set but is required to be not set"; then
             print_err "The kernel config is not right and not security!!!"
             return 1
        else
             print_info "The kernel config is security."
             return 0
        fi
    else
        print_err "Current user account is not root !!!"
        return 1
     fi
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
adb_device_check $DEVID || die "Can not connect device $DEVICE" 2
root_device $DEVID || die "Cannot root device $DEVID" 2

#${FILE_ADB_PUSH:=file_to_upload}

case $TESTCASE in
    1)  tc-generics-check_image_version && exit 0 || exit 1;;
    2)  tc-generics-check_bios_version && exit 0 || exit 1;;
    3)  tc-generics-check_kernel_version && exit 0 || exit 1;;
    4)  tc-generics-check_board_version && exit 0 || exit 1;;
    5)  tc-generics-check_kernel_warning && exit 0 || exit 1;;
    6)  tc-generics-android_processes && exit 0 || exit 1;;
    7)  tc-generics-test_screen_capture && exit 0 || exit 1;;
    8)  tc-generics-test_kernel_cmdline && exit 0 || exit 1;;
    9)  tc-generics-test_partitions && exit 0 || exit 1;;
    10)  tc-generics-test_mount && exit 0 || exit 1;;
    11)  tc-generics-test_cpuinfo && exit 0 || exit 1;;
    12)  tc-generics-tombstones && exit 0 || exit 1;;
    13)  tc-generics-trace && exit 0 || exit 1;;
    14)  tc-generics-panic && exit 0 || exit 1;;
    15)  tc-generics-check_kernel_config && exit 0 || exit 1;;
  *)  echo "Invalid Option!!!"; exit 1;;
esac
