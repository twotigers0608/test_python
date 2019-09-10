#!/usr/bin/python

import commands,sys
import re
adbshell = 'adb shell '
if(len(sys.argv)==2):
    deviceid=sys.argv[1]
    adbshell = 'adb -s %s shell ' % deviceid
    #print adbshell
(status, output) = commands.getstatusoutput(adbshell+'getprop')
if status==0:
#    print output
    pattern = re.compile('\[ro\.build\.description\]: \[(.*?)\]')
    match = pattern.search(output)
    if match:
        print "Build: %s" % match.group(1)
    pattern = re.compile('\[ro\.bootloader\]: \[(.*?)\]')
    match = pattern.search(output)
    if match:
        print "BIOS: %s" % match.group(1)
    pattern = re.compile('\[ro\.build\.version\.release\]: \[(.*?)\]')
    match = pattern.search(output)
    if match:
        print "Android Version: %s" % match.group(1)
    pattern = re.compile('\[ro\.product\.model\]: \[(.*?)\]')
    match = pattern.search(output)
    if match:
        print "Model Number: %s" % match.group(1)

(kstatus, kernel) = commands.getstatusoutput(adbshell+'cat /proc/version')
if kstatus==0:
    print "Kernel: %s" % kernel

