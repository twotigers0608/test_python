#/bin/bash

source "common.sh"
#####################################################
####################  Functions  ####################
#####################################################

##############  keyevent  ##############
  # TAB key
  tab_key(){
  #echo 'input tab key'
  adb -s $DEVID shell input keyevent 61
  }

  # OK key
  ok_key(){
  adb -s $DEVID shell input keyevent 23
  }

  # Down key(){
  down_key(){
  adb -s $DEVID shell input keyevent 20
  }

##########  Reboot Device  ##########
  reboot_device(){
  print_info "Start reboot"
  adb -s $DEVID reboot &
  sleep 40s
  print_info "Executing ADB reboot...Waiting adb reconnect..."
  sleep 30
  adb connect $DEVID > /dev/null 2>&1
  adb -s $DEVID root > /dev/null 2>&1
  if adb devices | grep $DEVID | grep "offline"; then
     print_err "The device $DEVID status is offline, can't check reboot status"
  fi
  }

##########  Log In  ##########

  log_in(){
  print_info "Log in as owner"
  # Log in as owner
  tab_key
  sleep 2
  tab_key
  sleep 2
  ok_key
  sleep 2
  }

##########  Check previous pictures  ##########
  first_check(){
  print_info "checking Camera Settings"
  local camera_info=`adb -s $DEVID shell ls -l /storage/emulated/0/DCIM/|wc -l`
  # Setup for first time(Will take two more picture if already setup)
  if [[ $camera_info -ge 1 ]]; then
      print_info "Setup camera"
      ok_key
      sleep 1
      ok_key
      sleep 1
      down_key
      sleep 1
      ok_key
      sleep 1
  fi
  }


##########  Take one picture and check (27-TakePicture) ##########
  take_pic(){
  local pic_num_old=`adb -s $DEVID shell ls -l /storage/emulated/0/DCIM/Camera|wc -l`
  print_info "Found `expr $pic_num_old - 1` pictures"
  print_info "Taking pictures"
  adb -s $DEVID shell input keyevent 27
  sleep 10

  # Check picture information
  print_info "Checking pictures"
  local pic_info_new=`adb -s $DEVID shell ls -l /storage/emulated/0/DCIM/Camera|wc -l`

  local pic_num=`expr $pic_info_new - $pic_num_old`
  if [[ $pic_num -gt 0 ]]; then
      print_info "successfully take $pic_num pictures"
      pic_info=`adb -s $DEVID shell ls -l /storage/emulated/0/DCIM/Camera| sed -n "$"p`
      print_info "latest picture info: $pic_info"
      return 0
  else
      print_info "Failed to take pictures"
      return 1
  fi
  }

##########  Main Test ##########
  camera_take_picture_test(){
  reboot_device
  local version=`adb -s $DEVID shell uname -a|awk '{print $3}'|cut -d . -f 1,2`
  if [[ $version != '4.9' ]]; then
       log_in
  fi
  # Start camera activity
  print_info "Start camera activity"
  adb -s $DEVID shell am start -a android.media.action.STILL_IMAGE_CAMERA
  sleep 2
  local camera_path=$(dirname "${BASH_SOURCE[0]}")

  first_check
  take_pic

  file_name=`adb -s $DEVID shell ls /storage/emulated/`
  for file in $file_name;
  do
    adb -s $DEVID shell cd /storage/emulated/$file//DCIM/Camera/
    if [ $? = 0 ] ; then

      pic_name_old=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
      now_time=`date '+%Y%m%d_%H%M%S'`
      date_name="IMG_${now_time}.jpg"
      rename=`adb -s $DEVID shell mv /storage/emulated/$file/DCIM/Camera/$pic_name_old /storage/emulated/$file/DCIM/Camera/$date_name`
      pic_name=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
      pic_path="/storage/emulated/$file/DCIM/Camera/`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`"
      echo "get the picture"
      break
    fi
  done
  adb -s $DEVID pull $pic_path results/
  rm -rf $camera_path/camera.zip $camera_path/PIL $camera_path/numpy $camera_path/python
  wget -P $camera_path http://otcpkt.bj.intel.com/tools/BAT/camera.zip -t 100
  if [[ $?==0 ]]; then
      print_info "Successfully download python modules"
  else
      print_error "Failed to download python modules"
  fi
  sleep 3
  unzip $camera_path/camera.zip -d $camera_path/
  echo $pic_name
  /usr/bin/python3 $camera_path/check_pic.py results/$pic_name >results/check_picture_result.log
  cat results/check_picture_result.log
  if [[ $?==0 ]]; then
      if cat results/check_picture_result.log | grep "Picture color is normal"; then
          print_info "The picture shows normal status."
          return 0
      else
          print_err "The picture shows abnormal status."
          return 1
      fi
  else
      print_err "Check picture failed"
      return 1
  fi
  }


#####################################################
##################  Run Wifi Test  ##################
#####################################################

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

case $TESTCASE in
  0) camera_take_picture_test && exit 0 || exit 1;;
  *) echo "Invalid Option!!!"; exit 1;;
esac
