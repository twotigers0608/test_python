#!/bin/bash
#####################################################
####################  Functions  ####################
#####################################################
source "common.sh"

##########  Connect network  ##########

tc-wifi-check_wifi_connect() {
    local devid=$1
    print_info "Push wifi config file into device"
    domain_name=$(nslookup $(hostname) | awk -F'.' '{ if ($0 ~ /^Name:/) { print $2 } }')
    kver=$(adb shell uname -r|cut -d- -f1)
    kver_suffix=""
    device_wifi_conf_path="/data/misc/wifi/WifiConfigStore.xml"
    case "$kver" in
      4.19*)
        kver_suffix="_419"
        ;;
      4.9*)
        kver_suffix="_49"
        ;;
      *)
        kver_suffix=""
        ;;
    esac
    xml_file_name="WifiConfigStore_${domain_name}${kver_suffix}.xml"
    print_info "xml_file_name: $xml_file_name"
    adb -s $devid push $xml_file_name $device_wifi_conf_path
    sleep 1
    adb -s $devid reboot
    print_info "Wating device reboot..."
    sleep 30
    print_info "Open wifi..."
    adb -s $devid shell svc wifi enable
    sleep 30
    print_info "Check network connect..."
    check_network
}

##########  Check network  ##########

check_network(){
    local num=0
    local value=0
    while [[ $num -lt 5 ]]
    do
    if [[ `adb -s $DEVID shell ping -c 3 www.google.com | grep '0% packet loss'` ]]; then
        print_info 'Ping www.google.com successfully'
        stat=0
        break
    fi
    print_err 'Ping www.google.com failed'
    num=`expr $num + 1`
    sleep 5
    stat=1
    done
    return $stat
}

#####################################################
##################  Run Wifi Test  ##################
####################################################

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
adb_device_check $DEVID || die "Cannot connect device $DEVID" 2
root_device $DEVID || die "Cannot root device $DEVID" 2

case $TESTCASE in
  0) tc-wifi-check_wifi_connect $DEVID && exit 0 || exit 1;;
  *) echo "Invalid Option!!!"; exit 1;;
esac
