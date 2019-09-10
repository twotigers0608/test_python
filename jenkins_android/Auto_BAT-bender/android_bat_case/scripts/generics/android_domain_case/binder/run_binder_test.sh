#!/bin/bash
###############################################################################
# @Author   Zhanghui.Yuan(zhanghuix.yuan@intel.com)
# @desc     Automatic test of the binder unit test
# @history  2018-06-21: First version
###############################################################################
devid=$1
binder_link="http://otcpkt.bj.intel.com/downloads/domain_unit_test/android/binder"

function adb_device_check(){
    if adb devices | grep $devid | grep "device"; then
        return 0
    else
        echo "Can not found device $devid"
        return 1
    fi
}

function download_dstfile(){
    local dstfile=$1
    echo -e "Download $dstfile ...\n"
    if [ ! -f "$dstfile" ]; then
        wget $binder_link/$dstfile
    else
        rm -rf $dstfile
        wget $binder_link/$dstfile
    fi
}

function get_test_version(){
    local case_id=$1
    local date_latest=$(cat binder_version.txt | grep ${case_id}_version | awk -F ':' '{print $2}' | sed 's/\"//g' | sed 's/ //g')
    echo -e "The latest $case_id version is : $date_latest\n"
    echo ${case_id}-${date_latest}.zip > tmp.txt
}

function check_test_result(){
    local case_id=$1
    if [[ $case_id == "binderThroughputTest" ]]; then
        iterations=$(cat $case_id.log | grep "iterations per sec" | cut -d ":" -f 2)
        product_name=$(adb -s $devid shell getprop | grep "ro.product.board" | cut -d ":" -f 2 |  sed 's/\[//g' | sed 's/\]//g')
        if [ $(echo "$iterations < 40000"|bc) -eq 1 ] && [ $product_name == "gordon_peak" ]; then
            echo "============= Result: $case_id test failed! ============="
            echo "The iterations per sec value is : $iterations"
        else
            echo "============= Result: $case_id test passed! ============="
            echo "The iterations per sec value is : $iterations"
        fi
    else
        test_number=$(cat $case_id.log | grep Running | awk -F ' ' '{print $3}')
        echo "Total test case number is $test_number"
        pass_number=$(cat $case_id.log | grep PASSED | awk -F ' ' '{print $4}')
        echo "Total passed test case number is $pass_number"
        if [[ $test_number==$pass_number ]]; then
            echo "============= Result: $case_id test passed! ============="
            return 0
        else
            echo "============= Result: $case_id test failed! ============="
            return 1
         fi
    fi
}

function run_binder_test(){
    local case_id=$1
    adb_device_check
    download_dstfile binder_version.txt
    get_test_version $case_id
    test_package=$(cat tmp.txt)
    rm -rf tmp.txt
    download_dstfile $test_package
    if [ ! -f $case_id ]; then
        unzip $test_package
    else
        rm -rf $case_id
        unzip $test_package
    fi
    echo -e "Push $case_id file to /data folder in device\n"
    adb -s $devid push $case_id /data
    echo -e "Start run $case_id Test ...\n"
    adb -s $devid root
    adb -s $devid wait-for-device
    adb shell /data/$case_id >$case_id.log
    check_test_result $case_id
}

# ============= Rinder Driver Test =============
run_binder_test binderDriverInterfaceTest
run_binder_test binderThroughputTest
