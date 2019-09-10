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

function tc-check-adb {
    adb connect $DEVID
    if adb -s $DEVID devices | egrep "^\w*%DEVID\w*+device"; then
        print_info "Connect to $DEVID"
    else
        print_err "Can not connect to $DEVID"
        return 1
    fi
    return 0
}

function tc-adb-connect {
    adb connect $DEVID
    if adb -s $DEVID devices; then
        print_info "Connect to $DEVID"
    else
        print_err "Can not connect to $DEVID"
        return 1
    fi
    return 0
}

function tc-adb-push {
    if adb -s $DEVID push \
        $UD_FILE_LOCAL_PATH/file_to_upload $UD_FILE_REMOTE_PATH/; then
        print_info "ADB push has been finished successfuly"
    else
        print_err "ADB push has failed"
        return 1
    fi

    if adb -s $DEVID shell ls $UD_FILE_REMOTE_PATH/ | grep file_to_upload; then
        print_info "ADB push uploaded the file successfully"
    else
        print_err "ADB push didn't upload the file"
        return 1
    fi
    return 0
}

function tc-adb-pull {
    if adb -s $DEVID pull $UD_FILE_REMOTE_PATH/file_to_upload \
        $UD_FILE_LOCAL_PATH/$FILE_ADB_PULL_NAME; then
        print_info "ADB pull has been finished successfuly"
    else
        print_err "ADB pull has failed"
        return 1
    fi

    if ls $UD_FILE_LOCAL_PATH/ | grep $FILE_ADB_PULL_NAME; then
        print_info "ADB pull download the file successfully"
    else
        print_err "ADB pull didn't download the file"
        return 1
    fi
    return 0
}

function tc-adb-remount {
    adb -s $DEVID shell getprop | grep "ro.build.version.release" | cut -d ":" -f 2 >tmp.txt
    echo "Android Version is $(cat tmp.txt)"
    sed -i "s/\[//g" tmp.txt
    sed -i "s/\]//g" tmp.txt
    ANDROID_VERSION=$(cat tmp.txt | cut -d "." -f 1)
    rm -rf tmp.txt
    PRODUCT_NAME=$(adb -s $DEVID shell getprop | grep "ro.product.board" | cut -d ":" -f 2)
    if [[ $ANDROID_VERSION -ge 8 ]] && [[ $PRODUCT_NAME =~ "gordon_peak" ]]; then
       echo -e "\ndisable dm-verity on Android O/P release for product $PRODUCT_NAME\n"
       adb -s $DEVID reboot bootloader
       sleep 20
       echo $(fastboot devices) | awk  '{printf $1 "\n"}' >tmp.txt
       if [ $(cat tmp.txt) == "$DEVID" ]; then
	   echo "start to flash vbmeta_disable_verity.img ..."
	   fastboot -s $DEVID flashing unlock
	   sleep 3
	   fastboot -s $DEVID flash vbmeta_a ./scripts/adb/vbmeta_disable_verity.img
	   sleep 3
	   fastboot -s $DEVID flashing lock
	   sleep 3
	   fastboot -s $DEVID reboot
	   sleep 120
       else
	   echo "device can't enter into fastboot mode"
	   return 1
       fi
    else
        echo -e "\nno need to disable dm-verity for product $PRODUCT_NAME\n"
    fi
    rm -rf tmp.txt
    adb -s $DEVID root
    if adb -s $DEVID remount | grep succeeded; then
        print_info "ADB remount has been finished without problems"
    else
        print_err "ADB remount failed"
        return 1
    fi

    if adb -s $DEVID shell mkdir /system/test-remount; then
        print_info "ADB has been remounted /system successfully"
        return 0
    else
        print_err "ADB has not been remounted /system successfully"
        return 1
    fi
}

function tc-adb-install {
    if adb -s $DEVID install $UD_FILE_LOCAL_PATH/$APK_TO_INSTALL; then
        print_info "ADB install has been excecuted without problems"
    else
        print_err "ADB install has been excecuted with problems"
        return 1
    fi

    if adb -s $DEVID shell pm list packages | grep -E $APK_PACKAGE_PATTERN; then
        print_info "ADB install has installed the apk successfully"
        return 0
    else
        print_err "ADB install has failed installing the package"
        return 1
    fi
}

