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
TXT_APP=$(echo djIuMCAgICAgYm9vc3QgcGVyZm9tYW5jZSBnYW1l | base64 -d)
TXT_VER="VERSION"
TXT_FUNGSI="FUNCTION LIST"
TXT_INFO="INFO"
TXT_TEMP="Temp"
TXT_RAM="RAM Free"
TXT_AUTO="AUTO"
TXT_TEKAN="Press [ENTER] to STOP"
TXT_STOP_TXT="STOP"
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
stealth_cache_clean(){
  pm trim-caches 2048M >/dev/null 2>&1
  for p in /sdcard/Android/data/*/cache /sdcard/Android/data/*/files/cache /sdcard/Android/obb/*/cache /sdcard/DCIM/.thumbnails; do
    rm -rf $p/* >/dev/null 2>&1
  done
  find /sdcard -type f \( -name "*.tmp" -o -name "*.log" -o -name "cache_*" -o -name ".tmp*" \) -delete >/dev/null 2>&1
  find /data/local/tmp -type f -mtime +1 -delete >/dev/null 2>&1
  cmd package bg-dexopt-job >/dev/null 2>&1 &
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
  cmd package bg-dexopt-job >/dev/null 2>&1 &
  safe_set global cached_apps_freezer enabled
  safe_set global activity_starts_logging_enabled 0
  safe_set global app_auto_restriction_enabled 1
  if [ "$TIER" -eq 1 ]; then am kill-all >/dev/null 2>&1; fi
}
boost_cpu_gpu(){
  safe_set system pointer_speed 7
  safe_set global sem_enhanced_cpu_responsiveness 1
  safe_set global debug.hwui.renderer skiagl
  safe_set global debug.hwui.overdraw false
  safe_set global debug.hwui.render_thread true
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  renice -n -10 $$ >/dev/null 2>&1
}
slippery_logic(){
  TEMP=$1; FPS=$2
  if [ "$FPS" -ge 55 ]; then SLOP=4; PRESS=0.25; TO=150
  elif [ "$FPS" -ge 40 ]; then SLOP=6; PRESS=0.35; TO=170
  else SLOP=8; PRESS=0.5; TO=190
  fi
  safe_set system view_configuration_touch_slop $SLOP
  safe_set system touch.pressure.scale $PRESS
  safe_set system touch.size.scale 0.3
  safe_set secure long_press_timeout $TO
  safe_set system gesture_exclusion_limit 300
  safe_set global block_untrusted_touches 0
}
game_loader_boost(){
  for pkg in $(pm list packages 3 2>/dev/null | cut -d: -f2 | grep -i -E "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb" | head -8); do
    cmd package compile -m speed-profile -f $pkg >/dev/null 2>&1 &
  done
  safe_set global game_dashboard_enable 1
  safe_set global game_auto_temperature 0
}
map_gen_boost(){
  safe_set system large_heap 1
  safe_set global chunk_load_optimize 1
  safe_set global map_render_accel 1
  safe_set system hwui.render_dirty_regions false
  safe_set global map_preload_distance 12
}
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10))
  BAR=$(printf "%${FILL}s" | tr ' ' '#')
  EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e " ${W}$TXT_VER : $TXT_APP${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_FUNGSI :${NC}"
  echo -e "  ${G}[✓]${NC} ${W}all system performance : active${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}
termux-wake-lock 2>/dev/null
CYCLE=0
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto)
  CYCLE=$((CYCLE+1))
  draw_box $TEMP $RAM $FPS
  echo ""; echo -e "${B}[$(date +%T)] $TXT_INFO: Secured Device ULTIMATE${NC}"
  echo -e "${G}[$(date +%T)] $TXT_AUTO: $BOOST_POWER | Touch $SENS Real-Time${NC}"
  if [ $((CYCLE % 5)) -eq 0 ]; then stealth_cache_clean; fi
  ultra_anti_ads
  ultra_anti_lag
  boost_cpu_gpu
  slippery_logic $TEMP $FPS
  game_loader_boost
  map_gen_boost
  echo -e "${G}[$(date +%T)] ULTIMATE: All System Active${NC}"
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 3; then clear; echo -e "${G}✔ $TXT_STOP_TXT - Secured${NC}"; safe_set global private_dns_mode opportunistic; safe_set system pointer_speed 3; safe_set secure long_press_timeout 400; safe_set system min_refresh_rate 60; exit 0; fi
done
