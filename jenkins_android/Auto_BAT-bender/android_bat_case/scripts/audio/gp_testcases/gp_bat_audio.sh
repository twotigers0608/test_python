#!/usr/bin/env bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on gordonpeak for lts 4.9 and 4.14
# kernels
# You can download this project and add more basic test case to it.
#
# Testcases covered:
#	Speaker Playback
#	BT playback & capture
#	Dirana Mix Capture
#	Dirana Aux Capture
#	Dirana Tuner Capture
#	TestPin playback & capture
#
# Tested on Gordonpeak for both lts 4.9 and 4.14 kernel.
# Requirements :
#	Audio files : bt_playback.wav, speaker_playback.wav, testpin_playback.wav,
#		sspGpMrbBtHfp.blob
#	Dm_verity : vbmeta_disable_verity.img

################################################################################

# @Author   Raghuram Sathyamurthy(raghuram.sathyamurthy@intel.com)
# @desc     Android Gordonpeak Audio BAT script
# @history  22-3-2018: First version
############################# Functions ########################################

# Variables to be altered as per requirements
flashscript_location="/share/bin"
audiofiles_location="/share"



ADB="adb -s ${1}"
funcname=''

disable-dm-verity () {
	funcname=$FUNCNAME
	eval ${flashscript_location}/gp_flash_mode.sh
#	sleep 60s
#	lava-lxc-device-add
#	sleep 5s
	fastboot flashing unlock
	fastboot flash vbmeta_a ${audiofiles_location}/vbmeta_disable_verity.img
	fastboot flashing lock
	fastboot reboot
}

prepare-audio-tc () {
	funcname=$FUNCNAME
	sleep 15s
	${ADB} root
	sleep 30s
	${ADB} remount
	sleep 30s
	${ADB} push ${audiofiles_location}/speaker_playback.wav /sdcard > null
	${ADB} push ${audiofiles_location}/sspGpMrbBtHfp.blob \
		/vendor/firmware/ > null
	${ADB} push ${audiofiles_location}/sspGpMrbBtHfp.blob_16k \
		/vendor/firmware/ > null
	${ADB} push ${audiofiles_location}/bt_playback.wav /sdcard > null
	${ADB} push ${audiofiles_location}/bthfp_playback.wav /sdcard > null
	${ADB} push ${audiofiles_location}/bt_16k_capture.wav /sdcard > null
	${ADB} shell cp /vendor/firmware/sspGpMrbBtHfp.blob \
		/vendor/firmware/sspGpMrbModem.blob > null
	${ADB} push ${audiofiles_location}/testpin_playback.wav /sdcard > null
}

playback-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=19 On > null
	timeout 10s ${ADB} shell alsa_aplay -Dplughw:0,0 \
		/sdcard/speaker_playback.wav -d10 2> playback_results.txt
}

capture-shell () {
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,11 -c2 -fs32_LE -r48000 \
		/sdcard/capture.wav 2> capture_results.txt
}

bt-playback-shell () {
	timeout 10s ${ADB} shell alsa_aplay -Dhw:0,6 /sdcard/bthfp_playback.wav \
		-d60 2> bt_playback_results.txt
}

bt-capture-shell () {
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,5 -fs32_LE -r8000 -c1 \
		/sdcard/bt_capture.wav 2> bt_capture_results.txt
	${ADB} pull /sdcard/bt_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"bt_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> bt_capture_results.txt
	fi
}


modem-playback-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=37 On > null
	timeout 10s ${ADB} shell alsa_aplay -vv -Dhw:0,8 \
		/sdcard/modem_playback.wav -d60 2> modem_playback_results.txt
}

modem-capture-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=33 On > null
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,7 -fs32_LE -r8000 -c1 \
	/sdcard/modem_capture.wav 2> modem_capture_results.txt
	${ADB} pull /sdcard/modem_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"modem_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> modem_capture_results.txt
	fi
}

testpin-playback-shell () {
	timeout 10s ${ADB} shell alsa_aplay -Dhw:0,4 /sdcard/testpin_playback.wav \
		2> testpin_playback_results.txt
}

testpin-capture-shell () {
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,3 -fs16_LE -r48000 -c2 \
		/sdcard/testpin_capture.wav 2> testpin_capture_results.txt
	${ADB} pull /sdcard/testpin_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"testpin_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> testpin_capture_results.txt
	fi
}

bt-gain-playback-shell () {
	timeout 30s ${ADB} shell alsa_aplay -vv -Dhw:0,6 \
		/sdcard/bthfp_playback.wav 2> bt_gain_playback_results.txt
}

