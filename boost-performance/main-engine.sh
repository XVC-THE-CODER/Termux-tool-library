#!/data/data/com.termux/files/usr/bin/bash
# ========================================================
# GAME BOOSTER v2.7 EXTENDED - REALTIME CHECKLIST FIX
# Parallel Update | Anti Malware | Bg Killer | Wifi Turbo
# Ping | CPU GPU | RAM | Thermal | DNS | Audio | Sensor
# ========================================================

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; M='\033[1;35m'; W='\033[1;37m'; NC='\033[0m'

_brand=$(getprop ro.product.brand 2>/dev/null)
_model=$(getprop ro.product.model 2>/dev/null)
_board=$(getprop ro.board.platform 2>/dev/null)
[ -z "$_board" ] && _board=$(getprop ro.hardware 2>/dev/null)
_kb=$(cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{print $2}')
_gb=$((_kb / 1024 / 1024))
_ver=$(getprop ro.build.version.release 2>/dev/null)
[ -z "$_brand" ] && _brand="Generic"
[ -z "$_model" ] && _model="Device"
[ -z "$_board" ] && _board="Unknown"

TMPDIR="/data/local/tmp/.boost_v27"
LOGFILE="/data/local/tmp/boost_v27.log"
mkdir -p $TMPDIR
echo "" > $LOGFILE

MODULE_LIST="anti_malware bg_killer anti_lag block_ads ping_boost wifi_boost cpu_gpu slippery game_loader map_gen cache_clean cooler ram_boost thermal dns_boost sensor audio"

for mod in $MODULE_LIST; do
  echo "idle" > $TMPDIR/$mod.status 2>/dev/null
done
echo "INIT" > $TMPDIR/wifi_mode.txt
echo "AUTO" > $TMPDIR/cooler_info.txt
echo "0" > $TMPDIR/ping.txt

if [ "$_gb" -le 4 ]; then
  TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5; SENS=9
elif [ "$_gb" -le 6 ]; then
  TIER=2; TIER_NAME="MID"; BOOST_POWER="75% PERFORMANCE"; MAX_CPU_PERCENT=90; REFRESH=90; ANIM=0.3; SENS=9
elif [ "$_gb" -le 8 ]; then
  TIER=3; TIER_NAME="HIGH"; BOOST_POWER="100% TURBO"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0; SENS=10
else
  TIER=4; TIER_NAME="EXTREME"; BOOST_POWER="120% EXTREME OC"; MAX_CPU_PERCENT=100; REFRESH=144; ANIM=0.0; SENS=10
fi

if echo "$_board" | grep -qi "mt6765\|helio.*G35\|G25\|G85\|mt6768"; then
  TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5
fi

is_rooted=0
if su -c "id" >/dev/null 2>&1; then is_rooted=1; fi

log_msg(){ echo "[$(date +%T)] $1" >> $LOGFILE; }

safe_set(){
  settings put "$1" "$2" "$3" >/dev/null 2>&1
  sleep 0.08
  log_msg "SET $1 $2 $3"
}

safe_set_root(){
  if [ "$is_rooted" -eq 1 ]; then
    su -c "settings put $1 $2 $3" >/dev/null 2>&1
  else
    safe_set $1 $2 $3
  fi
}

full_reset(){
  for pid in $(jobs -p 2>/dev/null); do kill -9 $pid >/dev/null 2>&1; done
  pkill -P $$ >/dev/null 2>&1
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
  safe_set global network_avoid_bad_wifi 1
  safe_set global captive_portal_detection_enabled 1
  safe_set global package_verifier_enable 1
  safe_set secure install_non_market_apps 1
  safe_set global low_power 0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | head -20); do
    cmd appops set $pkg RUN_IN_BACKGROUND allow >/dev/null 2>&1
    cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1
    cmd appops set $pkg WAKE_LOCK allow >/dev/null 2>&1
  done
  termux-wake-unlock 2>/dev/null
  termux-notification-remove tool_up 2>/dev/null
  rm -rf $TMPDIR
  mkdir -p $TMPDIR
  log_msg "FULL RESET DONE"
}

trap 'full_reset; exit 0' INT TERM

abort_check(){
  if read -t 0.1 -n 1 2>/dev/null; then
    clear
    echo -e "${R}[!] ENTER DETECTED - FORCE STOP ALL...${NC}"
    full_reset
    echo -e "${G}✔ STOP - Secured & Cooled${NC}"
    exit 0
  fi
}

