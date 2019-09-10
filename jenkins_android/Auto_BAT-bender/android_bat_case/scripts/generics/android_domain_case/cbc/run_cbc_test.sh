#!/bin/bash
###############################################################################
# @Author   Wenjiex.Yu(wenjiex.yu@intel.com)
# @desc     Automatic test of the cbc unit test
# @history  2018-07-11: First version
###############################################################################
cbc_link="http://otcpkt.bj.intel.com/downloads/domain_unit_test/android/cbc"
local_path=`pwd`
test_path=$local_path/cbc_test_dir
if [ -d $test_path ]; then
    rm -fr $test_path
fi
mkdir $test_path

function print_help {
        echo "Usage: run_cbc_test.sh [options]"
        echo "Available options:"
        echo "  -h              display this help message"
        echo "  -d <DEVID>      device ID."
        echo "Useful patterns for test filtering are described in the API documentation."
}

function download_dstfile(){
    cd $test_path
    local dstfile=$1
    echo -e "Download $dstfile ...\n"
    if [ ! -f "$dstfile" ]; then
        wget $cbc_link/$dstfile
    else
        rm -rf $dstfile
        wget $cbc_link/$dstfile
    fi
}

function get_test_version(){
    local case_id=$1
    local date_latest=$(cat cbc_version.txt | grep ${case_id}_version | awk -F ':' '{print $2}' | sed 's/\"//g' | sed 's/ //g')
    echo -e "The latest $case_id version is : $date_latest\n"
    echo ${case_id}-${date_latest}.zip > $test_path/tmp.txt
}

function run_cbc_test(){
    local case_id=$1
    local cbc_results=$local_path/cbc_results
    local attach=cbc_attach
    local script=Test_script.bash
    echo "================================================= CBC Test ======================================================"
    echo "Downloading cbc test package..."
    download_dstfile cbc_version.txt
    get_test_version $case_id
    test_package=$(cat $test_path/tmp.txt)
    rm -rf $test_path/tmp.txt
    download_dstfile $test_package
    if [ ! -f $attach ] && [ ! -f $script ] ; then
        unzip $test_package -d $test_path
    else
        rm -rf $attach
        rm -rf $script
        unzip $test_package -d $test_path
    fi

    if [ -d $cbc_result ]; then
        rm -fr $cbc_results
    fi
    mkdir $cbc_results
    # Verify if we got a DEVID
    if [ -z "$DEVID" ]; then
        echo "Please provide a Device DEVID (-d DEVID)"
    else
        if ! (adb devices | grep -q "$DEVID"); then
            echo "$DEVID is not listed by adb devices..."
            echo "DEVICE NOT FOUND..."
        fi
    fi
    adb -s $DEVID root

    if  [[ `adb -s $DEVID shell getprop|grep 'init.svc.cbc_attach'|grep 'running'` ]]; then
	echo "CBC service is running"
    else
	adb -s $DEVID push $attach /data
    fi
    adb -s $DEVID push $script /data
    echo -e "Start run cbc Test ...\n"
    adb -s $DEVID wait-for-device
    if [[ `adb -s $DEVID shell ls /data|grep $attach` ]]; then
	adb -s $DEVID shell /data/$attach /dev/ttyS1* &
    fi
    sleep 10
    echo "Check the cbc devices in /dev folder..."
    adb -s $DEVID shell ls /dev/cbc*
    adb -s $DEVID shell ls /dev/cbc* > $cbc_results/Android_cbc_device_note_result.log
    echo "Saved the result to $cbc_results/Android_cbc_device_note_result.log"
    echo "Read data from device note: /dev/cbc-lifecycle..."
    adb -s $DEVID shell dd if=/dev/cbc-lifecycle bs=16 count=1 | hexdump -C > $cbc_results/Android_dd_cbc-lifecycle.log
    echo "Saved the result to $cbc_results/Android_dd_cbc-lifecycle.log"
    echo "Read data from device note: /dev/cbc-debug-in..."
    adb -s $DEVID shell dd if=/dev/cbc-debug-in bs=16 count=1 | hexdump -C > $cbc_results/Android_dd_cbc-debug-in.log
    echo "Saved the result to $cbc_results/Android_dd_cbc-debug-in.log"
    if [ -s $cbc_results/Android_cbc_device_note_result.log ] && [ -s $cbc_results/Android_dd_cbc-lifecycle.log ] && [ -s $cbc_results/Android_dd_cbc-debug-in.log ]
    then
        echo -e "====================== CBC domain unit test result: PASS ======================"
        echo -e "Please check the results on $cbc_results"
    else
        echo -e "====================== CBC domain unit test result: FAIL ======================"
        echo -e "Please check the results on $cbc_results"
    fi
}

if [ $# -lt 1 ]; then
    echo "error.. need args"
    print_help
    exit 1
fi

while getopts ":hd:" opt; do
    case $opt in
        h) print_help; exit ;;
        d) DEVID="$OPTARG"
           echo "DEVID=$DEVID"
           ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
        \?)
            echo "Unknown option: -$OPTARG"
            print_help
            exit 1
            ;;
    esac
done

shift $(($OPTIND-1))

run_cbc_test CBCDriverTest && exit 0 || exit 1
