#In this test, we will comapre output of ls -lZ /mnt/eavb/misc/run/smartx/ with predefined data : "audio_evb_data"
#!/bin/bash
funcname='audio_evb_test'
result-out () {
	ret=$1
	if [ $ret == 0 ]
	then
		test_value='pass'
		echo "pass"
	else
		test_value='fail'
		echo "fail"
	fi
	if [ $ret == 3 ]
	then
		test_value='skip'
		echo "skip"
	fi
	lava-test-case $funcname --result $test_value
	echo $funcname
}

#date/timestamp comparision is not required, so skipped from data block
read -d '' audio_evb_data <<"BLOCK"
total 0    
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_hmi_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_hmi_p
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_mc_1_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_mc_1_p
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_media_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_media_p
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_mic_pair1_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_mic_pair2_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_navigation_c
prw-rw---- 1 root audio u:object_r:audioserver_data_file:s0 avb_eavb_navigation_p
prw-rw---- 1 audioserver audio u:object_r:audioserver_data_file:s0 smartx_hmi_stream_p
prw-rw---- 1 audioserver audio u:object_r:audioserver_data_file:s0 smartx_media_stream_p
prw-rw---- 1 audioserver audio u:object_r:audioserver_data_file:s0 smartx_navigation_stream_p
prw-rw---- 1 audioserver audio u:object_r:audioserver_data_file:s0 smartx_record_mic_1_2_c
BLOCK
test_adb () {
	timeout 10s adb root
	if [ $lavafy == 'yes'  ]; then
		lxc-add-device $DEVID
	fi
	timeout 30s adb wait-for-device
	timeout 30s adb devices|grep -wc device
}
audio_evb_test () {
	test_adb
	ret=$?
	if [[ $ret -eq 1 ]] #no device found, bail out
	then
		echo "Device not found: failing"
		result-out $ret
		exit 1
	fi

	adb shell start avbstreamhandler
	sleep 10
	output=$(adb shell ls -lZ /mnt/eavb/misc/run/smartx/ | awk '{print $1, $2, $3, $4, $5, $9}')
	#echo "$audio_evb_data"
	#echo "$output"
	diff  <(echo "$audio_evb_data") <(echo "$output")
	#diff <(echo "$audio_evb_data") <(echo "$output") >> /dev/null
	ret=$?
	result-out $ret
}

echo "...testing audio evb test..."
audio_evb_test
