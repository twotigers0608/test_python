#!/bin/bash

source "common.sh"

slide_key(){
adb -s $DEVID shell input swipe 100 100 1000 1000 100
}

select_video_19(){
adb -s $DEVID shell input tap 200 500
}

select_video_9(){
adb -s $DEVID shell input tap 400 600
}

tab_key(){
adb -s $DEVID shell input keyevent 61
}

ok_key(){
adb -s $DEVID shell input keyevent 23
}

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


##########  take one video  ##########
  first_check_19(){
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
      slide_key
      sleep 1
      select_video_19
 
  fi
  }

 first_check_9(){
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
      slide_key
      sleep 3
      select_video_9
 
  fi
  }

  ##########  find one video and check (27-TakeVideo) ##########
  take_mp4(){
    local pic_num_old=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera|wc -l`
    print_info "Found `expr $pic_num_old - 1` video"
    print_info "Taking video"
    local version=`adb -s $DEVID shell uname -a|awk '{print $3}'|cut -d . -f 1,2`
    if [[ $version != '4.9' ]]; then
      sleep 2
      adb -s $DEVID shell input tap 1700 500
      sleep 60
      print_info "1700 500"
      adb -s $DEVID shell input tap 1700 500
    else
      sleep 2
      adb -s $DEVID shell input tap 1800 500
      sleep 60
      print_info "1800 500"
      adb -s $DEVID shell input tap 1800 500
    fi
  # Check picture information
    sleep 5
    print_info "Checking video"
    local pic_info_new=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera|wc -l`
    local pic_num=`expr $pic_info_new - $pic_num_old`
    if [[ $pic_num -gt 0 ]]; then
        print_info "successfully take $pic_num video"
        pic_info=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera| sed -n "$"p`
        print_info "latest video info: $pic_info"
        return 0
    else
        print_info "Failed to take video"
        return 1
    fi
  }

  #try
  take_mp4_try(){
    local pic_num_old=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera|wc -l`
    print_info "Found `expr $pic_num_old - 1` video"
    print_info "Taking video"

    slide_key
    sleep 3
    select_video_9
    sleep 2
    adb -s $DEVID shell input tap 1900 500
    sleep 60
    print_info "1900 500"
    adb -s $DEVID shell input tap 1900 500
    sleep 5
    print_info "Checking video"
  }

######### check file name #########
check_file(){
  file_name=`adb -s $DEVID shell ls /storage/emulated/`
  for file in $file_name;
  do
    adb -s $DEVID shell cd /storage/emulated/$file//DCIM/Camera/
    if [ $? = 0 ] ; then
      adb -s $DEVID shell rm -rf /storage/emulated/$file//DCIM/Camera/*.jpg
      mp4_name_old=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
      now_time=`date '+%Y%m%d_%H%M%S'`
      date_name="VID_${now_time}.mp4"
      rename=`adb -s $DEVID shell mv /storage/emulated/$file/DCIM/Camera/$pic_name_old /storage/emulated/$file/DCIM/Camera/$date_name`
      mp4_name=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
      mp4_path="/storage/emulated/$file/DCIM/Camera/`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`"
      echo "get the video"
      break
    fi
  done

}

##########  Main Test ##########
camera_take_video_test(){
  reboot_device
  local version=`adb -s $DEVID shell uname -a|awk '{print $3}'|cut -d . -f 1,2`
  if [[ $version != '4.9' ]]; then
    log_in
    print_info "Start camera activity"
    adb -s $DEVID shell am start -a android.media.action.STILL_IMAGE_CAMERA
    sleep 2
    local camera_path=$(dirname "${BASH_SOURCE[0]}")
    print_info "4.19 Test"
    first_check_19
  else
    print_info "Start camera activity"
    adb -s $DEVID shell am start -a android.media.action.STILL_IMAGE_CAMERA
    sleep 2
    local camera_path=$(dirname "${BASH_SOURCE[0]}")
    print_info "4.9 Test"
    first_check_9
  fi
  
  # Start camera activity
  file_name=`adb -s $DEVID shell ls /storage/emulated/`
  for file in $file_name;
  do
    adb -s $DEVID shell cd /storage/emulated/$file//DCIM/Camera/
    if [ $? = 0 ] ; then
      adb -s $DEVID shell rm -rf /storage/emulated/$file//DCIM/Camera/*.jpg
      take_mp4
      sleep 20
      mp4_name=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
      mp4_path="/storage/emulated/$file/DCIM/Camera/`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`"
      if $mp4_path ; then
          echo "get the video"
        else
          echo "fail get video"
          slide_key
          sleep 3
          select_video_9
          take_mp4_try
          sleep 20
          mp4_name=`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`
          mp4_path="/storage/emulated/$file/DCIM/Camera/`adb -s $DEVID shell ls -l /storage/emulated/$file/DCIM/Camera/| sed -n "$"p|awk '{print $8}'`"
          adb -s $DEVID pull $mp4_path results/
        fi
        break
    fi
  done
  sleep 5
  adb -s $DEVID pull $mp4_path results/
   
  #check video
  rm -rf $camera_path/video_audio.zip $camera_path/image $camera_path/imageio $camera_path/imageio_ffmpeg/ $camera_path/moviepy/ $camera_path/numpy/ $camera_path/PIL/ $camera_path/proglog/ $camera_path/tqdm/ $camera_path/decorator.py $camera_path/cv2/
  wget -P $camera_path http://otcpkt.bj.intel.com/tools/BAT/video_audio.zip -t 100
  if [[ $?==0 ]]; then
      print_info "Successfully download python modules"
  else
      print_error "Failed to download python modules"
  fi
  sleep 3
  unzip $camera_path/video_audio.zip -d $camera_path/


  /usr/bin/python3.5 $camera_path/check_video.py results/$mp4_name >results/check_video_result.log
  /usr/bin/python3.5 $camera_path/check_audio.py results/$mp4_name >results/check_audio_result.log
  cat results/check_video_result.log results/check_audio_result.log

  if [[ $?==0 ]]; then
      if cat results/check_video_result.log | grep "video is normal" && cat results/check_audio_result.log | grep "voiced"; then
          print_info "The video shows normal status."
          return 0
      else
          print_err "The video shows abnormal status."
          return 1
      fi
  else
      print_err "Check video failed"
      return 1
  fi
}

# Please use getopts
while getopts  :t:vh arg
do case $arg in
  t)  TESTCASE="$OPTARG";;
  :)  die "$0: Must supply an argument to -$OPTARG.";;
  \?) die "Invalid Option -$OPTARG ";;
esac
done


adb_device_check $DEVID || die "Can not connect device $DEVICE" 2
root_device $DEVID || die "Cannot root device $DEVID" 2

case $TESTCASE in
  0) camera_take_video_test && exit 0 || exit 1;;
  *) echo "Invalid Option!!!"; exit 1;;
esac