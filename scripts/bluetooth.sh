#!/bin/sh
if [ "$(bluetoothctl show | grep "Powered: yes" | wc -l)" -eq 1 ]; then
  printf " on"
else
  printf " off"
fi