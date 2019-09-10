Android Gordonpeak Audio BAT Testcases :

Testcases covered:
	Speaker Playback
	BT playback & capture
	Modem playback & capture
	Dirana Mix Capture
	Dirana Aux Capture
	Dirana Tuner Capture
	TestPin playback & capture
	Simultaneous playback & capture
	BT gain validation
	Modem gain validation
	Dirana gain validation
	Speaker gain validation
	BT_16k validation

Tested on Gordonpeak for both lts 4.9 and 4.14 kernel.

Requirements :
	Audio files : bt_playback.wav, speaker_playback.wav,
			testpin_playback.wav, sspGpMrbBtHfp.blob, sspGpMrbBtHfp.blob_16k,
		bthfp_playback.wav, testpin_playback.wav
	Dm_verity : vbmeta_disable_verity.img

How to run :

	gp_bat_audio.sh was written based on bat.sh which was used
	for lava bat test.

	Edit the flashscript and audio test files location in
		gp_bat_audio.sh.

	Usage :

	./gp_bat_audio.sh [adb_device_id]

Test Case Execution :
=====================

1. Speaker Playback

	a. adb root && adb remount
	b. Push the required play back file in /sdcard
		adb push speaker_playback.wav /sdcard
	c. adb shell
	d. Do mixer settings (numid can get from "alsa_amixer -c 0 controls" as mentioned in general procedure)
		alsa_amixer -c 0 cset numid=19 On 	(i.e. codec0_out mo media_in mi Switch)
	e. Play the wav file speaker_playback.wav
		alsa_aplay -vv -Dhw:0,0 /sdcard/speaker_playback.wav -d60

2. BT playback & capture

	Push appropiate blob:
	=====================
	a. adb root && adb remount
	b. Push the blob file
		adb push sspGpMrbBtHfp.blob /vendor/firmware/sspGpMrbBtHfp.blob
	c. Restart the board

	Playback:
	=========
	a. adb root && adb remount
	b. Push the required playback file in /sdcard
		adb push bthfp_playback.wav /sdcard
	c. adb shell
	d. Play the wav file bthfp_playback.wav
		alsa_aplay -vv -Dhw:0,6 /sdcard/bthfp_playback.wav -d60

	Capture:
	========
	a. adb root && adb remount
	b. Open adb shell in two terminals
	c. In first terminal do playback
		alsa_aplay -vv -Dhw:0,6 /sdcard/bthfp_playback.wav -d60
	d. In second terminal do capture
		alsa_arecord -vv -Dhw:0,5 -fs32_LE -r8000 -c1 /sdcard/bt_capture.wav

3. Modem playback & capture

	Push appropiate blob:
	=====================
	a. adb root && adb remount
	b. Push the blob file
		adb push sspGpMrbModem.blob /vendor/firmware/sspGpMrbModem.blob
	b. Restart the board

	Playback:
	========
	a. adb root && adb remount
	b. Push the required playback file in /sdcard
		adb push modem_playback.wav /sdcard
	c. Do mixer settings for Modem playback
		alsa_amixer -c 0 cset numid=37 On	(i.e. modem_pt_pb mo media3_in mi Switch)
	d. Play the wav file modem_playback.wav
		alsa_aplay -vv -Dhw:0,8 /sdcard/modem_playback.wav -d60

	Capture:
	========
	a. adb root && adb remount
	b. Open adb shell in two terminals
	c. Do mixer setting for Modem playback & capture
		alsa_amixer -c 0 cset numid=37 On (i.e. modem_pt_pb mo media3_in mi Switch)
		alsa_amixer -c 0 cset numid=33 On (i.e. media2_out mo modem_pt_cp mi Switch)
	c. In first terminal do playback
		alsa_aplay -vv -Dhw:0,8 /sdcard/modem_playback.wav -d60
	d. In second terminal do capture
		alsa_arecord -vv -Dhw:0,7 -fs32_LE -r8000 -c1 /sdcard/modem_capture.wav

4. Dirana Capture (Mic)

	Capture:
	========
	a. adb root && adb remount
	b. Do capture using below command
		alsa_arecord -vv -Dhw:0,1 -fs32_LE -r48000 -c1 /sdcard/dirana_capture.wav -d30

5. Dirana AUX Capture

	Capture:
	========
	a. adb root && adb remount
	b. Do capture using below command
		alsa_arecord -vv -Dhw:0,10 -fs32_LE -r48000 -c2 /sdcard/dirana_aux_capture.wav -d30

6. Dirana Tuner Capture

	Capture:
	========
	a. adb root && adb remount
	b. Do capture using below command
		alsa_arecord -vv -Dhw:0,11 -fs32_LE -r48000 -c2 /sdcard/dirana_tuner_capture.wav -d30

7. TestPin playback & capture

	Playback:
	========
	a. adb root && adb remount
	b. Push the required playback file in /sdcard
		adb push testpin_playback.wav /sdcard
	c. Play the wav file testpin_playback.wav
		alsa_aplay -vv -Dhw:0,4 /sdcard/testpin_playback.wav

	Capture:
	========
	a. adb root && adb remount
	b. Open adb shell in two terminals
	c. In first terminal do playback
		alsa_aplay -vv -Dhw:0,4 /sdcard/testpin_playback.wav
	d. In second terminal do capture
		alsa_arecord -vv -Dhw:0,3 -fs16_LE -r48000 -c2 /sdcard/testpin_capture.wav

