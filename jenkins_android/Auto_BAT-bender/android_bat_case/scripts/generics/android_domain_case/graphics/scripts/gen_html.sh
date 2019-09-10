#!/bin/bash
##############################################################################

# @Author   Wenjiex.Yu(wenjiex.yu@intel.com)
# @desc     Automatic generate the html format file from csv format file
# @history  2017-12-27: First version

###############################################################################
datetime=`date +"%Y/%m/%d %H:%M:%S"`
file_input=$1
BUILD=$2
ANDROID_VER=$3
Test_suite=$4
Kernel_version=$5
file_output=$6
function create_html_head(){
  echo -e "<html>
    <body>
      <h1>Graphic Unit Test Report</h1>"
}
function create_test_info(){
  echo -e "<h3> Test info: </h3>
    <p id="info_summ">Date: $datetime</p>
    <p id="info_summ">Platform and build: $BUILD</p>
    <p id="info_summ">Android version: $ANDROID_VER</p>
    <p id="info_summ">Test suite: $Test_suite</p>
    <p id="info_summ">Kernel version: $Kernel_version</p>"
}
function create_summary(){
  echo -e "<h3> Summary:</h3>
    <p id="info_summ">Total: $1 </p>
    <p id="info_summ">Passed: $2 </p>
    <p id="info_summ">Failed: $3 </p>
    <p id="info_summ">Skipped: $4 </p>
    <p id="info_summ">N/A: $5 </p>"
}
function create_table_head(){
  echo -e "<table border="1" cellspacing="0" cellpadding="0">"
}
function create_td(){
    echo $1
    td_str=`echo $1 | awk 'BEGIN{FS=","}''{i=1; while(i<=NF) {print "<td>"$i"</td>";i++}}'`
    echo $td_str
}
function create_tr(){
  create_td "$1"
  echo -e "<tr>
    $td_str
  </tr>" >> $file_output
}
function create_table_end(){
  echo -e "</table>"
}
function create_html_end(){
  echo -e "</body></html>"
}
function create_html(){
  rm -rf $file_output
  touch $file_output
  count_total_add_1=0
  count_pass=0
  count_fail=0
  count_block=0
  count_na=0
  create_html_head >> $file_output
  create_test_info >> $file_output
  create_table_head >> $file_output
  while read line
  do
    if [[ $line == *"PASS"* ]] ; then
        count_pass=`expr $count_pass + 1`
    elif [[ $line == *"FAIL"* ]] ; then
        count_fail=`expr $count_fail + 1`
    elif [[ $line == *"SKIP"* ]] ; then
        count_block=`expr $count_block + 1`
    elif [[ $line == *"N/A"* ]] ; then
        count_na=`expr $count_na + 1`
    fi
    count_total_add_1=`expr $count_total_add_1 + 1`
    create_tr "$line"
  done < $file_input
  count_total=`expr $count_total_add_1 - 1`
  create_summary $count_total $count_pass $count_fail $count_block $count_na>> $file_output
  create_table_end >> $file_output
  create_html_end >> $file_output
}
create_html

