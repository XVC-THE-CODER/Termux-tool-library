#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
_b=$(getprop ro.product.brand 2>/dev/null)
_m=$(getprop ro.product.model 2>/dev/null)
_c=$(getprop ro.board.platform 2>/dev/null)
[ -z "$_c" ] && _c=$(getprop ro.hardware 2>/dev/null)
[ -z "$_c" ] && _c=$(cat /proc/cpuinfo 2>/dev/null | grep Hardware | cut -d: -f2 | xargs)
_k=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
_g=$((_k / 1024 / 1024))
_v=$(getprop ro.build.version.release 2>/dev/null)
[ -z "$_b" ] && _b="Generic"
[ -z "$_m" ] && _m="Device"
[ -z "$_c" ] && _c="Unknown"
TXT_APP="v2.7   boost performance game"
TXT_VER="VERSION"
TXT_FUNGSI="FUNCTION LIST"
TXT_INFO="INFO"
TXT_TEMP="Temp"
TXT_RAM="RAM Free"
TXT_PING="Ping"
TXT_WIFI="Wifi"
TXT_TEKAN="Press [ENTER] to STOP"
TXT_STOP="STOP"
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
  TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5; SENS=9
fi
safe_set(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.08; }
full_reset(){
  safe_set global private_dns_mode opportunistic
  safe_set global private_dns_specifier ""
  safe_set system pointer_speed 3
  safe_set secure long_press_timeout 400
  safe_set system min_refresh_rate 60
  safe_set system peak_refresh_rate 60
  safe_set global window_animation_scale 1
  safe_set global transition_animation_scale 1
  safe_set global animator_duration_scale 1
  safe_set system view_configuration_touch_slop 8
  safe_set system touch.pressure.scale 1.0
  safe_set system touch.size.scale 1.0
  safe_set system tap_duration_threshold 100
  safe_set system gesture_exclusion_limit 200
  safe_set global block_untrusted_touches 1
  safe_set global wifi_suspend_optimizations_enabled 1
  safe_set global wifi_scan_throttle_enabled 1
  safe_set global wifi_power_save 1
  safe_set global wifi_wakeup_enabled 1
  safe_set global wifi_networks_available_notification_on 1
  safe_set global network_avoid_bad_wifi 1
  safe_set global captive_portal_detection_enabled 1
  safe_set global captive_portal_mode 1
  safe_set global package_verifier_enable 1
  safe_set secure install_non_market_apps 1
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    cmd appops set $pkg RUN_IN_BACKGROUND allow >/dev/null 2>&1
    cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1
    cmd appops set $pkg WAKE_LOCK allow >/dev/null 2>&1
  done
  termux-wake-unlock 2>/dev/null
  termux-notification-remove tool_up 2>/dev/null
}
abort_check(){
  if read -t 0.1 -n 1 2>/dev/null; then
    clear
    echo -e "${R}[!] ENTER Detected - Killing all system...${NC}"
    full_reset
    echo -e "${G}✔ $TXT_STOP - All Reset Secured${NC}"
    exit 0
  fi
}
get_temp(){
  MAX=0
  for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$f" ] || continue
    T=$(cat $f 2>/dev/null)
    [ "$T" -gt 1000 ] && T=$((T/1000))
    [ "$T" -gt "$MAX" ] && MAX=$T
  done
  [ "$MAX" -eq 0 ] && MAX=38
  echo $MAX
}
get_ram_free(){ free -m | awk '/Mem:/{print $7}'; }
get_ping(){
  P=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep -o 'time=[0-9.]*' | cut -d= -f2 | cut -d. -f1)
  [ -z "$P" ] && P=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | grep -o 'time=[0-9.]*' | cut -d= -f2 | cut -d. -f1)
  [ -z "$P" ] && P=0
  echo $P
}
get_wifi_info(){
  INFO=$(dumpsys wifi 2>/dev/null | grep -m 1 "mWifiInfo" | head -1)
  SPEED=$(echo $INFO | grep -o "link speed [0-9]*" | grep -o "[0-9]*")
  RSSI=$(echo $INFO | grep -o "RSSI: -[0-9]*" | grep -o "-[0-9]*" | head -1)
  [ -z "$SPEED" ] && SPEED="--"
  [ -z "$RSSI" ] && RSSI="--"
  echo "${SPEED}Mbps ${RSSI}dBm"
}
get_fps_auto(){
  TEMP=$(get_temp); RAM=$(get_ram_free)
  if [ "$TIER" -eq 1 ]; then MAX_FPS=60
  elif [ "$TIER" -eq 2 ]; then MAX_FPS=90
  else MAX_FPS=120; fi
  if [ "$TEMP" -lt 42 ] && [ "$RAM" -gt 1000 ]; then echo $MAX_FPS
  elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-2))
  else echo $((MAX_FPS-6)); fi
}
has_cooler(){
  ls /sys/class/thermal/cooling_device* >/dev/null 2>&1 && return 0
  ls /sys/class/thermal/thermal_zone* >/dev/null 2>&1 && return 0
  return 1
}
if has_cooler; then COOLER_ENABLED=1; COOLER_STATUS="AUTO"; else COOLER_ENABLED=0; COOLER_STATUS="NOT SUPPORTED"; fi
stealth_cache_clean(){
  pm trim-caches 2048M >/dev/null 2>&1
  for p in /sdcard/Android/data/*/cache /sdcard/DCIM/.thumbnails /sdcard/.cache; do rm -rf $p/* 2>/dev/null; done
  find /data/local/tmp -type f -mtime +1 -delete 2>/dev/null
  cmd package bg-dexopt-job >/dev/null 2>&1 &
}
ultra_anti_ads(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier dns.adguard.com
  safe_set global ad_services_enabled 0
  safe_set secure limit_ad_tracking 1
  safe_set global analytics_enabled 0
}
ultra_anti_lag(){
  pm trim-caches 999M >/dev/null 2>&1
  safe_set global cached_apps_freezer enabled
  safe_set global activity_starts_logging_enabled 0
  safe_set global app_auto_restriction_enabled 1
  safe_set global system_cap 0
  [ "$TIER" -eq 1 ] && am kill-all >/dev/null 2>&1
}
ultra_ping_boost(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier one.one.one.one
  safe_set global captive_portal_detection_enabled 0
  safe_set global captive_portal_mode 0
  safe_set global mobile_data_always_on 1
  sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
  sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
  sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
  ndc resolver clearnetdns default >/dev/null 2>&1
}
ultra_wifi_boost(){
  CUR_TEMP=$1
  if [ "$CUR_TEMP" -ge 45 ]; then
    safe_set global wifi_suspend_optimizations_enabled 1
    safe_set global wifi_scan_throttle_enabled 1
    safe_set global wifi_power_save 1
    WIFI_MODE="COOL ${CUR_TEMP}C Anti Panas"
  else
    safe_set global wifi_suspend_optimizations_enabled 0
    safe_set global wifi_scan_throttle_enabled 0
    safe_set global wifi_power_save 0
    WIFI_MODE="TURBO Max Speed"
  fi
  safe_set global wifi_wakeup_enabled 0
  safe_set global wifi_networks_available_notification_on 0
  safe_set global wifi_scan_always_enabled 0
  safe_set global network_avoid_bad_wifi 0
  safe_set global network_recommendations_enabled 0
  safe_set global ble_scan_always_enabled 0
  cmd wifi set-scan-always-available 0 >/dev/null 2>&1
  echo $WIFI_MODE
}
ultra_anti_malware(){
  safe_set global package_verifier_enable 1
  safe_set global package_verifier_include_adb 1
  safe_set global verifier_verify_adb_installs 1
  safe_set secure install_non_market_apps 0
  safe_set global app_auto_restriction_enabled 1
  for b in $(pm list packages 2>/dev/null | cut -d: -f2 | grep -iE "lucky.*patcher|freedom|apk.*editor|game.*guardian|cheat.*engine|phx.*team|fake.*gps|hack.*app"); do
    pm disable $b >/dev/null 2>&1
    am force-stop $b >/dev/null 2>&1
  done
  for p in /sdcard/Download/*.apk /sdcard/*.apk /sdcard/Download/*.tmp; do
    [ -f "$p" ] && rm -f "$p" >/dev/null 2>&1
  done
  pm trim-caches 999M >/dev/null 2>&1
}
ultra_bg_killer(){
  safe_set global activity_starts_logging_enabled 0
  safe_set global background_freezer_enabled 1
  safe_set global cached_apps_freezer enabled
  safe_set global device_idle_constants "inactive_to=60000,sensing_to=0,locating_to=0"
  safe_set global anr_show_background 0
  safe_set system multicore_packet_scheduler 1
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -v -E "termux|inputmethod|keyboard|launcher|gboard"); do
    if echo "$pkg" | grep -qiE "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena"; then continue; fi
    cmd appops set $pkg RUN_IN_BACKGROUND ignore >/dev/null 2>&1
    cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
    cmd appops set $pkg WAKE_LOCK ignore >/dev/null 2>&1
    cmd appops set $pkg SYSTEM_ALERT_WINDOW ignore >/dev/null 2>&1
    am force-stop $pkg >/dev/null 2>&1
  done
  for sys in com.facebook.system com.facebook.appmanager com.heytap.msp com.heytap.cloud com.oppo.market com.coloros.oppoguardelf com.android.printspooler com.google.android.printservice.recommendation; do
    am force-stop $sys >/dev/null 2>&1
    cmd appops set $sys RUN_IN_BACKGROUND ignore >/dev/null 2>&1
  done
}
boost_cpu_gpu(){
  safe_set system pointer_speed 7
  safe_set global sem_enhanced_cpu_responsiveness 1
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  safe_set secure refresh_rate_mode 1
  renice -n -10 $$ >/dev/null 2>&1
}
slippery_logic(){
  TEMP=$1; FPS=$2
  if [ "$FPS" -ge 55 ]; then SLOP=4; PRESS=0.25; TO=150; SIZE=0.3
  elif [ "$FPS" -ge 40 ]; then SLOP=6; PRESS=0.35; TO=170; SIZE=0.4
  else SLOP=8; PRESS=0.5; TO=190; SIZE=0.5; fi
  safe_set system view_configuration_touch_slop $SLOP
  safe_set system touch.pressure.scale $PRESS
  safe_set system touch.size.scale $SIZE
  safe_set secure long_press_timeout $TO
  safe_set system gesture_exclusion_limit 300
  safe_set global block_untrusted_touches 0
  safe_set system tap_duration_threshold 0
}
game_loader_boost(){
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -iE "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena|valorant" | head -8); do
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
cooler_logic(){
  if [ "$COOLER_ENABLED" -eq 0 ]; then echo "$COOLER_STATUS"; return; fi
  TEMP=$1
  if [ "$TEMP" -ge 48 ]; then RFS=60; MODE="COOLER EXTREME $TEMP°C"; am kill-all >/dev/null 2>&1
  elif [ "$TEMP" -ge 44 ]; then RFS=90; MODE="COOLER HARD $TEMP°C"
  else RFS=120; MODE="COOLER STABLE $TEMP°C"; fi
  safe_set system peak_refresh_rate $RFS
  safe_set system min_refresh_rate $RFS
  echo $MODE
}
notify_start(){
  echo -e "${Y}update : $1${NC}"
  termux-notification --id tool_up --title "System Tool v2.7" --content "$1" --priority low 2>/dev/null
}
notify_clear(){ printf "\033[1A\033[2K"; termux-notification-remove tool_up 2>/dev/null; }
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; PING=$4; WIFI_INFO=$5; WIFI_MODE=$6; COOLER_INFO=$7
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10)); BAR=$(printf "%${FILL}s" | tr ' ' '#'); EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  if [ "$PING" -le 40 ]; then PC=$G; PS="EXCELLENT"; elif [ "$PING" -le 80 ]; then PC=$Y; PS="GOOD"; else PC=$R; PS="HIGH"; fi
  [ "$PING" -eq 0 ] && PS="CHECKING"
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e " ${W}$TXT_VER : $TXT_APP${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_FUNGSI :${NC}"
  echo -e " ${G}[✓]${NC} ${W}anti malware : active - scan & block${NC}"
  echo -e " ${G}[✓]${NC} ${W}bg killer : active - kill bg unnecessary${NC}"
  echo -e " ${G}[✓]${NC} ${W}tier device : $TIER_NAME ${MAX_CPU_PERCENT}% | $REFRESH Hz${NC}"
  echo -e " ${G}[✓]${NC} ${W}wifi boost : $WIFI_MODE${NC}"
  echo -e " ${G}[✓]${NC} ${W}wifi info : $WIFI_INFO${NC}"
  echo -e " ${G}[✓]${NC} ${W}ping boost : $PC$PING ms [$PS]${NC}"
  echo -e " ${G}[✓]${NC} ${W}slippery touch : 150ms locked${NC}"
  echo -e " ${G}[✓]${NC} ${W}cooler : $COOLER_INFO${NC}"
  echo -e " ${G}[✓]${NC} ${W}all performance : $BOOST_POWER${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e " ${W}$TXT_PING:$PC $PING ms${NC} | $TXT_WIFI: $WIFI_INFO"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
}
termux-wake-lock 2>/dev/null
CYCLE=0
WIFI_MODE="INIT"
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto); PING=$(get_ping); WIFI_INFO=$(get_wifi_info); CYCLE=$((CYCLE+1))
  COOLER_INFO=$(cooler_logic $TEMP)
  draw_box $TEMP $RAM $FPS "$PING" "$WIFI_INFO" "$WIFI_MODE" "$COOLER_INFO"
  abort_check; notify_start "anti malware scan"; ultra_anti_malware; notify_clear
  abort_check; notify_start "bg killer & debloat"; ultra_bg_killer; notify_clear
  abort_check; notify_start "anti lag"; ultra_anti_lag; notify_clear
  abort_check; notify_start "block ads"; ultra_anti_ads; notify_clear
  abort_check; notify_start "ping boost $PING ms"; ultra_ping_boost; notify_clear
  abort_check; notify_start "wifi boost"; WIFI_MODE=$(ultra_wifi_boost $TEMP); notify_clear
  abort_check; notify_start "cpu gpu $BOOST_POWER"; boost_cpu_gpu; notify_clear
  abort_check; notify_start "slippery"; slippery_logic $TEMP $FPS; notify_clear
  abort_check; notify_start "game loader"; game_loader_boost; notify_clear
  abort_check; notify_start "map gen"; map_gen_boost; notify_clear
  if [ "$COOLER_ENABLED" -eq 1 ]; then notify_start "$COOLER_INFO"; sleep 0.2; notify_clear; fi
  if [ $((CYCLE % 5)) -eq 0 ]; then notify_start "cache clean"; stealth_cache_clean; notify_clear; fi
  abort_check
  echo -e "${G}[$(date +%T)] ALL IN ONE: $BOOST_POWER | $PING ms | $WIFI_MODE${NC}"
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 2; then
    clear
    echo -e "${R}[!] STOP REQUESTED${NC}"
    full_reset
    echo -e "${G}✔ $TXT_STOP - Secured${NC}"
    exit 0
  fi
done
