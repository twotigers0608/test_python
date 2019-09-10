#/bin/sh
# Clear BAT script

failed_cve=

function tc_boot_first_boot ()
{
	dmesg > dmesg.log
}

function tc_generics_check_kernel_warning () {
	dmesg | grep -i warning | wc -l
}

function tc_generics_check_kernel_version () {
	cat /proc/version
}

function tc_generics_kernel_cmdline () {
	cat /proc/cmdline
}

function tc_generics_partitions () {
	df |tee df.txt
}

function tc_generics_mount () {
	mount |tee mount.txt
}

function tc_generics_cpuinfo () {
	cat /proc/cpuinfo > cpuinfo.txt
}

function tc_wifi_driver_loaded() {
	dmesg |grep network |grep "network logging started"
}

function tc_wlan_enable() {
	phy=$(rfkill list |grep phy |cut -c 1,1)
	rfkill unblock $phy
	ifconfig wlan0 up
	iw wlan0 scan
}

function tc_bluetooth_enable() {
	hci=$(rfkill list |grep hci |cut -c 1,1)
	rfkill unblock $hci
	hciconfig up
}

function tc_kernel_config_check() {
	kv=$(uname -a | cut -d " " -f 3)
	export http_proxy=http://child-prc.intel.com:913
	export https_proxy=http://child-prc.intel.com:913
	git clone https://github.com/clearlinux/kernel-config-checker.git
	cd kernel-config-checker
        python setup.py build
        python setup.py install
	cd ../
        zcat /proc/config.gz | kcc >kccr-$kv.txt
	cat kccr-$kv.txt | grep "is not set but is required to be set to y" || cat kccr-$kv.txt | grep "is set but is required to be not set"
}

function tc_spectre_meltdown_check() {
	swupd bundle-add binutils\
		         lz4\
			 c-basic\
			 gzip\
			 xz\
			 sysadmin-basic\
			 os-core\
			 binutils
	git clone https://github.com/speed47/spectre-meltdown-checker
	cd spectre-meltdown-checker
	git am 0001-kernel_decompress-continue-to-try-other-decompress-t.patch
	cd ../
	bash spectre-meltdown-checker/spectre-meltdown-checker.sh -v > spectre-meltdown-check.log
	failed_cve=$(cat spectre-meltdown-check.log | grep 'SUMMARY'|awk -F ' ' '{for(i=1; i<=NF; i++) {print $i}}' | grep 'KO')
}

# run tests
if [ $# = 1 ]
then
$1
else
	echo " running full BAT takes approximately 1.5 minutes
		firstboot
		check kernel version
		check cpu info
		check kernel cmdline
		partitions
		mounted file systems
		dmesg kernel warnings
		check wifi and firmware loaded
                enable wifi
                enable bluetooth
		"
	echo
	echo

	# LAVAFy results log
	touch clear_bat.json
	> clear_bat.json
	echo -e "{" >> clear_bat.json
	tc_boot_first_boot
	ret=$?
	echo -n  ......first boot test...
	TESTCASE='tc-boot-first_boot'
	if [ $ret == 0 ]
	then
		echo PASS
		RESULT='pass'
	else
		echo FAILED!
		RESULT='fail'
	fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
	echo
	echo

	tc_generics_check_kernel_version
	ret=$?
        echo -n  ......kernel version test...
	TESTCASE='tc-generics-kernel_version'
        if [ $ret == 0 ]
        then
                echo PASS
		RESULT='pass'
        else
                echo FAILED!
		RESULT='fail'
        fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
        echo
        echo

	tc_generics_cpuinfo
	ret=$?
        echo -n  ......cpuinfo test...
	TESTCASE='tc-generics-cpuinfo'
        if [ $ret == 0 ]
        then
                echo PASS
		RESULT='pass'
        else
                echo FAILED!
		RESULT='fail'
        fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
        echo
        echo


	tc_generics_kernel_cmdline
	ret=$?
	echo -n  ......check kernel cmdline test...
	TESTCASE='tc-generics-kernel_cmdline'
	if [ $ret == 0 ]
	then
		echo PASS
		RESULT='pass'
	else
		echo FAILED!
		RESULT='fail'
	fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
	echo
	echo

	tc_generics_partitions
	ret=$?
	echo -n  ......check partition test...
	TESTCASE='tc-generics-partitions'
	if [ $ret == 0 ]
	then
		echo PASS
		RESULT='pass'
	else
		echo FAILED!
		RESULT='fail'
	fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
	echo
	echo

	tc_generics_mount
	ret=$?
	echo -n  .........check mounts test...
	TESTCASE='tc-generics-mounts'
	if [ $ret == 0 ]
	then
		echo PASS
		RESULT='pass'
	else
		echo FAILED!
		RESULT='fail'
	fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
	echo
	echo

	tc_generics_check_kernel_warning
	ret=$?
	echo -n  .........check kernel warnings test...
	TESTCASE='tc-generics-check_kernel_warning'
	if [ $ret == 0 ]
	then
		echo PASS
		RESULT='pass'
	else
		echo FAILED!
		RESULT='fail'
	fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
        echo
	echo

        tc_wifi_driver_loaded
        ret=$?
        echo -n  .........check wifi driver and firmware loaded...
        TESTCASE='tc_wifi_driver_loaded'
        if [ $ret == 0 ]
        then
                echo PASS
                RESULT='pass'
        else
                echo FAILED!
	        RESULT='fail'
        fi
	echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
        echo
        echo

	tc_spectre_meltdown_check
        ret=$?
        echo -n  .........check spectre and meltdown...
        TESTCASE='tc_spectre_meltdown_check'
	if [ $ret == 0 ]
	then
            if [ -z "$failed_cve" ]
            then
            	echo PASS
            	RESULT='pass'
            else
            	echo FAILED!
		echo $failed_cve
            	RESULT='fail'
	    fi
	else
	    echo FAILED!
	    RESULT='fail'
	fi
        echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
        echo
        echo


#        tc_wlan_enable
#        ret=$?
#        echo -n  .........enable wlan...
#        TESTCASE='tc_wlan_enable'
#        if [ $ret == 0 ]
#        then
#                echo PASS
#	        RESULT='pass'
#        else
#                echo FAILED!
#		RESULT='fail'
#        fi
#        echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
#        echo
#        echo



#        tc_bluetooth_enable
#        ret=$?
#        echo -n  .........enable bluetooth...
#        TESTCASE='tc_bluetooth_enable'
#        if [ $ret == 0 ]
#        then
#                echo PASS
#                RESULT='pass'
#        else
#                echo FAILED!
#                RESULT='fail'
#        fi
#        echo -e "\"$TESTCASE\": [\"$RESULT\"]" >> clear_bat.json
#
#
#         echo -e "}" >> clear_bat.json


#        tc_kernel_config_check
#        ret=$?
#        echo -n  .........check kernel config...
#        TESTCASE='tc_kernel_config_check'
#        if [ $ret == 0 ]
#        then
#                echo FAILED!
#                RESULT='fail'
#        else
#                echo PASS
#                RESULT='pass'
#        fi
#        echo -e "\"$TESTCASE\": [\"$RESULT\"]," >> clear_bat.json
#        echo
#        echo

fi
