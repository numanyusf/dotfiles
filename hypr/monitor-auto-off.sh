#!/bin/bash
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCKET" | while read -r event; do
  case "$event" in
    monitoradded\>\>*|monitoraddedv2\>\>*)
      sleep 1
      omarchy-hyprland-monitor-internal off
      ;;
  esac
done
