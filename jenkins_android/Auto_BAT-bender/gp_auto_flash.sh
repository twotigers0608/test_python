#!/bin/bash
################################### DESC #######################################
# @Desc    This script should be copied into image-dir then do execution
#          This script includes flashing ifwi file, opening usb fastboot mode
#          and flashing image files
# 
# @Authr   Yu Hai(yux.hai@intel.com)
# @History May 28th Yu finished firsh version
#
# @References
#
################################## PARAMS ######################################

IOC_SER="/dev/ttyUSB2"
PFT="/opt/intel/platformflashtool/bin/ias-spi-programmer"   #刷机工具的路径
IAS_SPI_PROGRAMMER="./ias-spi-programmer"
IFWI_FILE="ifwi_gr_mrb_b1.bin"

FLASH_TOOL=""
################################## FUNCS #######################################

cp_img_to_dir(){
    local img_file=$1
    local test_file_path=$2
    pushd ${test_file_path}
    unzip ${img_file}
}

usage(){
cat <<__EOF
    Usage:    sudo ${0##*/} -b [kernel_branch] -h
    Options:
       -b       Kernel branch, supported:
                     4.9-bkc-gordon_peak,
                     4.9-bkc-gordon_peak-baseline,
                     4.14-bkc-gordon_peak,
                     4.14-bkc-gordon_peak-baseline
                Note: Ignore this argument if kernel branch not in those items

       -h       Show this help
    Note: This script must be copied into image folder before execution. If
          flashing ifwi file failed at first time, try to solve it by opening
          IOC serical (usually ttyUSB2).  
__EOF
}

die(){
    echo -e "** ERROR, $1 **"
    exit 1
}

info(){
    echo -e "== INFO: $1 =="
}

check_ttyUSB_status(){
    info "check USB serial"
    if [ ! -x "${IOC_SER}" ] || [ ! -w "${IOC_SER}" ]; then
        sudo chmod 777 ${IOC_SER}
    fi

    info "${IOC_SER}, Permission allowed"
}

check_flash_tool(){
    info "check flash tool"
    if [ -f "$PFT" ]; then
        FLASH_TOOL=$PFT
    elif [ -f "${IAS_SPI_PROGRAMMER}" ]; then
        FLASH_TOOL=${IAS_SPI_PROGRAMMER}
    else
        die "flash tool not found"
    fi
    info "flash tool $FLASH_TOOL"
}

# Note: Open IOC(ttyUSB2) with minicom first time if flash ifwi failed
flash_ifwi_gp(){
    local count=$1
    local ifwi=$2
    local flash=''

    if [ $count -eq 5 ]; then
        die "Flash ifwi Failed"
    fi

    [ -n "$ifwi" ] && [ -f "$ifwi" ]|| die "ifwi file not found"

    info "Start flash ifwi file"
 
    echo "r" > ${IOC_SER}
    sleep 3s
    echo "n3#" > ${IOC_SER}
    sleep 3s
    info "Gorder peak device is now in ifwi state"
    $FLASH_TOOL --write $2

    [ $? -eq 0 ] && info "Flash ifwi is Done" || (let count++ && flash_ifwi_gp $count $ifwi)
}

open_gp_fastboot_mode(){
    local count=$1
    info "Open USB fastboot mode"

    if [ $count -eq 5 ]; then
        die "Open USBfastboot mode Failed"
    fi
    echo 'r' > ${IOC_SER}
    sleep 3s
    echo 'n4#' > ${IOC_SER}
    sleep 20s
    # min@min-dev:~$ fastboot devices
    # R1J56L90fa462e  fastboot
    local fastboot_device=`fastboot devices`
    if [[ ! $fastboot_device ]]; then
        let count++
        open_gp_fastboot_mode $count
    else
        info "Start to flash"
    fi
}

flash_gp(){
    local flash_option=$1
    [ -n "${flash_option}" ] || info "flash_option not given, use default option"

    cflasher -f flash.json -c blank_gr_mrb_b1 -l 5
    
    [ $? -eq 0 ] && info "Flashing GP Finished" || die "Flashing GP Failed"
}

################################### MAIN ######################################
while getopts b:hd:t: arg; do
    case $arg in
        b) BRANCH=$OPTARG;;
#	d) IMG_FILE_PATH=$OPTARG;;
	t) TEST_DIR_PATH=$OPTARG;;
        h) usage
           exit 0;;
        \?) usage
            die "Invalid option -$OPTARG";;
    esac
done

# cp_img_to_dir $IMG_FILE_PATH $TEST_DIR_PATH
pushd $TEST_DIR_PATH
check_ttyUSB_status
check_flash_tool
flash_ifwi_gp 1 ${IFWI_FILE} || exit 1
open_gp_fastboot_mode 1 || exit 1
flash_gp $BRANCH
popd
