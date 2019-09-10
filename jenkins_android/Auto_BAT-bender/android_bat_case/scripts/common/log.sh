#!/bin/bash
################################################################################
# Copyright (C) 2015 Intel - http://www.intel.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation version 2.
#
# This program is distributed "as is" WITHOUT ANY WARRANTY of any
# kind, whether express or implied; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
################################################################################

# @Author   Luis Rivas(luis.miguel.rivas.zepeda@intel.com)
# @desc     Common log function
# @history  2015-06-23: First version

############################# Functions ########################################
__print_msg() {
  local id=$1
  shift 1
  local msg="$@"
  local epoch=$(date +%s)
  local p1=$(printf ' %.0s' {1..10})
  local p2=$(printf ' %.0s' {1..15})
  local p3=$(printf ' %.0s' {1..5})
  local caller=$(basename ${BASH_SOURCE[2]})
  local caller_size=${#caller}
  local caller_diff=$((caller_size - 14))

  if [ $caller_diff -gt 0 ]; then
    caller=$(echo $caller | cut -c ${caller_diff}-)
  fi

  printf "[%s%s][%s%s][%s%s]: %s\n" $epoch "${p1:${#epoch}}" \
                                    $caller "${p2:${#caller}}" \
                                    $id "${p3:${#id}}" "$msg"
  return 0
}

__print_carriage_msg() {
  local id=$1
  shift 1
  local msg="$@"
  local epoch=$(date +%s)
  local p1=$(printf ' %.0s' {1..10})
  local p2=$(printf ' %.0s' {1..15})
  local p3=$(printf ' %.0s' {1..5})
  local caller=$(basename ${BASH_SOURCE[2]})
  local caller_size=${#caller}
  local caller_diff=$((caller_size - 14))

  if [ $caller_diff -gt 0 ]; then
    caller=$(echo $caller | cut -c ${caller_diff}-)
  fi

  printf "\r[%s%s][%s%s][%s%s]: %s" $epoch "${p1:${#epoch}}" \
                                    $caller "${p2:${#caller}}" \
                                    $id "${p3:${#id}}" "$msg"
  return 0
}

print_warn() {
  local msg=$1
  __print_msg "WARN" "$msg"
  return 0
}

print_info() {
  local msg=$1
  __print_msg "INFO" "$msg"
  return 0
}

print_err() {
  local msg=$1
  __print_msg "ERROR" "$msg"
  return 0
}

print_fatal() {
  local msg=$1
  __print_msg "FATAL" "$msg"
  return 0
}

print_abort() {
  local msg=$1
  __print_msg "ABORT" "$msg"
  return 0
}

print_carriage() {
  local msg=$1
  __print_carriage_msg "INFO" "$msg"
}

print_newline() {
  echo ""
}
