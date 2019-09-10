#USB
export USB_DRIVERS="/sys/bus/usb/devices"

#WIFI
export WIFI_DRIVER="/sys/class/net"

#GPS
export GPS_PORT_PATH="/dev/gps"
export GPS_GPIO_PATH="/sys/devices/platform/intel_mid_gps/intel_mid_gps"
export GPS_HAL_PATH="/system/lib/hw"
export DATA_PATH="/data"
export GPS_PORT="ttyGPS"
export GPS_GPIO_STATUS="enable"
export GPS_HAL="gps.gsd.so"
export GPS_DATA="gps"

#AUDIO
export ALSA_VER="/proc/asound/version"
export AUDIO_PCM="/proc/asound/pcm"

#MODULES
export MODULES="/lib/modules"

#DRIVERPATH
export DRIVERPATH="/system"

#ADB
export UD_FILE_LOCAL_PATH="tools"
export UD_FILE_REMOTE_PATH="/data"
#export FILE_ADB_PUSH="file_to_upload"
export FILE_ADB_PULL_NAME="file_uploaded"
#export APK_TO_INSTALL="Development.apk"
export APK_PACKAGE_PATTERN="development"
export EXTERNAL_SITE="www.google.com"
export INTERNAL_SITE="autoproxy.intel.com"

#GENERICS
export SCREEN_CAPTURE_PATH="/data"
export SCREEN_CAPTURE_NAME="screen.png"
export CMDLINE_PATH="/proc/cmdline"
export CPUINFO_PATH="/proc/cpuinfo"
export TOMBSTONES_PATH="/data/tombstones"
export TRACE_PATH="/data/anr"

# param has to have the same position that his value, if the param doesn't
# have value put the text no-value to identify it as no value
# list cpu attributes to compare
#export CPU_ATTRIBUTES=()
#export CPU_VALUES=()
