#!/usr/bin/env bash

VMLINUZ_DST='/boot/EFI/org.clearlinux'
LIB_DST='/lib/modules'
CFG_DST='/lib/kernel'
LOADER='/boot/loader/loader.conf'
ENTRY_DIR='/boot/loader/entries'
BOOT_PART=''
CUR_ENTRY=''

usage() {
        cat <<EOF

USAGE:
    $(basename $0) -k vmlinx*** -l 4.14-**
#    $(basename $0) -k vmlinx*** -l 4.14-** -c config**

    k = kernel location
    l = module location
#    c = config location
    h|? = help (this screen)



EOF
    exit 1
}

while getopts "k:l:c:h?" opt; do
    case $opt in
      k)
        VMLINUZ=${OPTARG}
        ;;
      l)
        LIB=${OPTARG}
        ;;
      #c)
      #  CONFIG=${OPTARG}
      #  ;;
      h|?)
        usage
        ;;
    esac
done

if [ -z "$VMLINUZ" ] ; then
    echo "No vmlinux"
    usage
fi
if [ -z "$LIB" ] ; then
    echo "no lib!"
    usage
fi
#if [ -z "$CONFIG" ] ; then
#    echo "no config!"
#    usage
#fi

LOADER_CONF="default Clear-linux-$(echo $VMLINUZ | awk -F '/' '{print $NF}')"
ENTRY="${ENTRY_DIR}/$( echo ${LOADER_CONF} | cut -d ' ' -f 2 ).conf"

INFO(){
    echo "[clr][$(date +%m%d-%H:%M:%S)]: $@"
}

check_params(){
    local vmlinuz=$1
    local lib=$2
#    local lib=$3
#    local config=$3
    if [ $# -ne 2 ]; then
#    if [ $# -ne 3 ]; then
        INFO "target vmlinuz lib are needed"
        exit 1
    else
        [ -f "$vmlinuz" ] || INFO "error, $vmlinuz file is not existent"
        [ -d "$lib" ] || INFO "error, $lib module is not existent"
#        [ -f "$config" ] || INFO "error, $config file is not existent"
    fi
}

replace_kernel(){
    INFO "Delete original PKT kernel file"
    rm -rf $VMLINUZ_DST/vmlinu*PKT*
    INFO "Copy $VMLINUZ to $VMLINUZ_DST"
    cp $VMLINUZ $VMLINUZ_DST
    [ $? -eq 0 ] && INFO "Copy kernel finished" || INFO "error, copy $VMLINUZ failed"
    INFO "Delete original PKT kernel modules"
    rm -rf $LIB_DST/*PKT*
    INFO "Copy $LIB to $LIB_DST"
    cp -rf $LIB $LIB_DST
    [ $? -eq 0 ] && INFO "Copy module finished" || INFO "error, copy $LIB failed"
#    INFO "Delete original PKT kernel config"
#    rm -rf $CFG_DST/*PKT*
#    INFO "Copy $CONFIG to $CFG_DST"
#    cp -rf $CONFIG $CFG_DST
#    [ $? -eq 0 ] && INFO "Copy config finished" || INFO "error, copy $CONFIG failed"

    INFO "backup and modify $LOADER"
    cp $LOADER ${LOADER}.bak
    INFO "loader.conf: ${LOADER_CONF}"
    echo "${LOADER_CONF}" > $LOADER

    INFO "Create entry file: $ENTRY"
    for file in $(ls $ENTRY_DIR); do
        CUR_ENTRY=$(echo $file | grep "$(uname -r | awk -F'-' '{print $1}')")
        [ -z "${CUR_ENTRY}" ] || break
    done
    INFO "CUR_ENTRY: ${CUR_ENTRY}"
    if [[ -n ${CUR_ENTRY} ]]; then
        cp "${ENTRY_DIR}/${CUR_ENTRY}" "$ENTRY"
        sed -i "2c linux /EFI/org.clearlinux/${VMLINUZ##*/}" $ENTRY
        [ -n "$(cat $ENTRY | grep 'rootwait')" ] || sed -i 's/ rw/ rw rootwait/' $ENTRY
        [ -n "$(cat $ENTRY | grep 'console=ttyS2')" ] || sed -i 's/ rw/ rw console=ttyS2/' $ENTRY
        [ -n "$(cat $ENTRY | grep 'pcie_port_pm=off')" ] ||\
        sed -i 's/ rw/ rw pcie_port_pm=off/' $ENTRY
    else
        INFO "Error. Current entry file was not found"
        exit 2
    fi
}

#check_params $VMLINUZ $LIB $CONFIG
check_params $VMLINUZ $LIB

BOOT_PART=$(fdisk -l | grep EFI | awk '{print $1}'|head -1)
if [ -n ${BOOT_PART} ] && [ -z "$(ls /boot)" ]; then
    INFO "boot partition: $BOOT_PART, mount to /boot"
    mount $BOOT_PART /boot || INFO "error. mount boot partition to /boot failed"
elif [ -n "$(ls /boot)" ]; then
    INFO "boot partition was already mounted"
else
    INFO "boot partition was not found"
    exit 2
fi

replace_kernel
[ "$?" -eq 0 ] && INFO "replace kernel successfully" || INFO "replace kernel failed"