bt-gain-capture-shell () {
	timeout 30s ${ADB} shell alsa_arecord -vv -Dhw:0,5 -fs32_LE -r8000 -c1 \
		/sdcard/bt_gain_capture.wav 2> bt_gain_capture_results.txt
	${ADB} pull /sdcard/bt_gain_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"bt_gain_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> bt_gain_capture_results.txt
	fi
}

bt-gain-change-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=32 1000 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 100 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 10 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 5 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 500 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 50 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 70 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 7 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 700 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=32 70 > null
}

modem-gain-playback-shell () {
	timeout 30s ${ADB} shell alsa_aplay -vv -Dhw:0,8 \
		/sdcard/bthfp_playback.wav 2> modem_gain_playback_results.txt
}

modem-gain-capture-shell () {
	timeout 30s ${ADB} shell alsa_arecord -vv -Dhw:0,7 -fs32_LE -r8000 -c1 \
		/sdcard/modem_gain_capture.wav 2> modem_gain_capture_results.txt
	${ADB} pull /sdcard/modem_gain_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"modem_gain_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> modem_gain_capture_results.txt
	fi
}

modem-gain-change-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=36 1000 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 100 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 10 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 5 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 500 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 50 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 70 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 7 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 700 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=36 70 > null
}

dirana-gain-capture-shell () {
	timeout 30s ${ADB} shell alsa_arecord -Dhw:0,1 -fs32_LE -r48000 -c1 \
		/sdcard/dirana_gain_capture.wav 2> dirana_gain_capture_results.txt
	${ADB} pull /sdcard/dirana_gain_capture.wav > null
	sleep 10s
	file_size=$(wc -c <"dirana_gain_capture.wav")
	if [ $file_size == 0 ]
	then
	echo "Dummy Line" >> dirana_gain_capture_results.txt
	fi
}

dirana-gain-change-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=22 1000 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 100 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 10 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 5 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 500 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 50 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 70 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 7 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 700 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=22 70 > null
}

speaker-gain-playback-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=19 On > null
	timeout 30s ${ADB} shell alsa_aplay -Dhw:0,0 /sdcard/speaker_playback.wav \
		2> speaker_gain_playback_results.txt
}

speaker-gain-change-shell () {
	${ADB} shell alsa_amixer -c 0 cset numid=8 1000 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 100 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 10 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 5 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 500 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 50 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 70 > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 7 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 700 On > null
	sleep 3s
	${ADB} shell alsa_amixer -c 0 cset numid=8 70 > null
}

bt-16k-playback-shell () {
	timeout 10s ${ADB} shell alsa_aplay -Dhw:0,6 /sdcard/bt_playback_16.wav \
		2> bt_playback_16k_results.txt
}

bt-16k-capture-shell () {
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,5 -fs32_LE -r16000 -c1 \
		/sdcard/bt_capture_16.wav 2> bt_capture_16k_results.txt
}