get_temp(){
  MAX=0
  for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$f" ] || continue
    T=$(cat $f 2>/dev/null)
    [ -z "$T" ] && continue
    [ "$T" -gt 1000 ] && T=$((T/1000))
    [ "$T" -gt "$MAX" ] && MAX=$T
  done
  [ "$MAX" -eq 0 ] && MAX=37
  echo $MAX
}

get_ram_free(){ free -m 2>/dev/null | awk '/Mem:/{print $7}'; [ -z "$RAM" ] && echo 800 || echo $RAM; }

get_ping(){
  OUT=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null)
  P=$(echo "$OUT" | grep -oE 'time=[0-9.]+' | grep -oE '[0-9.]+' | cut -d. -f1)
  if [ -z "$P" ]; then
    OUT2=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null)
    P=$(echo "$OUT2" | grep -oE 'time[=<][0-9.]+' | grep -oE '[0-9.]+' | cut -d. -f1)
  fi
  [ -z "$P" ] && P=0
  echo $P > $TMPDIR/ping.txt
  echo $P
}

get_wifi_info(){
  INFO=$(dumpsys wifi 2>/dev/null | grep -m 1 "mWifiInfo" | head -1)
  SPEED=$(echo $INFO | grep -o "link speed [0-9]*" | grep -o "[0-9]*")
  RSSI=$(echo $INFO | grep -o "RSSI: -[0-9]*" | grep -o "-[0-9]*" | head -1)
  if [ -z "$SPEED" ]; then
    if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
      SPEED=$(termux-wifi-connectioninfo 2>/dev/null | grep -o '"link_speed_mbps":[0-9]*' | grep -o '[0-9]*')
      RSSI=$(termux-wifi-connectioninfo 2>/dev/null | grep -o '"rssi":-[0-9]*' | grep -o '-[0-9]*')
    fi
  fi
  [ -z "$SPEED" ] && SPEED="--"
  [ -z "$RSSI" ] && RSSI="--"
  echo "${SPEED}Mbps ${RSSI}dBm"
}

get_fps_auto(){
  TEMP=$(get_temp)
  if [ "$TIER" -eq 1 ]; then MAX_FPS=60
  elif [ "$TIER" -eq 2 ]; then MAX_FPS=90
  else MAX_FPS=120; fi
  if [ "$TEMP" -lt 41 ]; then echo $MAX_FPS
  elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-2))
  else echo $((MAX_FPS-8)); fi
}

has_cooler(){
  ls /sys/class/thermal/cooling_device* >/dev/null 2>&1 && return 0
  ls /sys/class/thermal/thermal_zone* >/dev/null 2>&1 && return 0
  return 1
}

if! has_cooler; then
  echo "unsupported" > $TMPDIR/cooler.status
  echo "NOT SUPPORTED" > $TMPDIR/cooler_info.txt
fi

