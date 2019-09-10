#!/bin/bash
##############################################################################

# @Author   Wenjiex.Yu(wenjiex.yu@intel.com)
# @desc     Automatic generate the csv format file from text format file
# @history  2017-12-27: First version

###############################################################################
txt_file=$1
csv_file=$2
txt_name=$(echo $1 | awk -F '/' '{print $NF}')
if [ -f $csv_file ] ; then
  rm $csv_file
fi
count=0
echo "No.,Test Case,Subtest Case,Test Result" >> $csv_file
cat $txt_file | while read LINE
do
  if [[ $txt_name == *"result"* ]] ; then
      if [[ $LINE == *"igt@"* ]] ; then
          count=`expr $count + 1`
          line_1=$(echo $LINE | awk -F '@' '{print $2}')
          line_2=$(echo $LINE | awk -F '@' '{print $3}')
          echo -n "$count,$line_1,$line_2," >> $csv_file
      elif [[ $LINE == *"SUCCESS"* ]] ; then
          line_3=$(echo "PASS")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"FAIL"* ]] ; then
          line_3=$(echo "FAIL")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"SKIP"* ]] ; then
          line_3=$(echo "SKIP")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"No Valid"* ]] ; then
          line_3=$(echo "N/A")
          echo $line_3 >> $csv_file
      fi
  else
      count=`expr $count + 1`
      line_1=$(echo $txt_name | awk -F '.' '{print $1}')
      line_2=$(echo $LINE | awk '{print $2}' | sed 's/\://g')
      echo -n "$count,$line_1,$line_2," >> $csv_file
      if [[ $LINE == *"SUCCESS"* ]] ; then
          line_3=$(echo "PASS")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"FAIL"* ]] ; then
          line_3=$(echo "FAIL")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"SKIP"* ]] ; then
          line_3=$(echo "SKIP")
          echo $line_3 >> $csv_file
      elif [[ $LINE == *"No Valid"* ]] ; then
          line_3=$(echo "N/A")
          echo $line_3 >> $csv_file
      fi
  fi
done
