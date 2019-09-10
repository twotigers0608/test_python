#!/bin/bash
################################################################################
# Copyright (C) 2017 Intel - http://www.intel.com
#
# This program is aim to test basic test case on android x86 platform.
# You can download this project and add more basic test case to it.
################################################################################

# @Author   Wenjie Yu(wenjiex.yu@intel.com)
# @desc     Executor
# @history  2017-01-11: First version

############################# Functions #######################################
# please run it with "./android.sh DEVICE_ID"

die() {
  local msg=$@
  echo "$msg"
  exit 1
}

show_description() {                 ############  这个函数不会被调用到  ############
  local logs_dir=$1
  local name="${logs_dir}/${2}_desc.txt"
  local script=''
  local used_scripts=''

  # Create file
  touch ${name}

  echo -e "--------------------------------------------------------------------"
  echo -e "                          TESTCASES"
  echo -e "--------------------------------------------------------------------"
  for tcn in $(seq 0 $((${#TESTCASES[@]}-1))); do
    script=$(echo ${TESTCASES[$tcn]} | awk '{print $3}')
    if ! [[ "$used_scripts" =~ $script ]]; then
      $script -v | tee -a ${name}
      used_scripts="$used_scripts $script"
      count=$((count + 1))
    fi
  done
  echo "Testcases descriptions saved at ${name}"
  exit 0
}

get_testcases() {
  local scenario=$1      #这个函数就是'all',也是就是环境文件的文件名

  while IFS='' read -r line || [[ -n "$line" ]]; do     #做了一个循环这个循环是需要输入东西的下面的done后面就是输入的值
    # Skip comments
    if (echo $line | grep -qE '^\s*#'); then            #这一步就是跳过all这个文件的第一行
      continue                                   
    fi

    if [ $(echo $line | wc -w) -eq 1 ]; then            #这步是在检测,如果all文件里有一段为1(wc -w是统计字数,是分段统计的,以一个空格为一段),就会递归执行一遍这个函数,把新的文件名传进来,但是现在这步不会执行
      echo "Subscenario detected..."
      get_testcases $line
    else
      echo "Adding testcases '$line' to TESTCASES array"
      if [ -z "$TESTCASES" ]; then                      #这步在第一次会执行,第一次的时候TESTCASES是为0还没有数据写入,所以为真
        TESTCASES[0]=$line                              #第一次会给TESTCASES数组添加第一个值就是$line这个变量,也就是all文件里的每一行
      else
        TESTCASES=("${TESTCASES[@]}" "$line")           #给TESTCASES在原有值得后面添加新的值,最后TESTCASES数组里面就会包含all文件里面所有的数据
      fi
    fi
  done < ${SCENARIOS_DIR}/${scenario}                   #把all文件读取到这个循环,赋值给上面的read -r line的line变量
}

print_testcases() {      ############## 这步也没什么用,就是打印一下测试用例 ##################
  local count=0
  echo "Testcases to run..."
  for tcn in $(seq 0 $((${#TESTCASES[@]}-1))); do
    echo -e "\t${tcn}) ${TESTCASES[$tcn]}"
  done
}

execute_testcases() {
  local count=0
  local tc_name=''
  local st_time=''
  local end_time=''
  local result=''

  echo "Executing testcases..."
  for tcn in $(seq 0 $((${#TESTCASES[@]}-1))); do           #这个#号是在计数,会显示出TESTCASES这个数组里一共有多少个数值,这个[@]就是同时显示TESTCASES这个数组所有的数值
    # Get only tag
    tc_name=$(echo ${TESTCASES[$tcn]} | awk '{print $2}')   #awk '{print $2}'过滤出来的是最后执行结果的名字,${TESTCASES[$tcn]}这个TESTCASES是一个列表[$tcn]是一个数字就是在索引取值
    # Remove tag from testcase information
    testcase1=$(echo ${TESTCASES[$tcn]} | awk '{print $3}') #这是把脚本的名过滤出来awd '{print $3}'就是过滤第三列
    testcase2=$(echo ${TESTCASES[$tcn]} | awk '{print $4}') #这是过滤脚本的参数选项
    testcase3=$(echo ${TESTCASES[$tcn]} | awk '{print $5}') #这是过滤脚本的参数值
    testcase=$(echo "$testcase1 $testcase2 $testcase3")     #这就是脚本名加上 - 参数加上后面具体的参数
    # Get start time
    st_time=$(date '+%Y-%m-%d %H:%M:%S')                    #现在的时间
    st_t=$(date -u +"%s")                                   #date -u是显示的UTC的时间,比本地北京时间晚8小时,后面的%s就是让时间以秒来显示
    # Execute testcase
    echo "====================================================================="
    echo "Executing TC - $tc_name"
    echo "Start time: $st_time"
    echo "====================================================================="
    $testcase                                               #这个是执行了相对应的脚本,之所以执行这个脚本不需要加上./或者bash是因为之前已经把这些文件夹都放到PATH环境变量里了,这些脚本都可以直接执行了
    result=${PIPESTATUS[0]}                                 #这个${PIPESTATUS[0]}就是上一个命令的返回值,这是一个数组就取第0个,result保存的是0 1是执行的每一个测试脚本最后的结果
    if [ $result -ne 0 ]; then
      adb -s $DEVID shell dmesg > ${RES_DIR}/ERROR_${tc_name}.dmesg #如果result不等于0证明上一条脚本执行错误,然后会把相对应的错误保存出来
    fi
    end_time=$(date '+%Y-%m-%d %H:%M:%S')                   #现在的时间
    end_t=$(date -u +"%s")
    RESULTS[$tcn]=$result                                   #全局变量方便其他函数使用,这个变量保存的是最后的结果,RESULTS[0]这样命名变量就是把这个变量设置成一个数组,数组的每一个值就是执行结果的每一个值
    diff=$((end_t - st_t))                                  #结束的秒数减去开始的秒数
    echo -e "\nResult: $result"
    echo -e "End time: $end_time"
    echo -e "Duration: $((end_t - st_t)) seconds\n"         #这步是看一下这个测试执行了多长时间
  done
}

typeset -A RESULTS_STR=(               #typeset是用来设置变量的值的,后面的-A应该是设置变量的值为数组的但是应该是用-a??,索引的第0个就是pass,索引的第一个就是fail...
    [0]="PASS"
    [1]="FAIL"
    [2]="BLOCK"
)

save_results() {
  local logs_dir=$1                                     #这个$1是保存结果文件夹的绝对路径"/home/yzh/Desktop/android_bat_case/results/R1J56L34fb9966_356_all_2018-09-30-16-40-55"
  local count=0
  local tc_name=''
  local result_str=''

  echo "Saving results..."
  touch ${logs_dir}/results.csv                         #创建的这个csv文件是报错所有pass与fail的结果的

  for tcn in $(seq 0 $((${#TESTCASES[@]}-1))); do
    # Get only the tag
    tc_name=$(echo ${TESTCASES[$tcn]} | awk '{print $2}')    #把结果的名字过滤出来
    tc_suite=$(echo ${TESTCASES[$tcn]} | awk '{print $1}')   #这个是把执行的哪个脚本文件的名字过滤出来
    # Get result string PASS or FAIL or BLOCK
    result_str=${RESULTS_STR[${RESULTS[$tcn]}]}              #这个RESULTS是之前保存的结果的函数,里面只保存0,或者1,或者2,这个for循环导致tcn会从0往上一直加1,然后再对RESULTS_STR切片就是每一个脚本输出的结果

    echo "${tcn},${tc_suite},${tc_name},${result_str}" >> ${logs_dir}/results.csv    #这个就是把结果写入到csv这个文件里
    if [ $lavafy == 'yes'  ]; then                           #这个是在执行脚本的时候给定的参数-l后面的参数,通常执行脚本不给这个参数所以是no,这步不会执行
      result_str=`awk '{ print tolower($0) }' <<< ${result_str}`
      if [ ${result_str} == 'block' ];then
        result_str="skip"
      fi
     # echo -e "lava-test-case ${tc_suite}-${tc_name} --result ${result_str}"
      lava-test-case ${tc_name} --result ${result_str}
    else
      echo -e "TEST_RESULT: \t${tcn}  ${tc_suite}  ${tc_name}  ${result_str}"
    fi
  done
  echo "Results saved at ${logs_dir}/results.csv"
}

print_device_info() {
  ##################### 这个函数只是为了查看一下设备的信息的没有任何用 #######################
  local devid=$1
  echo "PLATFORM: $(adb -s $DEVID shell getprop ro.board.platform)"              #这个结果是broxton
  echo "RELEASE: $(adb -s $DEVID shell getprop ro.build.version.incremental)"    #这个报错,提示没有找到
  echo "RELEASE FULL DESC: $(adb -s $DEVID shell getprop ro.build.fingerprint)"  #也是报错,找不到
  echo "BIOS: $(adb -s $DEVID shell getprop ro.boot.bootloader)"                 #也是报错
}

main() {
  print_device_info $DEVID

  get_testcases $SCENARIO                                     #这步主要就是为了定义一下TESTCASES这边数组的值,这个数组就是读取的all文件里面的值,将来会决定要执行哪些脚本

  print_testcases                                             #这个函数只是展示一下所有要测试的东西,也就是all文件里所有的内容

  if [ $SHOW_TC_DESC -eq 1 ]; then                            #这步不会执行
    show_description $RES_DIR $SCENARIO
  else
    execute_testcases                                         #这步是根据all文件里写的东西来具体执行了各个测试脚本分别测试的每一个东西
    echo "Execution log saved at: ${RES_DIR}/${EXEC_NAME}.log"
  fi

  save_results $RES_DIR                                       #保存结果这个函数

  # Create zip file inside RES_DIR
  cd ${RES_DIR}
  zip -r ${RES_DIR}/${EXEC_NAME}.zip ./* 1> /dev/null
  echo "Zip file with execution results at: ${RES_DIR}/${EXEC_NAME}.zip"   #这是把所有结果压缩成一个zip包保存在结果目录下
}

############################ Script Variables ##################################
SCRIPTS_DIR='scripts'
SCENARIOS_DIR='scenarios'
TOOLS_DIR='tools'
RESULTS_DIR='results'
CONFIG_DIR='config'
SHOW_TC_DESC=0
RES_DIR=''
RELEASE=''
EXEC_NAME=''
ROOT=""
TESTCASES=
RESULTS=

############################# Dynamic Variables ################################
ROOT=$(dirname $(readlink -f ${BASH_SOURCE[0]}))   #这个ROOT就是当前这个脚本的所在目录
if [ -z "$ROOT" ]; then                            #只是判断ROOT这个变量是不是空的-z为空则为真,如果是空的则会直接退出这个脚本
  echo "Cannot get executor directory, cannot start the execution"
  exit 1
fi

############################# Environment Setup ################################
echo "Moving to executor root directory..."
cd ${ROOT}                                         #切换到这个脚本所在的目录
echo "We are now at $PWD"                          #$PWD是在哪个目录下执行的这个脚本

# Export script directory and all its subdirectories
export PATH=$PATH$(find ${ROOT}/${SCRIPTS_DIR}/ -type d -printf ":%p")  #设置环境变量
export PATH=$PATH$(find ${ROOT}/${SCENARIOS_DIR}/ -type d -printf ":%p")
export PATH=$PATH$(find ${ROOT}/${TOOLS_DIR}/ -type d -printf ":%p")

################################ CLI Params ####################################
SIMICS=no
export lavafy=no
SCENARIO='all'                         #默认的场景文件就是all
CONFIG='common'
while getopts c:s:l:d:n:p:j:b: option
do
 case "${option}"
 in
 c) SCENARIO=${OPTARG}                 #这个是提供场景文件的参数
    echo "SCENERIO: " $SCENARIO
    ;;

 s) SIMICS=${OPTARG}
    if [ $SIMICS == 'yes' ]; then
      export DEVID='localhost:5558'
      adb connect $DEVID
    fi
    echo "Simics: " $SIMICS
    ;;

 l) LAVAFY=${OPTARG}
    export lavafy=$LAVAFY
    echo "Lavafy: " $LAVAFY
    ;;

 d) dev_id=${OPTARG}
    export DEVID=$dev_id
    echo "Device ID: " $DEVID
    ;;

 n) WIFI_NAME=${OPTARG}
    export WIFI_NAME=$WIFI_NAME
    echo "WIFI NAME: " $WIFI_NAME
    ;;

 p) WIFI_PASSWORD=${OPTARG}
    export WIFI_PASSWORD=$WIFI_PASSWORD
    echo "WIFI PASSWORD: " $WIFI_PASSWORD
    ;;

 j) JOB_NAME=${OPTARG}
    ;;

 b) BUILD_NUMBER=${OPTARG}
    ;;
 esac
done

#i############################## MODULE LOGIC ###################################
# Verify if we got a devid
if [ -z "$DEVID" ]; then                             #判断设备的id如果是0则为真,就会退出脚本
    echo "Please provide a Device DEVID (-d DEVID)"
    exit 1
else
  if ! (adb devices | grep -q "$DEVID"); then        #还是判断输入的设备id是不是错的,如果是错的就退出脚本
    echo "$DEVID is not listed by adb devices..."
    echo "DEVICE NOT FOUND..."
    exit 1
  fi
fi

# Verify if we got a scenario
if [ -z "$SCENARIO" ]; then                          #SCENARIO是保存环境文件名的变量也就是那个all,如果是空也会退出,默认设置的就是all文件
    die "Please provide a Scenario File (-s SCENARIO)"
fi

# Get release from android properties
RELEASE=$(adb -s $DEVID shell getprop ro.build.version.incremental | tr -d '\r')  #结果是10,只是为了后面文件夹和文件命名用的

# Get dessert version
DESSERT=$(adb -s $DEVID shell getprop ro.build.version.release | cut -c 1)        #最后得到9,根本没有用到这个变量

# Source android version enviorment variables
#for i in $(seq 5 $DESSERT); do
#  echo "Importing envioronment variables for Android Dessert ${i}..."
#  source ${CONFIG_DIR}/d${i}.sh
#done

# If a configuration was provided, override default environment variables
if [ -n "$CONFIG" ]; then                                             #判断comm.sh这个文件是不是存在的
  if [ -f "${CONFIG_DIR}/${CONFIG}.sh" ]; then                        #判断comm.sh这个文件是不是存在的
    echo "Configuration provided"
    echo "Overriding default environment variables with ${CONFIG}..."
    source ${CONFIG_DIR}/${CONFIG}.sh                                 #source就相当于python里的import就是把这个脚本里的变量导入到这个脚本里,在这个脚本里可以引用
  else
    die "Configuration ${CONFIG} is not supported"
  fi
fi

# Create execution name
# EXEC_NAME="${DEVID}_${RELEASE}_${JOB_NAME}_$(date +%Y-%m-%d-%H-%M-%S)"     #这是结果的文件保存目录的目录名,DEVID是设备ID,release是从设备里查到的10,SCENARIO是上面定义的all
EXEC_NAME="${DEVID}_${BUILD_NUMBER}_${JOB_NAME}_$(date +%Y-%m-%d_%H-%M-%S)"     #这是结果的文件保存目录的目录名,DEVID是设备ID,release是从设备里查到的10,SCENARIO是上面定义的all

# Create result directory
RES_DIR=${ROOT}/${RESULTS_DIR}/${EXEC_NAME}                                #保存结果文件夹的绝对路径
mkdir -p ${RES_DIR}                                                        #创建这个文件夹

# Call main execution!!!
main | tee -a ${RES_DIR}/${EXEC_NAME}.log                                  #tee -a将前一个命令的正确输出保存到文件里而且也会在屏幕里输出
