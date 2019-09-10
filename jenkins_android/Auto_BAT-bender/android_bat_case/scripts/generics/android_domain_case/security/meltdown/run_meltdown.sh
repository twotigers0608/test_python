#!/bin/bash

# Date: 4/13/2018
# Description: run meltdown test

meltdown_git="https://github.com/paboldin/meltdown-exploit.git"
meltdown_path="/data/meltdown"
plat_simics="localhost:5558"
src_root=${0%/*}

show_help()
{
     echo "$0 -[dh]"
     echo "-d [device id]  specify device id"
     echo "-h              help"
     exit 0
}

connect_adb()
{
     adb connect $plat_simics
     sleep 2s
}

check_device()
{
     echo -e "\nFinding device ..."
     if [ ! -n "$devid" ]
     then
	echo -e "\nplease input [device id]"
	echo -e "eg: ./run_meltdown.sh -d R1J56Lc98fdd1a"
	exit
     fi

     if [ $devid == $plat_simics ]
     then
          connect_adb
     fi

     retry=0
     while [ $retry -le 10 ]
     do
         dev_exist=$(adb devices | grep $devid | grep 'device' | wc -l)
         if [ $dev_exist -eq 1 ]; then
             break
         elif [ $dev_exist -ge 1 ]; then
             echo "Found multiple devices !!!"
             exit 1
         else
             retry=$(($retry + 1))
             sleep 1s
         fi
     done

     if [ $retry -ge 10 ]; then
          echo "No available device found !!!"
          exit 1
     fi
}

prepare_file()
{
     echo -e "\n#########################"
     echo -e "   Download Meltdown Test    "
     echo -e "#########################"
     rm -rf meltdown-exploit
     git clone ${meltdown_git} && cd meltdown-exploit

     echo -e "\n#########################"
     echo -e "   Compile Meltdown Test    "
     echo -e "#########################"
     echo "LDFLAGS += --static" >>Makefile
     make && cd ../

     which expect
     if [ $? -eq 1 ]; then
         sudo apt install -y expect
     fi
     adb root
     sleep 2
     echo -e "push test files into device ..."
     adb shell mkdir -p $meltdown_path
     adb push meltdown-exploit/run.sh $meltdown_path/
     adb push meltdown-exploit/meltdown $meltdown_path/

     if [ ! -d "results" ]
     then
          mkdir results
     fi
}

show_info()
{
     echo -e "\n#########################"
     echo -e "   Device Info   "
     echo -e "#########################"
     python ${src_root}/../../adbbuildinfo.py  | tee results/image_info.txt
}

attack_test()
{
     echo -e "\n#########################"
     echo -e "    Meltdown Test          "
     echo -e "#########################"
     meltdown_log="meltdown.log"
/usr/bin/expect <<-EOF
set timeout -1
spawn -noecho adb shell
expect "*# $"
send "echo 0 > /proc/sys/kernel/kptr_restrict\r"
expect "*# $"
send "cd $meltdown_path\r"
expect "*# $"
send "chmod +x run.sh\r"
expect "*# $"
send "/system/bin/sh run.sh | tee $meltdown_log\r"
expect "*# $"
send "exit\r"
expect eof
EOF
     adb pull $meltdown_path/$meltdown_log ./results/
}

check_result()
{
    attack_result=$(cat results/${meltdown_log} | grep "NOT VULNERABLE")
    if [ -n "$attack_result" ]; then
        echo -e "\nYou device is NOT VULNERABLE\n"
    else
	echo -e "\nYou device is VULNERABLE !!!\n"
    fi

}

if [ $# == 0 ]
then
     show_help
fi

while getopts "d:h" arg
do
     case $arg in
          d)
               devid=$OPTARG
               ;;
          h)
               show_help
               ;;
	  ?)
	       echo "unkonw argument"
               show_help
               ;;
        esac
done


echo -e "\nStarting run meltdown test ..."
check_device
prepare_file
show_info
starttime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s);
echo -e "\nStart time: $starttime"
attack_test
endtime=`date +'%Y-%m-%d %H:%M:%S'`
end_seconds=$(date --date="$endtime" +%s);
echo -e "\nEnd time: $endtime"
echo -e "Duration: "$((end_seconds-start_seconds))"s"
check_result
echo -e "\nThe test is over !\n"
