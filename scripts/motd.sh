#!/usr/bin/env bash
# Login status screen for the homelab (shown by bashrc on interactive SSH logins).
# Accent is Debian red (#D70751); a bar at 80 %+ turns bright bold red with a "!". Dots: green/amber/red.
# Never blocks: the dashboard API gets 1 s, everything else is local.

A=$'\e[38;2;215;7;81m'; Y=$'\e[38;5;214m'; R=$'\e[38;5;203m'; HR=$'\e[1;38;2;255;64;64m'; G=$'\e[38;5;78m'; D=$'\e[38;5;245m'; W=$'\e[1;97m'; N=$'\e[0m'
HOT=80

bar() {  # bar <percent> -> 10-segment bar, red at HOT
  local p=${1%.*} c=$A n i out=""
  (( p >= HOT )) && c=$HR
  n=$(( (p + 5) / 10 )); (( p > 0 && n == 0 )) && n=1
  for ((i = 0; i < 10; i++)); do (( i < n )) && out+="▰" || out+="▱"; done
  printf '%s%s%s' "$c" "$out" "$N"
}
pad() { local t="$1" w=$2; printf '%s%*s' "$t" $(( w > ${#t} ? w - ${#t} : 0 )) ""; }  # pad by visible width (° is 2 bytes)
human() { awk -v b="$1" 'BEGIN { if (b >= 1e12) printf "%.1f TB", b/1e12; else if (b >= 1e10) printf "%.0f GB", b/1e9; else printf "%.1f GB", b/1e9 }'; }

# --- host ---
host=$(hostname)
os=$(. /etc/os-release && echo "${NAME%% *} ${VERSION_ID}")
up=$(awk '{d=int($1/86400); h=int($1%86400/3600); m=int($1%3600/60); if (d) printf "%dd %dh", d, h; else printf "%dh %dm", h, m}' /proc/uptime)
now=$(date '+%a %-d %b %H:%M')
lan=$(ip -4 -o addr show scope global | awk '$2 !~ /^(docker|br-|veth|tailscale)/ {split($4, a, "/"); print a[1]; exit}')
ts=$(ip -4 -o addr show tailscale0 2>/dev/null | awk '{split($4, a, "/"); print a[1]}')

# --- resources ---
read -r _ u1 n1 s1 i1 w1 x1 y1 z1 _ < /proc/stat; sleep 0.15
read -r _ u2 n2 s2 i2 w2 x2 y2 z2 _ < /proc/stat
busy=$(( (u2+n2+s2+x2+y2+z2) - (u1+n1+s1+x1+y1+z1) )); idle=$(( (i2+w2) - (i1+w1) ))
cpu=$(( busy + idle > 0 ? 100 * busy / (busy + idle) : 0 ))
temp=""
for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = coretemp ] && temp=$(( $(cat "$h/temp1_input") / 1000 )); done
read -r mt ma < <(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t*1024, a*1024}' /proc/meminfo)
mu=$(( mt - ma )); mp=$(( 100 * mu / mt ))
read -r st su < <(df -B1 --output=size,used / | tail -1); sp=$(( 100 * su / st ))
bk=""; if mountpoint -q /mnt/backup; then read -r bt bu < <(df -B1 --output=size,used /mnt/backup | tail -1); bp=$(( 100 * bu / bt )); bk=1; fi

tcol=$D; [ -n "$temp" ] && (( temp >= 85 )) && tcol=$R

# --- health (containers locally, the rest from the dashboard) ---
read -r crun ctot < <(docker ps -a --format '{{.Image}} {{.State}}' 2>/dev/null | awk '$1 !~ /^vsc-/ {t++; if ($2 == "running") r++} END {print r+0, t+0}')
sum=$(curl -s -m 1 https://home.imhosting.cc/api/summary 2>/dev/null)

dot() { printf '%s●%s %s' "$1" "$N" "$2"; }
health=()
if (( crun == ctot )); then health+=("$(dot "$G" "$crun/$ctot containers")"); else health+=("$(dot "$R" "$crun/$ctot containers")"); fi
if [ -n "$sum" ] && command -v jq >/dev/null; then
  ku=$(jq -r '.kuma.up // empty' <<<"$sum"); kt=$(jq -r '.kuma.total // empty' <<<"$sum")
  if [ -n "$ku" ]; then
    if [ "$ku" = "$kt" ]; then health+=("$(dot "$G" "$ku/$kt monitors up")")
    else
      down=$(jq -r '.kuma.byName | to_entries | map(select(.value == 0) | .key) | join(", ")' <<<"$sum")
      health+=("$(dot "$R" "${down:-$((kt-ku)) monitors} down")")
    fi
  fi
  bs=$(jq -r '.backrest.lastStatus // empty' <<<"$sum"); bt_=$(jq -r '.backrest.lastTime // empty' <<<"$sum")
  if [ -n "$bs" ]; then
    when=$(date -d "@$(( bt_ / 1000 ))" '+%-d %b' 2>/dev/null)
    [ "$bs" = STATUS_SUCCESS ] && health+=("$(dot "$G" "backup $when OK")") || health+=("$(dot "$R" "backup $when FAILED")")
  fi
  upd=$(jq -r '.diun.updates // 0' <<<"$sum")
  (( upd > 0 )) && health+=("$(dot "$Y" "$upd updates")") || health+=("$(dot "$G" "0 updates")")
else
  health+=("$(dot "$D" "dashboard not reachable")")
fi

# --- last login (previous session), named via Tailscale ---
read -r lip lwhen < <(last -n 2 -i "$USER" 2>/dev/null | awk 'NR == 2 {print $3, $7}')
lname=$lip
if [ -n "$lip" ] && command -v tailscale >/dev/null; then
  n=$(tailscale status 2>/dev/null | awk -v ip="$lip" '$1 == ip {print $2; exit}'); [ -n "$n" ] && lname=$n
fi

hot() { (( ${1%.*} >= HOT )) && printf '%s!%s' "$HR" "$N" || printf ' '; }

# --- print ---
# Debian swirl (as in neofetch/fastfetch) beside the first six lines; compact header on narrow terminals.
cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
l1="$(printf '%s%s%s · %s · up %s' "$W" "$host" "$N" "$os" "$up")"
l2="$(printf '%s%s · LAN %s · TS %s%s' "$D" "$now" "${lan:--}" "${ts:--}" "$N")"
l4="$(printf 'CPU     %s %3s %%%s  %s%s%s Memory  %s  %s / %s' "$(bar "$cpu")" "$cpu" "$(hot "$cpu")" "$tcol" "$(pad "${temp:+$temp °C}" 17)" "$N" "$(bar "$mp")" "$(human "$mu")" "$(human "$mt")")"
if [ -n "$bk" ]; then bkline="Backup  $(bar "$bp")  $(human "$bu") / $(human "$bt")"; else bkline="Backup  ${R}stick not mounted${N}"; fi
l5="$(printf 'SSD     %s %3s %%%s  %s%s%s %s' "$(bar "$sp")" "$sp" "$(hot "$sp")" "$D" "$(pad "$(human "$su") / $(human "$st")" 17)" "$N" "$bkline")"
echo
if (( cols >= 110 )); then
  logo=('  _____  ' ' /  __ \ ' '|  /    |' '|  \___- ' '-_       ' '  --_    ')
  info=("$l1" "$l2" "" "$l4" "$l5" "")
  for i in 0 1 2 3 4 5; do printf '  %s%s%s   %s\n' "$A" "${logo[$i]}" "$N" "${info[$i]}"; done
else
  printf '  %s\n  %s\n\n  %s\n  %s\n' "$l1" "$l2" "$l4" "$l5"
fi
echo
printf '  %s\n\n' "$(IFS='|'; out=""; for h in "${health[@]}"; do out+="$h   "; done; echo "$out")"
printf '  %s↪ home.imhosting.cc%s' "$A" "$N"
[ -n "$lip" ] && printf '        %slast login %s from %s%s' "$D" "$lwhen" "$lname" "$N"
printf '\n\n'