tc-speaker-playback () {
	funcname=$FUNCNAME
	${ADB} shell alsa_amixer -c 0 cset numid=19 On > null
	sleep 1s
	timeout 10s ${ADB} shell alsa_aplay -Dhw:0,0 \
		/sdcard/speaker_playback.wav 2> speaker_playback_results.txt
	sleep 5s
	if ! grep -q "non available" speaker_playback_results.txt;
	then
		numlines=`wc -l < speaker_playback_results.txt`
		if [ $numlines == 1 ]
		then
			playback_line=$(head -n 1 speaker_playback_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			if [[ $playing_content == "Playing" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value

}

tc-bt-playback-capture () {
	funcname=$FUNCNAME
	bt-playback-shell & bt-capture-shell
	sleep 1s
	if ! grep -q "non available" bt_playback_results.txt && \
		! grep -q "non available" bt_capture_results.txt;
	then
		numlines_playback=`wc -l < bt_playback_results.txt`
		numlines_capture=`wc -l < bt_capture_results.txt`
		if [[ $numlines_playback == 1 && $numlines_capture == 1 ]]
		then
			playback_line=$(head -n 1 bt_playback_results.txt)
			capture_line=$(head -n 1 bt_capture_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" && \
				$capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-modem-playback-capture () {
	funcname=$FUNCNAME
	modem-playback-shell & modem-capture-shell
	sleep 1s
	if ! grep -q "non available" modem_playback_results.txt && \
		! grep -q "non available" modem_capture_results.txt;
	then
		numlines_playback=`wc -l < modem_playback_results.txt`
		numlines_capture=`wc -l < modem_capture_results.txt`
		if [[ $numlines_playback -gt 25 && $numlines_capture == 1 ]]
		then
			playback_line=$(head -n 1 modem_playback_results.txt)
			capture_line=$(head -n 1 modem_capture_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" \
				&& $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-dirana-mic-capture () {
	funcname=$FUNCNAME
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,1 -fs32_LE -r48000 -c1 \
		/sdcard/dirana_capture.wav 2> dirana_mic_capture_results.txt
	${ADB} pull /sdcard/dirana_capture.wav > null
	sleep 10s
	if ! grep -q "non available" dirana_mic_capture_results.txt;
	then
		file_size=$(wc -c <"dirana_capture.wav")
		if [ $file_size == 0 ]
		then
		echo "Dummy Line" >> dirana_mic_capture_results.txt
		fi
		numlines=`wc -l < dirana_mic_capture_results.txt`
		if [ $numlines == 1 ]
		then
		#echo PASS
		test_value=0
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-dirana-aux-capture () {
	funcname=$FUNCNAME
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,10 -fs32_LE -r48000 -c2 \
		/sdcard/dirana_aux_capture.wav 2> dirana_aux_capture_results.txt
	${ADB} pull /sdcard/dirana_aux_capture.wav > null
	sleep 10s
	if ! grep -q "non available" dirana_aux_capture_results.txt;
	then
		file_size=$(wc -c <"dirana_aux_capture.wav")
		if [ $file_size == 0 ]
		then
		echo "Dummy Line" >> dirana_aux_capture_results.txt
		fi
		numlines=`wc -l < dirana_mic_capture_results.txt`
		if [ $numlines == 1 ]
		then
		#echo PASS
		test_value=0
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-dirana-tuner-capture (){
	funcname=$FUNCNAME
	timeout 10s ${ADB} shell alsa_arecord -Dhw:0,11 -fs32_LE -r48000 -c2 \
		/sdcard/dirana_tuner_capture.wav 2> dirana_tuner_capture_results.txt
	${ADB} pull /sdcard/dirana_tuner_capture.wav > null
	sleep 10s
	if ! grep -q "non available" dirana_tuner_capture_results.txt;
	then
		file_size=$(wc -c <"dirana_tuner_capture.wav")
		if [ $file_size == 0 ]
		then
		echo "Dummy Line" >> dirana_tuner_capture_results.txt
		fi
		numlines=`wc -l < dirana_tuner_capture_results.txt`
		if [ $numlines == 1 ]
		then
		#echo PASS
		test_value=0
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-testpin-playback-capture () {
	funcname=$FUNCNAME
	testpin-playback-shell & testpin-capture-shell
	sleep 1s
	if ! grep -q "non available" testpin_playback_results.txt && \
		! grep -q "non available" testpin_capture_results.txt;
	then
		numlines_playback=`wc -l < testpin_playback_results.txt`
		numlines_capture=`wc -l < testpin_capture_results.txt`
		if [[ $numlines_playback == 1 && $numlines_capture == 1 ]]
		then
		#echo PASS
		test_value=0
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-simultaneous-playback-capture () {
	funcname=$FUNCNAME
	playback-shell & capture-shell
	sleep 1s
	if ! grep -q "non available" playback_results.txt && \
		! grep -q "non available" capture_results.txt;
	then
		numlines_playback=`wc -l < playback_results.txt`
		numlines_capture=`wc -l < capture_results.txt`
		if [[ $numlines_playback == 1 && $numlines_capture == 1 ]]
		then
			playback_line=$(head -n 1 playback_results.txt)
			capture_line=$(head -n 1 capture_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" \
				&& $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-bt-gain-validation () {
	funcname=$FUNCNAME
	bt-gain-playback-shell & bt-gain-capture-shell & bt-gain-change-shell
	sleep 1s
	if ! grep -q "non available" bt_gain_playback_results.txt && \
		! grep -q "non available" bt_gain_capture_results.txt;
	then
		numlines_playback=`wc -l < bt_gain_playback_results.txt`
		numlines_capture=`wc -l < bt_gain_capture_results.txt`
		if [[ $numlines_playback -gt 25 && $numlines_capture -gt 25 ]]
		then
			playback_line=$(head -n 1 bt_gain_playback_results.txt)
			capture_line=$(head -n 1 bt_gain_capture_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" \
				&& $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-modem-gain-validation () {
	funcname=$FUNCNAME
	${ADB} shell alsa_amixer -c 0 cset numid=37 On > null
	${ADB} shell alsa_amixer -c 0 cset numid=33 On > null
	${ADB} shell alsa_amixer -c 0 cset numid=36 On> null
	modem-gain-playback-shell & modem-gain-capture-shell \
		& modem-gain-change-shell
	sleep 1s
	if ! grep -q "non available" modem_gain_playback_results.txt && \
		! grep -q "non available" modem_gain_capture_results.txt;
	then
		numlines_playback=`wc -l < modem_gain_playback_results.txt`
		numlines_capture=`wc -l < modem_gain_capture_results.txt`
		if [[ $numlines_playback -gt 25 && $numlines_capture -gt 25 ]]
		then
			playback_line=$(head -n 1 modem_gain_playback_results.txt)
			capture_line=$(head -n 1 modem_gain_capture_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" \
				&& $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-dirana-gain-validation () {
	funcname=$FUNCNAME
	dirana-gain-capture-shell & dirana-gain-change-shell
	sleep 1s
	if ! grep -q "non available" dirana_gain_capture_results.txt;
	then
		numlines_capture=`wc -l < dirana_gain_capture_results.txt`
		if [[ $numlines_capture == 1 ]]
		then
			capture_line=$(head -n 1 dirana_gain_capture_results.txt)
			IFS=' '
			read -ra capture_content <<< $capture_line
			if [[ $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}


tc-speaker-gain-validation () {
	funcname=$FUNCNAME
	speaker-gain-playback-shell & speaker-gain-change-shell
	sleep 1s
	if ! grep -q "non available" speaker_gain_playback_results.txt;
	then
		numlines_capture=`wc -l < speaker_gain_playback_results.txt`
		if [[ $numlines_capture == 1 ]]
		then
			capture_line=$(head -n 1 speaker_gain_playback_results.txt)
			IFS=' '
			read -ra capture_content <<< $capture_line
			if [[ $capture_content == "Playing" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

tc-bt-16k-validation () {
	${ADB} shell alsa_amixer -c 0 cset numid=3 1 > null
	${ADB} shell alsa_amixer -c 0 cset numid=4 1 > null
	${ADB} shell cp /vendor/firmware/sspGpMrbBtHfp.blob_16k \
		/vendor/firmware/sspGpMrbModem.blob > null
	funcname=$FUNCNAME
	bt-16k-playback-shell & bt-16k-capture-shell
	sleep 1s
	if ! grep -q "non available" bt_playback_16k_results.txt && \
	! grep -q "non available" bt_capture_16k_results.txt;
	then
		numlines_playback=`wc -l < bt_playback_16k_results.txt`
		numlines_capture=`wc -l < bt_capture_16k_results.txt`
		if [[ $numlines_playback == 1 && $numlines_capture == 1 ]]
		then
			playback_line=$(head -n 1 bt_playback_16k_results.txt)
			capture_line=$(head -n 1 bt_capture_16k_results.txt)
			IFS=' '
			read -ra playing_content <<< $playback_line
			read -ra capture_content <<< $capture_line
			if [[ $playing_content == "Playing" \
				&& $capture_content == "Recording" ]]
			then
			#echo PASS
			test_value=0
			else
			#echo FAILED!
			test_value=1
			fi
		else
		#echo FAILED!
		test_value=1
		fi
	else
		test_value=1
	fi
	return $test_value
}

parse-out () {
	ret=$1
	if [ $ret == 0 ]
	then
        #echo PASS
        test_value='pass'
	else
        #echo FAILED!
        test_value='fail'
	fi
	if [ $ret == 3 ]
	then
	test_value='skip'
	fi
lava-test-case $funcname --result $test_value
#echo 'RESULTS: '$funcname --result $test_value
}

echo ".........Disable Dm Verity"
disable-dm-verity

#sleep 60s
#lava-lxc-device-add
#sleep 60s

echo ".........Preparing Audio Test Cases"
prepare-audio-tc

sleep 30s

echo ".........Speaker Playback"
tc-speaker-playback
ret=$?
parse-out $ret

echo ".........Bluetooh Playback and Capture"
tc-bt-playback-capture
ret=$?
parse-out $ret

echo ".........Modem Playback and Capture"
tc-modem-playback-capture
ret=$?
parse-out $ret

echo ".........Dirana Mic Playback and Capture"
tc-dirana-mic-capture
ret=$?
parse-out $ret

echo ".........Dirana Aux Playback and Capture"
tc-dirana-aux-capture
ret=$?
parse-out $ret

echo ".........Dirana Tuner Playback and Capture"
tc-dirana-tuner-capture
ret=$?
parse-out $ret

echo ".........Testpin Playback and Capture"
tc-testpin-playback-capture
ret=$?
parse-out $ret

echo ".........Simultaneous Playback and Capture"
tc-simultaneous-playback-capture
ret=$?
parse-out $ret

echo ".........Bluetooth Gain Validation"
tc-bt-gain-validation
ret=$?
parse-out $ret

echo ".........Modem Gain Validation"
tc-modem-gain-validation
ret=$?
parse-out $ret

echo ".........Dirana Gain Validation"
tc-dirana-gain-validation
ret=$?
parse-out $ret

echo ".........Speaker Gain Validation"
tc-speaker-gain-validation
ret=$?
parse-out $ret

echo ".........Bluetooth 16k Validation"
tc-bt-16k-validation
ret=$?
parse-out $ret
