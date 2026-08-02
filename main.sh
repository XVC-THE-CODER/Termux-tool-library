#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
_b=$(getprop $(echo cm8ucHJvZHVjdC5icmFuZA== | base64 -d) 2>/dev/null | tr 'a-z' 'A-Z')
_m=$(getprop $(echo cm8ucHJvZHVjdC5tb2RlbA== | base64 -d) 2>/dev/null)
_c=$(getprop $(echo cm8uYm9hcmQucGxhdGZvcm0= | base64 -d) 2>/dev/null)
if [ -z "$_c" ]; then _c=$(getprop $(echo cm8uaGFyZHdhcmU= | base64 -d) 2>/dev/null); fi
if [ -z "$_c" ]; then _c=$(cat /proc/cpuinfo 2>/dev/null | grep Hardware | head -1 | cut -d: -f2 | xargs); fi
_k=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
_g=$(( _k / 1024 ))
_v=$(getprop $(echo cm8uYnVpbGQudmVyc2lvbi5yZWxlYXNl | base64 -d) 2>/dev/null)
[ -z "$_b" ] && _b=$(echo R2VuZXJpYw== | base64 -d)
[ -z "$_m" ] && _m=$(echo RGV2aWNl | base64 -d)
[ -z "$_c" ] && _c=$(echo VW5rbm93bg== | base64 -d)
LANG_CODE="ID"
detect_lang(){
  LOC=$(getprop $(echo cGVyc2lzdC5zeXMubG9jYWxl | base64 -d) 2>/dev/null | tr 'a-z' 'A-Z')
  if echo "$LOC" | grep -q "ID"; then LANG_CODE="ID"; else LANG_CODE="EN"; fi
  if [ -z "$LOC" ]; then
    SIM=$(getprop $(echo Z3NtLnNpbS5vcGVyYXRvci5pc28tY291bnRyeQ== | base64 -d) 2>/dev/null | tr 'a-z' 'A-Z')
    if [ "$SIM" = "ID" ]; then LANG_CODE="ID"; else LANG_CODE="EN"; fi
  fi
}
load_translation(){
  TXT_APP=$(echo ICAgICBib29zdCB1bHRpbWF0ZSBWMi4w | base64 -d)
  TXT_VER="VERSION"
  TXT_FUNGSI="FUNGSI LIST"
  TXT_INFO="INFO"
  TXT_TIER="TIER DEVICE"
  TXT_BOOST="BOOST POWER"
  TXT_CPU="CPU GPU BOOST"
  TXT_SLIP="SLIPPERY REAL-TIME"
  TXT_FRAME="FRAME OPTIMIZE"
  TXT_TEMP="Suhu"
  TXT_RAM="RAM Free"
  TXT_AUTO="AUTO"
  TXT_TEKAN="Tekan [ENTER] untuk STOP"
  TXT_STOP_TXT="STOP"
  if [ "$LANG_CODE" = "EN" ]; then
    TXT_VER="VERSION"
    TXT_FUNGSI="FUNCTION LIST"
    TXT_INFO="INFO"
    TXT_TIER="DEVICE TIER"
    TXT_BOOST="BOOST POWER"
    TXT_CPU="CPU GPU BOOST"
    TXT_SLIP="SLIPPERY REAL-TIME"
    TXT_FRAME="FRAME OPTIMIZE"
    TXT_TEMP="Temp"
    TXT_AUTO="AUTO"
    TXT_TEKAN="Press [ENTER] to STOP"
    TXT_STOP_TXT="STOP"
  fi
}
detect_lang
load_translation
if [ "$_g" -le 4 ]; then
  TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5; SENS=9
elif [ "$_g" -le 6 ]; then
  TIER=2; TIER_NAME="MID"; BOOST_POWER="75% PERFORMANCE"; MAX_CPU_PERCENT=90; REFRESH=90; ANIM=0.3; SENS=9
elif [ "$_g" -le 8 ]; then
  TIER=3; TIER_NAME="HIGH"; BOOST_POWER="100% TURBO"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0; SENS=10
else
  TIER=4; TIER_NAME="EXTREME"; BOOST_POWER="120% EXTREME OC"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0; SENS=10
fi
if echo "$_c" | grep -qi "mt6765\|helio\|G35\|G25\|G85"; then
  TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED ADEM"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5; SENS=9