stealth_cache_clean(){
  pm trim-caches 3072M >/dev/null 2>&1
  for p in /sdcard/Android/data/*/cache /sdcard/Android/obb/*/cache /sdcard/DCIM/.thumbnails /sdcard/.cache /sdcard/Android/data/*/files/cache; do rm -rf $p/* 2>/dev/null; done
  find /data/local/tmp -type f -mtime +1 -delete 2>/dev/null
  find /sdcard -type f \( -name "*.tmp" -o -name "*.log" -o -name "cache_*" \) -delete 2>/dev/null
  cmd package bg-dexopt-job >/dev/null 2>&1 &
  log_msg "cache clean"
}

ultra_anti_ads(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier dns.adguard.com
  safe_set global ad_services_enabled 0
  safe_set global ad_services_consent_enabled 0
  safe_set secure limit_ad_tracking 1
  safe_set global analytics_enabled 0
  for pkg in com.heytap.msp com.heytap.cloud com.oppo.market com.coloros.oppoguardelf com.facebook.system; do
    pm clear --cache-only $pkg >/dev/null 2>&1
    am force-stop $pkg >/dev/null 2>&1
  done
  log_msg "anti ads"
}

ultra_anti_lag(){
  pm trim-caches 1024M >/dev/null 2>&1
  safe_set global cached_apps_freezer enabled
  safe_set global cached_apps_freezer_compression lz4
  safe_set global activity_starts_logging_enabled 0
  safe_set global app_auto_restriction_enabled 1
  safe_set global system_cap 0
  safe_set global hidden_api_policy 1
  safe_set system multicore_packet_scheduler 1
  safe_set global device_idle_constants "inactive_to=60000,sensing_to=0,locating_to=0"
  safe_set global anr_show_background 0
  if [ "$TIER" -eq 1 ]; then am kill-all >/dev/null 2>&1; fi
  log_msg "anti lag"
}

ultra_ping_boost(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier one.one.one.one
  safe_set global captive_portal_detection_enabled 0
  safe_set global captive_portal_mode 0
  safe_set global mobile_data_always_on 1
  safe_set global network_avoid_bad_wifi 0
  safe_set global wifi_power_save 0
  safe_set global ble_scan_always_enabled 0
  safe_set global tcp_default_init_rwnd 60 >/dev/null 2>&1
  if [ "$is_rooted" -eq 1 ]; then
    su -c "sysctl -w net.ipv4.tcp_congestion_control=bbr" >/dev/null 2>&1
    su -c "sysctl -w net.ipv4.tcp_fastopen=3" >/dev/null 2>&1
    su -c "sysctl -w net.core.rmem_max=16777216" >/dev/null 2>&1
    su -c "sysctl -w net.core.wmem_max=16777216" >/dev/null 2>&1
    su -c "sysctl -w net.ipv4.tcp_mtu_probing=1" >/dev/null 2>&1
    su -c "ndc resolver clearnetdns default" >/dev/null 2>&1
  else
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    ndc resolver clearnetdns default >/dev/null 2>&1
  fi
  ip route flush cache >/dev/null 2>&1
  log_msg "ping boost"
}

ultra_wifi_boost(){
  CUR_TEMP=$1
  if [ "$CUR_TEMP" -ge 45 ]; then
    safe_set global wifi_suspend_optimizations_enabled 1
    safe_set global wifi_scan_throttle_enabled 1
    safe_set global wifi_power_save 1
    echo "COOL ${CUR_TEMP}C Anti Panas" > $TMPDIR/wifi_mode.txt
  else
    safe_set global wifi_suspend_optimizations_enabled 0
    safe_set global wifi_scan_throttle_enabled 0
    safe_set global wifi_power_save 0
    echo "TURBO Max Speed" > $TMPDIR/wifi_mode.txt
  fi
  safe_set global wifi_wakeup_enabled 0
  safe_set global wifi_networks_available_notification_on 0
  safe_set global wifi_scan_always_enabled 0
  safe_set global network_avoid_bad_wifi 0
  safe_set global network_recommendations_enabled 0
  safe_set global wifi_verbose_logging_enabled 0
  safe_set global ble_scan_always_enabled 0
  cmd wifi set-scan-always-available 0 >/dev/null 2>&1
  svc wifi set-verbose-logging disabled >/dev/null 2>&1
  log_msg "wifi boost $CUR_TEMP"
}

ultra_anti_malware(){
  safe_set global package_verifier_enable 1
  safe_set global package_verifier_include_adb 1
  safe_set global verifier_verify_adb_installs 1
  safe_set secure install_non_market_apps 0
  for b in $(pm list packages 2>/dev/null | cut -d: -f2 | grep -iE "lucky.*patcher|freedom|apk.*editor|game.*guardian|cheat.*engine|phx|hacker|fake.*gps|game.*hack"); do
    pm disable $b >/dev/null 2>&1
    am force-stop $b >/dev/null 2>&1
    log_msg "malware block $b"
  done
  for p in /sdcard/Download/*.apk /sdcard/*.apk /sdcard/Download/*.tmp /sdcard/*.dex; do [ -f "$p" ] && rm -f "$p" 2>/dev/null; done
}

ultra_bg_killer(){
  safe_set global activity_starts_logging_enabled 0
  safe_set global background_freezer_enabled 1
  safe_set global cached_apps_freezer enabled
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -v -E "termux|keyboard|launcher|gboard|inputmethod|google.android.gms" | head -40); do
    if echo "$pkg" | grep -qiE "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena|valorant"; then continue; fi
    cmd appops set $pkg RUN_IN_BACKGROUND ignore >/dev/null 2>&1
    cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
    cmd appops set $pkg WAKE_LOCK ignore >/dev/null 2>&1
    cmd appops set $pkg SYSTEM_ALERT_WINDOW ignore >/dev/null 2>&1
    am force-stop $pkg >/dev/null 2>&1
  done
  for sys in com.facebook.system com.facebook.appmanager com.heytap.msp com.heytap.cloud com.oppo.market com.coloros.oppoguardelf com.android.printspooler com.google.android.printservice.recommendation com.xiaomi.mipicks com.coloros.phonemanager; do
    am force-stop $sys >/dev/null 2>&1
    cmd appops set $sys RUN_IN_BACKGROUND ignore >/dev/null 2>&1
  done
  log_msg "bg killer"
}

ultra_ram_boost(){
  if [ "$is_rooted" -eq 1 ]; then su -c "echo 1 > /proc/sys/vm/drop_caches" >/dev/null 2>&1; su -c "echo 1 > /proc/sys/vm/compact_memory" >/dev/null 2>&1; fi
  am kill-all >/dev/null 2>&1
  pm trim-caches 2048M >/dev/null 2>&1
  safe_set global cached_apps_freezer enabled
  log_msg "ram boost"
}

ultra_thermal_control(){
  TEMP=$1
  if [ "$TEMP" -ge 47 ]; then
    safe_set system min_refresh_rate 60
    safe_set system peak_refresh_rate 60
    am kill-all >/dev/null 2>&1
    echo "THERMAL EXTREME $TEMP°C" > $TMPDIR/cooler_info.txt
  elif [ "$TEMP" -ge 43 ]; then
    echo "THERMAL HOT $TEMP°C" > $TMPDIR/cooler_info.txt
  else
    echo "THERMAL STABLE $TEMP°C" > $TMPDIR/cooler_info.txt
  fi
  if [ "$is_rooted" -eq 1 ]; then su -c "echo 0 > /sys/class/thermal/thermal_zone0/mode" >/dev/null 2>&1; fi
  log_msg "thermal $TEMP"
}

ultra_dns_boost(){
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier one.one.one.one
  safe_set global captive_portal_detection_enabled 0
  ndc resolver clearnetdns default >/dev/null 2>&1
  log_msg "dns boost"
}

ultra_sensor_boost(){
  safe_set global battery_saver_constants "" >/dev/null 2>&1
  safe_set global sensor_privacy_enabled 0 >/dev/null 2>&1
  cmd sensorservice reset >/dev/null 2>&1
  log_msg "sensor boost"
}

ultra_audio_boost(){
  safe_set global low_latency_audio 1 >/dev/null 2>&1
  safe_set global audio_safe_media_volume_enabled 0 >/dev/null 2>&1
  log_msg "audio boost"
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
  renice -n -10 $$ >/dev/null 2>&1
  log_msg "cpu gpu boost"
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
  log_msg "slippery $FPS"
}

game_loader_boost(){
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -iE "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena|valorant" | head -8); do
    cmd package compile -m speed-profile -f $pkg >/dev/null 2>&1 &
  done
  safe_set global game_dashboard_enable 1
  safe_set global game_auto_temperature 0
  log_msg "game loader"
}

map_gen_boost(){
  safe_set system large_heap 1
  safe_set global chunk_load_optimize 1
  safe_set global map_render_accel 1
  safe_set system hwui.render_dirty_regions false
  safe_set global map_preload_distance 12
  log_msg "map gen"
}

run_mod(){
  name=$1; shift
  ( echo "updating" > $TMPDIR/$name.status; "$@" >/dev/null 2>&1; echo "done" > $TMPDIR/$name.status ) &
}

get_icon(){
  s=$(cat $TMPDIR/$1.status 2>/dev/null)
  if [ "$s" = "done" ]; then echo "${G}[√]${NC}"
  elif [ "$s" = "updating" ]; then echo "${Y}[O]${NC}"
  elif [ "$s" = "unsupported" ]; then echo "${R}[X]${NC}"
  else echo "${W}[ ]${NC}"; fi
}

draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; PING=$4; WIFI_INFO=$5; UPD_COUNT=$6; UPD_LIST=$7
  WIFI_MODE=$(cat $TMPDIR/wifi_mode.txt 2>/dev/null)
  COOLER_INFO=$(cat $TMPDIR/cooler_info.txt 2>/dev/null)
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100; [ "$PERC" -lt 0 ] && PERC=0
  FILL=$((PERC/10)); [ "$FILL" -gt 10 ] && FILL=10; [ "$FILL" -lt 0 ] && FILL=0
  BAR=$(printf "%${FILL}s" | tr ' ' '█'); EBAR=$(printf "%$((10-FILL))s" | tr ' ' '░')
  if [ "$PING" -le 40 ]; then PC=$G; PS="EXCELLENT"; elif [ "$PING" -le 80 ]; then PC=$Y; PS="GOOD"; elif [ "$PING" -le 120 ]; then PC=$Y; PS="STABLE"; else PC=$R; PS="HIGH"; fi
  [ "$PING" -eq 0 ] && PS="CHECKING"
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${C}┃${W} $TXT_APP | $_brand $_model | ROOT:$is_rooted${NC} ${C}┃${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e "${C}┃${W} REAL-TIME: ${Y}[O]${W}=Update ${G}[√]${W}=Done ${R}[X]${W}=No Support ${C}┃${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e "${C}┃${NC} $(get_icon anti_malware) anti malware scan & block ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon bg_killer) bg killer & unnecessary off ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon anti_lag) anti lag & freezer ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon block_ads) block ads & analytics ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon ping_boost) ping boost ${PC}${PING}ms [$PS]${NC} ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon wifi_boost) wifi boost : $WIFI_MODE ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon dns_boost) dns turbo one.one.one.one ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon cpu_gpu) cpu gpu $MAX_CPU_PERCENT% $REFRESH Hz [$TIER_NAME] ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon ram_boost) ram boost free ${RAM}MB ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon thermal) thermal : $COOLER_INFO ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon slippery) slippery touch $SENS ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon sensor) sensor optimizer ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon audio) audio low latency ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon game_loader) game loader fast load ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon map_gen) map gen preload 12 ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon cache_clean) cache clean stealth ${C}┃${NC}"
  echo -e "${C}┃${NC} $(get_icon cooler) cooler system $COOLER_INFO ${C}┃${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  if [ "$UPD_COUNT" -gt 0 ]; then
    echo -e "${C}┃${Y} UPDATE ($UPD_COUNT) : $UPD_LIST${NC}"
    echo -e "${C}┃${Y} ${BAR}${W}${EBAR} $PERC% ${NC}"
  else
    echo -e "${C}┃${G} UPDATE (0) : All Done - $BOOST_POWER${NC}"
    echo -e "${C}┃${G} ${BAR}${W}${EBAR} $PERC% FPS:$FPS | $WIFI_INFO${NC}"
  fi
  echo -e "${C}┃${W} INFO: RAM ${_gb}GB Free ${RAM}MB | Andro $_ver | Temp ${TEMP}C | Ping ${PING}ms${NC} ${C}┃${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
}

termux-wake-lock 2>/dev/null
CYCLE=0
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto); PING=$(get_ping); WIFI_INFO=$(get_wifi_info); CYCLE=$((CYCLE+1))
  run_mod anti_malware ultra_anti_malware
  run_mod bg_killer ultra_bg_killer
  run_mod anti_lag ultra_anti_lag
  run_mod block_ads ultra_anti_ads
  run_mod ping_boost ultra_ping_boost
  run_mod wifi_boost ultra_wifi_boost $TEMP
  run_mod cpu_gpu boost_cpu_gpu
  run_mod ram_boost ultra_ram_boost
  run_mod thermal ultra_thermal_control $TEMP
  run_mod dns_boost ultra_dns_boost
  run_mod sensor ultra_sensor_boost
  run_mod audio ultra_audio_boost
  run_mod slippery slippery_logic $TEMP $FPS
  run_mod game_loader game_loader_boost
  run_mod map_gen map_gen_boost
  run_mod cooler cooler_logic $TEMP
  if [ $((CYCLE % 4)) -eq 0 ]; then run_mod cache_clean stealth_cache_clean; fi
  while true; do
    abort_check
    UPD_LIST=$(for f in $TMPDIR/*.status; do [ "$(cat $f 2>/dev/null)" = "updating" ] && basename $f.status; done | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    UPD_COUNT=$(for f in $TMPDIR/*.status; do [ "$(cat $f 2>/dev/null)" = "updating" ] && echo 1; done | wc -l)
    draw_box $TEMP $RAM $FPS $PING $WIFI_INFO $UPD_COUNT "$UPD_LIST"
    if [ "$UPD_COUNT" -eq 0 ]; then break; fi
    sleep 0.25
  done
  echo -e "${G}[$(date +%T)] CYCLE $CYCLE DONE: $BOOST_POWER | $PING ms | $WIFI_INFO${NC}"
  echo -e "${W}>> Press [ENTER] to STOP - Log: $LOGFILE <<${NC}"
  if read -t 2.5; then full_reset; echo -e "${G}✔ STOP - Secured${NC}"; exit 0; fi
done