8. Simultaneous PLayback & Capture

	Capture (Aux example but it could be tuner)
	a. In one terminal:
		alsa_arecord -vv -Dhw:0,11 -c2 -fS32_LE -r48000 /data/test.wav

	b. In another terminal playback to speaker
		alsa_amixer -c 0 cset numid=19 On  (i.e. codec0_out mo media_in mi Switch
		alsa_aplay -vv -Dplughw:0,0 /sdcard/speaker_playback.wav -d10

9. BT Gain Validation

	adb root && adb remount
	Open three terminals
	In first terminal (playback):
	=============================
		adb shell
		alsa_aplay -vv -Dhw:0,6 /sdcard/bthfp_playback.wav

	In second terminal (capture):
	=============================
		adb shell
		alsa_arecord -vv -Dhw:0,5 -fs32_LE -r8000 -c1 /sdcard/gain_test_bt.wav

	In third terminal (change values for "BtHfp_ssp0_in gain 2 Volume" continuously)
	================================================================================
		adb shell
		alsa_amixer -c 0 controls (To see mixer controls)
		alsa_amixer -c 0 cset numid=32 1000  (BtHfp_ssp0_in gain 2 Volume)
		alsa_amixer -c 0 cset numid=32 10
		Continuously give some random values minimum for 10 times

10. Modem Gain Validation

	Push appropiate blob:
	=====================
	a. adb root && adb remount
	b. Push the blob file
		adb push sspGpMrbModem.blob /vendor/firmware/sspGpMrbModem.blob
	b. Restart the board

	adb root && adb remount

	Open three terminals
	In first terminal (playback):
	=============================
	Open adb shell
		adb shell
	Required mixer settings
		alsa_amixer -c 0 cset numid=37 On  (modem_pt_pb mo media3_in mi Switch)
		alsa_amixer -c 0 cset numid=33 On  (media2_out mo modem_pt_cp mi Switch)
		alsa_amixer -c 0 cset numid=36 On  (modem_pt_cp gain 3 Volume)
	Do playback using below command
		alsa_aplay -vv -Dhw:0,8 /sdcard/bthfp_playback.wav

	In second terminal (capture):
	=============================
	Open adb shell
		adb shell
	Do capture using below command
		alsa_arecord -vv -Dhw:0,7 -fs32_LE -r8000 -c1 /sdcard/gain_test_modem.wav

	In third terminal (change values for "modem_pt_cp gain 3 Volume" continuously)
	==============================================================================
		adb shell
		alsa_amixer -c 0 controls (To see mixer controls)
		alsa_amixer -c 0 cset numid=36 1000 (modem_pt_cp gain 3 Volume)
		alsa_amixer -c 0 cset numid=36 10
		Continuously give some random values minimum for 10 times

11. Dirana Gain Validation

	adb root && adb remount
	Open two terminals
	In first terminal (capture):
	============================
		adb shell
		alsa_arecord -Dhw:0,1 -fs32_LE -r48000 -c1 /sdcard/gain_test_dirana_capture.wav

	In second terminal (change values for "dirana_in gain 1 Volume" continuously):
	==============================================================================
		adb shell
		alsa_amixer -c 0 controls (To see mixer controls)
		alsa_amixer -c 0 cset numid=22 1000(dirana_in gain 1 Volume)
		alsa_amixer -c 0 cset numid=22 10
		Continuously give some random values minimum for 10 times

12. Speaker Gain Validation

	adb root && adb remount
	Push the required play back file in /sdcard (if file is not available)
		adb push speaker_playback.wav /sdcard

	Open two terminals
	In first terminal (playback):
	============================
		adb shell
		alsa_amixer -c 0 cset numid=19 On  (codec0_out mo media_in mi Switch
		alsa_aplay -Dhw:0,0 /sdcard/speaker_playback.wav -d60

	In second terminal (change values for "media_in gain 0 Volume" continuously):
	==============================================================================
		adb shell
		alsa_amixer -c 0 controls (To see mixer controls)
		alsa_amixer -c 0 cset numid=8 1000(media_in gain 0 Volume)
		alsa_amixer -c 0 cset numid=8 10
		Continuously give some random values minimum for 10 times

13. BT_16k validation
	Put appropiate blob
	 ===================
	BT 16k blob & playback wav files are available, need to push in target
		adb push sspGpMrbBtHfp.blob_16k /vendor/firmware/sspGpMrbBtHfp.blob
		adb push bt_playback_16.wav /sdcard

	 Mixer settings
	 ==============
	 alsa_amixer -c 0 cset numid=3 1
	 alsa_amixer -c 0 cset numid=4 1

	In one terminal (capture):
	 ==========================
	alsa_arecord -Dhw:0,5 -fs32_LE -r16000 -c1 /sdcard/bt_16k_capture.wav
	wait for 10 secs

	In another terminal (playback):
	 ===============================
	alsa_aplay -Dhw:0,6 /sdcard/bt_playback_16.wav
	play for 10 secs

	Then switch for capture terminal & stop capture
	 also stop playback in another terminal