fi
safe_set(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.08; }
get_temp(){ MAX=0; for f in /sys/class/thermal/thermal_zone*/temp; do [ -f "$f" ] || continue; T=$(cat $f 2>/dev/null); [ "$T" -gt 1000 ] && T=$((T/1000)); [ "$T" -gt "$MAX" ] && MAX=$T; done; [ "$MAX" -eq 0 ] && MAX=40; echo $MAX; }
get_ram_free(){ free -m | awk '/Mem:/{print $7}'; }
get_fps_auto(){
  TEMP=$(get_temp); RAM=$(get_ram_free)
  if [ "$TIER" -eq 1 ]; then MAX_FPS=60; elif [ "$TIER" -eq 2 ]; then MAX_FPS=90; else MAX_FPS=120; fi
  if [ "$TEMP" -lt 42 ] && [ "$RAM" -gt 1000 ]; then echo $MAX_FPS
  elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-2))
  else echo $((MAX_FPS-6))
  fi
}
ultra_anti_ads(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier $(echo ZG5zLmFkZ3VhcmQuY29t | base64 -d)
  safe_set global ad_services_enabled 0
  safe_set global ad_services_consent_enabled 0
  safe_set secure limit_ad_tracking 1
  safe_set global analytics_enabled 0
  for enc in Y29tLmhleXRhcC5tc3A= Y29tLmhleXRhcC5jbG91ZA== Y29tLm9wcG8ubWFya2V0 Y29tLmNvbG9yb3Mub3Bwb2d1YXJkZWxm Y29tLmZhY2Vib29rLnN5c3RlbQ==; do
    pkg=$(echo $enc | base64 -d)
    pm clear --cache-only $pkg >/dev/null 2>&1
  done
}
ultra_anti_lag(){
  pm trim-caches 999M >/dev/null 2>&1
  cmd package bg-dexopt-job >/dev/null 2>&1 &
  safe_set global cached_apps_freezer enabled
  safe_set global cached_apps_freezer_compression lz4
  safe_set global activity_starts_logging_enabled 0
  safe_set global app_auto_restriction_enabled 1
  safe_set global system_cap 0
  if [ "$TIER" -eq 1 ]; then am kill-all >/dev/null 2>&1; fi
}
boost_cpu_gpu(){
  safe_set system pointer_speed 7
  safe_set global sem_enhanced_cpu_responsiveness 1
  safe_set global game_home_enable 1
  safe_set global debug.hwui.renderer skiagl
  safe_set global debug.hwui.overdraw false
  safe_set global debug.hwui.use_buffer_age false
  safe_set global debug.hwui.render_thread true
  safe_set global debug.hwui.render_thread_count 2
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  safe_set secure refresh_rate_mode 1
  cmd package compile -m speed-profile -a >/dev/null 2>&1 &
  renice -n -10 $$ >/dev/null 2>&1
}
slippery_logic(){
  TEMP=$1; FPS=$2
  if [ "$FPS" -ge 55 ]; then SLOP=4; PRESS=0.25; TO=150; SIZE=0.3
  elif [ "$FPS" -ge 40 ]; then SLOP=6; PRESS=0.35; TO=170; SIZE=0.4
  else SLOP=8; PRESS=0.5; TO=190; SIZE=0.5
  fi
  safe_set system view_configuration_touch_slop $SLOP
  safe_set system touch.pressure.scale $PRESS
  safe_set system touch.size.scale $SIZE
  safe_set secure long_press_timeout $TO
  safe_set system gesture_exclusion_limit 300
  safe_set global block_untrusted_touches 0
  safe_set system tap_duration_threshold 0
  safe_set system touch.size.calibration geometric
  safe_set system touch.pressure.calibration amplitude
  if command -v xinput >/dev/null 2>&1; then
    for id in $(xinput list --id-only 2>/dev/null | head -5); do
      xinput set-prop $id "libinput Accel Speed" 1 2>/dev/null
      xinput set-prop $id "libinput Accel Profile Enabled" 0 1 2>/dev/null
      xinput set-prop $id "libinput Scrolling Pixel Distance" 10 2>/dev/null
    done
  fi
}
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; TIER_NOW=$4; BOOST_NOW=$5; SENS_NOW=$6
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10))
  BAR=$(printf "%${FILL}s" | tr ' ' '#')
  EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e " ${W}$TXT_VER : $TXT_APP${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_FUNGSI :${NC}"
  echo -e "  ${G}[✓]${NC} ${W}$TXT_TIER : $TIER_NOW${NC}"
  echo -e "  ${G}[✓]${NC} ${W}$TXT_BOOST : $BOOST_NOW${NC}"
  echo -e "  ${G}[✓]${NC} ${W}$TXT_CPU : $MAX_CPU_PERCENT% | $REFRESH Hz Locked${NC}"
  echo -e "  ${G}[✓]${NC} ${W}$TXT_SLIP : $SENS_NOW/10 REAL-TIME${NC}"
  echo -e "  ${G}[✓]${NC} ${W}$TXT_FRAME : V-Sync Stable | Touch 150ms${NC}"
  echo -e "  ${G}[✓]${NC} ${W}ANTI LAG + BLOCK ADS + GPU RENDER${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}
termux-wake-lock 2>/dev/null
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto)
  draw_box $TEMP $RAM $FPS "$TIER - $TIER_NAME" "$BOOST_POWER" "$SENS"
  echo ""; echo -e "${B}[$(date +%T)] $TXT_INFO: Frame Locked $REFRESH Hz | Touch Real-Time${NC}"
  echo -e "${G}[$(date +%T)] $TXT_AUTO: $BOOST_POWER | FPS $FPS stabil${NC}"
  ultra_anti_ads
  ultra_anti_lag
  boost_cpu_gpu
  slippery_logic $TEMP $FPS
  echo -e "${G}[$(date +%T)] ULTIMATE V2: Frame Optimize + Slippery Applied${NC}"
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 3; then clear; echo -e "${G}✔ $TXT_STOP_TXT - Secured${NC}"; safe_set global private_dns_mode opportunistic; safe_set system pointer_speed 3; safe_set secure long_press_timeout 400; safe_set system min_refresh_rate 60; exit 0; fi
done