function tc-adb-uninstall {
    local package_name=$( adb -s $DEVID shell "pm list packages" | \
        grep -E $APK_PACKAGE_PATTERN | tr -d '\r')
    package_name=${package_name//package\:/}

    if adb -s $DEVID uninstall $package_name; then
        print_info "ADB uninstall has been running successfully"
    else
        print_err "ADB uninstall has been running with problems"
        return 1
    fi

    if adb -s $DEVID shell "pm list packages" | \
        grep -E $APK_PACKAGE_PATTERN; then
        print_err "ADB uninstall cannot uninstall the apk"
        return 1
    else
        print_info "ADB uninstall has uninstalled the apk successfully"
        return 0
    fi
}

function tc-adb-enable-wifi {
    enable_wifi $DEVID
    sleep 2s
    sys_check_wifi=`adb -s ${DEVID} shell dumpsys wifi | grep -c "Wi-Fi is enabled"`
    echo "The results for dumpsys" ${sys_check_wifi}
    if [ ${sys_check_wifi} == '1' ]; then
        print_info "WiFi Enabled"
        return 0
    else
        print_err "Can not enable WiFi"
        return 1
    fi
}

#function tc-adb-config-Network {
#
#}

function tc-adb-wifi-ping {
    sleep 8s
    check_wifi_ping=`adb -s ${DEVID} shell ping -c 3 $EXTERNAL_SITE | grep -c "3 packets transmitted"`
    if [ ${check_wifi_ping} == '1' ]; then
        print_info "WiFi Transmitted 3 packets"
        return 0
    else
        print_err "Can not transmit thru WiFi"
        return 1
    fi
}

function tc-adb-disable-wifi {
    disable_wifi $DEVID
    sleep 2s
    sys_check_wifi=`adb -s ${DEVID} shell dumpsys wifi | grep -c "Wi-Fi is disabled"`
    if [ ${sys_check_wifi} == '1' ]; then
        print_info "WiFi Disabled"
        return 0
    else
        print_err "Can not disable WiFi"
        return 1
    fi
}

function tc-adb-enable-bluetooth {
    enable_bluetooth $DEVID
    sleep 2s
    sys_check_bt=`adb -s ${DEVID} shell dumpsys bluetooth_manager | grep -c "  enabled: true"`
    if [ ${sys_check_bt} == '1' ]; then
        print_info "Bluetooth Enabled."
        return 0
    else
        print_err "Can not Enable bluetooth"
        return 1
    fi
}

function tc-adb-disable-bluetooth {
    disable_bluetooth $DEVID
    sleep 2s
    sys_check_bt=`adb -s ${DEVID} shell dumpsys bluetooth_manager | grep -c "  enabled: false"`
    if [ ${sys_check_bt} == '1' ]; then
        print_info "Bluetooth Disabled"
        return 0
    else
        print_err "Can not Disable Bluetooth"
        return 1
    fi
}

function tc-adb-lan-ping {
    check_eth=`adb -s ${DEVID} shell ping -c 3 $INTERNAL_SITE | grep -c "3 packets transmitted"`
    if [ ${check_eth} == '1' ]; then
        print_info "Ethernet Transmitted 3 packets"
        return 0
    else
        print_err "Can not transmit thru Ethernet"
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
if [ $lavafy == 'yes'  ]; then
  lxc-add-device $DEVID
fi

#${FILE_ADB_PUSH:=file_to_upload}

case $TESTCASE in
  0)  tc-adb-connect && exit 0 || exit 1;;
  1)  tc-adb-push && exit 0 || exit 1;;
  2)  tc-adb-pull && exit 0 || exit 1;;
  3)  tc-adb-remount && exit 0 || exit 1;;
  4)  tc-adb-install && exit 0 || exit 1;;
  5)  tc-adb-uninstall && exit 0 || exit 1;;
  6)  tc-adb-enable-wifi && exit 0 || exit 1;;
  7)  tc-adb-wifi-ping && exit 0 || exit 1;;
  8)  tc-adb-disable-wifi && exit 0 || exit 1;;
  9)  tc-adb-enable-bluetooth && exit 0 || exit 1;;
  10)  tc-adb-disable-bluetooth && exit 0 || exit 1;;
  11)  tc-adb-lan-ping && exit 0 || exit 1;;
  *)  echo "Invalid Option!!!"; exit 1;;
esac
