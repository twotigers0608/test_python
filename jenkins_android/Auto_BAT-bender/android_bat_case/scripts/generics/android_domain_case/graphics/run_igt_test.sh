#!/bin/bash
###############################################################################

# @Author   Wenjiex.Yu(wenjiex.yu@intel.com)
# @desc     Automatic test of the graphic unit test cases and generate
#           the csv and html format test report in results folder
# @history  2017-12-27: First version

###############################################################################
ROOT="`pwd`"
RESULTS="$ROOT/results"
SCRIPTS="$ROOT/scripts"
SCENARIO="$ROOT/scenarios"
LIBS="$ROOT/libs"
IGT_DEVICE_PATH="/data/app"
LIB_DEVICE_SYSTEM_PATH="/system/lib64"
LIB_DEVICE_VENDOR_PATH="/vendor/lib64"
datetime=`date +"%Y-%m-%d-%H-%M-%S"`
echo "ROOT=$ROOT"

function print_help {
        echo "Usage: run_igt_tests.sh [options]"
        echo "Available options:"
        echo "  -h              display this help message"
        echo "  -d <DEVID>      device ID"
        echo "  -t <CASE>       run single test case or tests listed in testlist"
        echo "Useful patterns for test filtering are described in the API documentation."
}

function download_source(){
  #check the directorys
  if [ -d $SCENARIO ] ; then
      rm $SCENARIO -fr
  fi
  if [ -d $LIBS ] ; then
      rm $LIBS -fr
  fi
  mkdir $SCENARIO
  mkdir $LIBS
  #check the latest version of igt
  wget http://otcpkt.bj.intel.com/downloads/domain_unit_test/android/graphics/igt_version.txt
  local date_latest=$(cat igt_version.txt | awk -F ':' '{print $2}' | sed 's/\"//g' | sed 's/ //g')
  rm igt_version.txt
  #download and unzip the packages
  cd $LIBS
  wget http://otcpkt.bj.intel.com/downloads/domain_unit_test/android/graphics/lib-$date_latest.zip
  if [ $? == "0" ] ; then
      unzip lib-$date_latest.zip
      mv lib/* ./
      rm lib/ -fr
      rm lib-$date_latest.zip -fr
  else
      echo "Download lib package failed! Skip the test ..."
      exit 1
  fi
  cd $SCENARIO
  wget http://otcpkt.bj.intel.com/downloads/domain_unit_test/android/graphics/igt-$date_latest.zip
  if [ $? == "0" ] ; then
      unzip igt-$date_latest.zip
      rm igt-$date_latest.zip -fr
  else
      echo "Download igt package failed! Skip the test ..."
      exit 1
  fi
  cd $ROOT
}

function push_files(){
  #push the igt files to device
  adb -s $DEVID push $SCENARIO/* $IGT_DEVICE_PATH >/dev/null
  if [ "$?" == "0" ] ; then
      echo "Push igt files succeeded!"
      adb -s $DEVID shell chmod 755 $IGT_DEVICE_PATH/igt
  else
      echo "Push igt files failed, please check the files!"
      exit 1
  fi
  #push the test script to device
  adb -s $DEVID push $SCRIPTS/run_test_android.sh $IGT_DEVICE_PATH/igt  >/dev/null
  if [ "$?" == "0" ] ; then
      echo "Push test script of run_test_android.sh succeeded!"
      adb -s $DEVID shell chmod 755 $IGT_DEVICE_PATH/igt/run_test_android.sh
  else
      echo "Push test script failed, please check the files!"
      exit 1
  fi
  #push the lib files to device
  adb -s $DEVID push $LIBS/* $LIB_DEVICE_SYSTEM_PATH
  if [ "$?" == "0" ] ; then
      echo "Push lib files succeeded!"
  else
      echo "Push lib files failed, please check the files!"
      exit 1
  fi
  adb -s $DEVID push $LIBS/libkmod.so $LIB_DEVICE_VENDOR_PATH
  if [ "$?" == "0" ] ; then
      echo "Push lib file libkmod.so succeeded!"
  else
      echo "Push lib file libkmod.so failed, please check the files!"
      exit 1
  fi
  adb -s $DEVID push $LIBS/libpciaccess.so $LIB_DEVICE_VENDOR_PATH
  if [ "$?" == "0" ] ; then
      echo "Push lib file libpciaccess.so succeeded!"
  else
      echo "Push lib file libpciaccess.so failed, please check the files!"
      exit 1
  fi

}

function generate_test_report(){
  BUILD=$(adb -s $DEVID shell getprop | grep "ro.build.description" | awk -F ':' '{print $2}' | sed 's/\[//g' | sed 's/\]//g')
  ANDROID_VER=$(adb -s $DEVID shell getprop | grep "ro.build.version.release" | awk -F ':' '{print $2}' | sed 's/\[//g' | sed 's/\]//g')
  KERNEL_VER=$(adb -s $DEVID shell cat /proc/version)

  if [ ! -d "$RESULTS" ]; then
      echo "There is no results directory in local path, exit..."
      exit 1
  else
      TEXT=$(ls $RESULTS/$datetime | grep txt)
      FILE_NAME=$(echo "$TEXT" | awk -F '.' '{print $1}')
      TEXT_FILE="$RESULTS/$datetime/$FILE_NAME.txt"
      CSV_FILE="$RESULTS/$datetime/$FILE_NAME.csv"
      HTML_FILE="$RESULTS/$datetime/$FILE_NAME.html"
      $SCRIPTS/gen_csv.sh $TEXT_FILE $CSV_FILE
      if [ -f "$CSV_FILE" ]; then
          $SCRIPTS/gen_html.sh $CSV_FILE "$BUILD" "$ANDROID_VER" "$CASE" "$KERNEL_VER" $HTML_FILE
          echo "Generate HTML test report in $RESULTS/$datetime successfully!"
      else
          echo "Generate HTML test report failed!"
          exit 1
      fi
  fi
}

function run_test() {
  if [ ! -d $RESULTS ] ; then
      mkdir $RESULTS
  fi
  mkdir -p $RESULTS/$datetime
  echo "#####################Graphic Unit Automatic Test#####################"
  echo "Start! Make adb as root"
  adb -s $DEVID root
  echo "Step 1: adb remount..."
  local remt=$(adb -s $DEVID remount | grep "remount succeeded")
  if [ -n "$remt" ] ; then
      echo "Remount device succeeded!"
  else
      echo "The device remount failed! Please check if your DUT need flash the disable_verity image primarily! Skip the test..."
      return 1
  fi
  adb -s $DEVID shell mount -o rw,remount /
  echo "Step 2: Download the latest igt and lib sources to local..."
  download_source
  echo "Step 3: Push the files to DUT..."
  push_files
  echo "Step 4: adb shell stop"
  adb -s $DEVID shell stop
  echo "Step 5: stop the hwcomposer-2-1 process..."
  adb -s $DEVID shell stop hwcomposer-2-1
  echo "Step 6: Execute the igt test process"
  check_case=$(adb -s $DEVID shell ls $IGT_DEVICE_PATH/igt | grep "$CASE")
  if [ -n "$check_case" ] ; then
      echo -e "\nStart to run the test of $CASE..."
      if [[ $CASE == *"testlist"* ]] ; then
          echo "Execute run_test_android.sh -T $CASE"
          adb -s $DEVID shell $IGT_DEVICE_PATH/igt/run_test_android.sh -T $CASE
          adb -s $DEVID pull $IGT_DEVICE_PATH/igt/results/ $RESULTS/$datetime
          mv $RESULTS/$datetime/results/* $RESULTS/$datetime/
          rm -fr $RESULTS/$datetime/results
      else
          echo "Execute the $CASE in $IGT_DEVICE_PATH/igt/"
          adb -s $DEVID shell $IGT_DEVICE_PATH/igt/$CASE > $RESULTS/$datetime/$CASE.log
          cat $RESULTS/$datetime/$CASE.log | grep Subtest* > $RESULTS/$datetime/$CASE.txt
      fi
  else
      echo "Can't find this case: $CASE, skip the test..."
      exit 1
  fi
  echo "Step 7:Generate the csv and html test report"
  generate_test_report
  echo "Test complete! Plese check the test report in $RESULTS/$datetime"
  echo "############################################################################"
}

if [ $# -lt 1 ]; then
    echo "error.. need args"
    print_help
    exit 1
fi
while getopts ":hd:t:" opt; do
    case $opt in
        h) print_help; exit ;;
        d) DEVID="$OPTARG" ;;
        t) CASE="$OPTARG" ;;
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

############################### MODULE LOGIC ###################################
# Verify if we got a DEVID
if [ -z "$DEVID" ]; then
    echo "Please provide a Device DEVID (-d DEVID)"
else
  if ! (adb devices | grep -q "$DEVID"); then
    echo "$DEVID is not listed by adb devices..."
    echo "DEVICE NOT FOUND..."
  fi
fi

# Verify if we got a scenario
if [ -z "$CASE" ]; then
    echo "Please provide a Scenario File (-t CASE)"
fi

run_test && exit 0 || exit 1

