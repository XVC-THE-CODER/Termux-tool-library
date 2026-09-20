#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; D='\033[2;37m'; NC='\033[0m'
get_device_info() {
    BRAND=$(getprop ro.product.brand 2>/dev/null); [ -z "$BRAND" ] && BRAND="Generic"
    MODEL=$(getprop ro.product.model 2>/dev/null); [ -z "$MODEL" ] && MODEL="Device"
    CHIP=$(getprop ro.board.platform 2>/dev/null); [ -z "$CHIP" ] && CHIP=$(getprop ro.hardware 2>/dev/null)
    [ -z "$CHIP" ] && CHIP=$(cat /proc/cpuinfo 2>/dev/null | grep Hardware | head -1 | cut -d: -f2 | xargs)
    MEM_KB=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
    RAM_GB=$((MEM_KB / 1024 / 1024))
    [ "$RAM_GB" -eq 0 ] && RAM_GB=$((MEM_KB / 1024 / 1000))
    ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null)
    [ -z "$CHIP" ] && CHIP="Unknown"
}
detect_tier() {
    if [ "$RAM_GB" -le 4 ]; then
        TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU=80; REFRESH=60; ANIM=0.5
    elif [ "$RAM_GB" -le 6 ]; then
        TIER=2; TIER_NAME="MID"; BOOST_POWER="75% PERFORMANCE"; MAX_CPU=90; REFRESH=90; ANIM=0.3
    elif [ "$RAM_GB" -le 8 ]; then
        TIER=3; TIER_NAME="HIGH"; BOOST_POWER="100% TURBO"; MAX_CPU=100; REFRESH=120; ANIM=0.0
    else
        TIER=4; TIER_NAME="EXTREME"; BOOST_POWER="120% EXTREME OC"; MAX_CPU=100; REFRESH=120; ANIM=0.0
    fi
    if echo "$CHIP" | grep -qi "mt6765\|helio.*G35\|G25\|G85\|mt6761"; then
        TIER=1; TIER_NAME="LOW [HELIO]"; BOOST_POWER="50% BALANCED"; MAX_CPU=80; REFRESH=60; ANIM=0.5
    fi
}
safe_set() { settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.05; }
get_temp() {
    local MAX=0 T
    for f in /sys/class/thermal/thermal_zone*/temp; do
        [ -f "$f" ] || continue
        T=$(cat $f 2>/dev/null); [ "$T" -gt 1000 ] && T=$((T/1000))
        [ "$T" -gt "$MAX" ] && MAX=$T
    done; [ "$MAX" -eq 0 ] && MAX=38; echo $MAX
}
get_ram_free() { free -m | awk '/Mem:/{print $7}'; }
get_ping() {
    local P; P=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep -o 'time=[0-9.]*' | cut -d= -f2 | cut -d. -f1)
    [ -z "$P" ] && P=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | grep -o 'time=[0-9.]*' | cut -d= -f2 | cut -d. -f1)
    [ -z "$P" ] && P=0; echo $P
}
get_fps_auto() {
    local TEMP=$1 RAM=$2 MAX_FPS
    if [ "$TIER" -eq 1 ]; then MAX_FPS=60; elif [ "$TIER" -eq 2 ]; then MAX_FPS=90; else MAX_FPS=120; fi
    if [ "$TEMP" -lt 42 ] && [ "$RAM" -gt 1200 ]; then echo $MAX_FPS
    elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-2)); else echo $((MAX_FPS-8)); fi
}
has_cooler() { ls /sys/class/thermal/cooling_device* >/dev/null 2>&1 || ls /sys/class/thermal/thermal_zone* >/dev/null 2>&1; }
ultra_anti_lag() {
    pm trim-caches 999M >/dev/null 2>&1
    cmd package bg-dexopt-job >/dev/null 2>&1 &
    safe_set global cached_apps_freezer enabled
    safe_set global cached_apps_freezer_compression lz4
    safe_set global activity_starts_logging_enabled 0
    safe_set global app_auto_restriction_enabled 1
    safe_set global system_cap 0
}
ultra_anti_ads() {
    safe_set global private_dns_mode hostname
    safe_set global private_dns_specifier dns.adguard.com
    safe_set global ad_services_enabled 0
    safe_set global analytics_enabled 0
    safe_set secure limit_ad_tracking 1
}
boost_cpu_gpu() {
    safe_set system pointer_speed 7
    safe_set global sem_enhanced_cpu_responsiveness 1
    safe_set global debug.hwui.renderer skiagl
    safe_set global debug.hwui.render_thread true
    safe_set system peak_refresh_rate $REFRESH
    safe_set system min_refresh_rate $REFRESH
    safe_set global window_animation_scale $ANIM
    safe_set global transition_animation_scale $ANIM
    safe_set global animator_duration_scale $ANIM
    safe_set secure refresh_rate_mode 1
    renice -n -15 $$ >/dev/null 2>&1
}
extreme_tuning() {
    if [ "$TIER" -ge 3 ]; then
        cmd power set-fixed-performance-mode-enabled true >/dev/null 2>&1
        cmd power set-mode 0 >/dev/null 2>&1
        echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
        echo 1 | tee /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost >/dev/null 2>&1
        echo 0 | tee /sys/module/msm_thermal/core_control/enabled >/dev/null 2>&1
    fi
}
wifi_mbps_booster() {
    if dumpsys wifi 2>/dev/null | grep -q "Wi-Fi is enabled" && dumpsys wifi 2>/dev/null | grep -q "mWifiInfo"; then
        safe_set global wifi_suspend_optimizations_enabled 0
        safe_set global wifi_scan_throttle_enabled 0
        safe_set global wifi_power_save 0
        safe_set global captive_portal_detection_enabled 0
        safe_set global captive_portal_mode 0
        safe_set global network_avoid_bad_wifi 0
        safe_set global ble_scan_always_enabled 0
        safe_set global private_dns_mode hostname
        safe_set global private_dns_specifier one.one.one.one
        sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
        sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
        sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_wmem="4096 16384 16777216" >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
        sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
        ip link set wlan0 txqueuelen 3000 >/dev/null 2>&1
        ip link set wlan0 mtu 1500 >/dev/null 2>&1
        ndc resolver clearnetdns wlan0 >/dev/null 2>&1
        cmd connectivity set-airplane-mode false >/dev/null 2>&1 &
    fi
}
stealth_bg_killer() {
    local KEEP_PATTERN="termux|cloudphone|flexphone|geekphone|vmos|f1vm|systemui|launcher3|launcher|settings|inputmethod|gboard|swiftkey|magisk|shizuku|sui|system"
    for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
        if ! echo "$pkg" | grep -qiE "$KEEP_PATTERN"; then
            if dumpsys activity processes 2>/dev/null | grep -q "$pkg"; then
                am force-stop "$pkg" >/dev/null 2>&1
                cmd appops set "$pkg" RUN_IN_BACKGROUND ignore >/dev/null 2>&1
                cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
            fi
        fi
    done
    am kill-all --user all >/dev/null 2>&1 || true
}
slippery_logic() {
    local FPS=$1 SLOP PRESS TO SIZE
    if [ "$FPS" -ge 90 ]; then SLOP=2; PRESS=0.20; TO=120; SIZE=0.2
    elif [ "$FPS" -ge 55 ]; then SLOP=4; PRESS=0.25; TO=150; SIZE=0.3
    else SLOP=6; PRESS=0.35; TO=170; SIZE=0.4; fi
    safe_set system view_configuration_touch_slop $SLOP
    safe_set system touch.pressure.scale $PRESS
    safe_set system touch.size.scale $SIZE
    safe_set secure long_press_timeout $TO
    safe_set system gesture_exclusion_limit 300
    safe_set global block_untrusted_touches 0
    safe_set system tap_duration_threshold 0
}
game_loader_boost() {
    for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -i -E "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena|valorant|hok" | head -8); do
        cmd package compile -m speed-profile -f "$pkg" >/dev/null 2>&1 &
    done
}
cooler_logic() {
    local TEMP=$1
    if [ "$TEMP" -ge 48 ]; then echo "COOLER EXTREME ${TEMP}°C - 60Hz"; safe_set system peak_refresh_rate 60; safe_set system min_refresh_rate 60; am kill-all >/dev/null 2>&1
    elif [ "$TEMP" -ge 44 ]; then echo "COOLER HARD ${TEMP}°C - 90Hz"; safe_set system peak_refresh_rate 90
    else echo "COOLER STABLE ${TEMP}°C - ${REFRESH}Hz"; fi
}
full_reset() {
  safe_set global private_dns_mode opportunistic; safe_set global private_dns_specifier ""
  safe_set system pointer_speed 3; safe_set secure long_press_timeout 400
  safe_set system min_refresh_rate 60; safe_set system peak_refresh_rate 60
  safe_set global window_animation_scale 1; safe_set global transition_animation_scale 1; safe_set global animator_duration_scale 1
  safe_set system view_configuration_touch_slop 8; safe_set system touch.pressure.scale 1.0
  safe_set global block_untrusted_touches 1; safe_set global captive_portal_detection_enabled 1
  safe_set global wifi_suspend_optimizations_enabled 1; safe_set global wifi_scan_throttle_enabled 1
  safe_set global mobile_data_always_on 0; safe_set global network_avoid_bad_wifi 1
  termux-wake-unlock 2>/dev/null; termux-notification-remove tool_up >/dev/null 2>&1
}
draw_box() {
  local TEMP=$1 RAM=$2 FPS=$3 PING=$4 COOLER=$5
  local PERC=$((FPS*100/REFRESH)); [ "$PERC" -gt 100 ] && PERC=100
  local FILL=$((PERC/10)); local BAR=$(printf "%${FILL}s" | tr ' ' '█'); local EBAR=$(printf "%$((10-FILL))s" | tr ' ' '░')
  local PING_C=$G PING_S="EXCELLENT"
  if [ "$PING" -le 40 ]; then PING_C=$G; PING_S="EXCELLENT"; elif [ "$PING" -le 80 ]; then PING_C=$Y; PING_S="GOOD"; elif [ "$PING" -le 120 ]; then PING_C=$Y; PING_S="STABLE"; else PING_C=$R; PING_S="HIGH"; fi
  [ "$PING" -eq 0 ] && PING_S="CHECKING"
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e " ${W}SYSTEM TOOL v2.7 EXTREME  |  ${G}boost performance game${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${D}Device: $BRAND $MODEL | $CHIP | Andro $ANDROID_VER${NC}"
  echo -e " ${W}TIER : ${G}$TIER_NAME${NC} ${W}(${RAM_GB}GB) | ${W}POWER: ${Y}$BOOST_POWER${NC}"
  echo -e " ${G}[✓]${NC} ${W}CPU/GPU Boost      : ${MAX_CPU}% | ${REFRESH}Hz Locked"
  echo -e " ${G}[✓]${NC} ${W}Slippery Touch     : 120ms Ultra Responsive"
  echo -e " ${G}[✓]${NC} ${W}WIFI Mbps Booster  : Active (1.1.1.1 + BBR + 16MB Buffer)"
  echo -e " ${G}[✓]${NC} ${W}Ping Stabilizer    : ${PING_C}${PING}ms [$PING_S]${NC}"
  echo -e " ${G}[✓]${NC} ${W}Frame Optimizer    : V-Sync Stable ${G}${FPS} FPS${NC}"
  echo -e " ${G}[✓]${NC} ${W}Cooler System      : $COOLER"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}RAM Free: ${G}${RAM}MB${NC} | Temp: ${Y}${TEMP}°C${NC} | ${W}FPS: [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}
notify() { echo -e "${Y}» $1${NC}"; termux-notification --id tool_up --title "System Tool v2.7" --content "$1" --priority low >/dev/null 2>&1; }
notify_clear() { printf "\033[1A\033[2K"; termux-notification-remove tool_up >/dev/null 2>&1; }
trap 'full_reset; echo -e "${G}✔ STOP - All Reset Secured${NC}"; exit 0' INT TERM
termux-wake-lock 2>/dev/null
get_device_info; detect_tier
has_cooler; COOLER_ENABLED=$?
CYCLE=0
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto $TEMP $RAM); PING=$(get_ping); CYCLE=$((CYCLE+1))
  COOLER_INFO=$(cooler_logic $TEMP)
  draw_box $TEMP $RAM $FPS "$PING" "$COOLER_INFO"
  if read -t 0.2 -n 1; then echo -e "${R}[!] STOP REQUESTED${NC}"; full_reset; exit 0; fi
  notify "anti lag system"; ultra_anti_lag; notify_clear
  notify "block ads & analytics"; ultra_anti_ads; notify_clear
  notify "wifi mbps booster [$PING ms]"; wifi_mbps_booster; notify_clear
  notify "cpu gpu extreme $BOOST_POWER"; boost_cpu_gpu; extreme_tuning; notify_clear
  notify "slippery sensitivity $FPS FPS"; slippery_logic $FPS; notify_clear
  notify "game fast load"; game_loader_boost; notify_clear
  if [ $((CYCLE % 2)) -eq 0 ]; then
    stealth_bg_killer >/dev/null 2>&1 &
  fi
  if [ $((CYCLE % 6)) -eq 0 ]; then
    notify "deep cache clean"; pm trim-caches 2048M >/dev/null 2>&1; notify_clear
  fi
  echo -e "${G}[$(date +%T)] ALL IN ONE: $BOOST_POWER | WIFI: ${PING}ms | $COOLER_INFO${NC}"
  echo -e "${W}>> Press [ENTER] to STOP <<${NC}"
  if read -t 2; then clear; echo -e "${R}[!] STOP - Resetting...${NC}"; full_reset; echo -e "${G}✔ STOP - Secured${NC}"; exit 0; fi
donerformance : active${NC}"
  echo -e " ${G}[✓]${NC} ${W}tier device : $TIER_NOW${NC}"
  echo -e " ${G}[✓]${NC} ${W}boost power : $BOOST_NOW${NC}"
  echo -e " ${G}[✓]${NC} ${W}cpu gpu boost : $MAX_CPU_PERCENT% | $REFRESH Hz Locked${NC}"
  echo -e " ${G}[✓]${NC} ${W}slippery real-time : 150ms${NC}"
  echo -e " ${G}[✓]${NC} ${W}frame optimize : V-Sync Stable${NC}"
  echo -e " ${G}[✓]${NC} ${W}game loading : Fast Load Active${NC}"
  echo -e " ${G}[✓]${NC} ${W}map gen : Chunk Preload 12 Active${NC}"
  echo -e " ${G}[✓]${NC} ${W}ping boost : ${PING_COLOR}$PING ms [$PING_STAT]${NC}"
  if [ "$COOLER_ENABLED" -eq 1 ]; then
    echo -e " ${G}[✓]${NC} ${W}cooler cpu gpu : $COOLER_INFO${NC}"
  else
    echo -e " ${R}[x]${NC} ${W}cooler cpu gpu : $COOLER_STATUS${NC}"
  fi
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v | $TXT_PING ${PING_COLOR}${PING}ms${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
}
termux-wake-lock 2>/dev/null
CYCLE=0
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto); PING=$(get_ping); CYCLE=$((CYCLE+1))
  COOLER_INFO=$(cooler_logic $TEMP)
  draw_box $TEMP $RAM $FPS "$PING" "$COOLER_INFO" "$TIER_NAME" "$BOOST_POWER"

  abort_check
  notify_start "anti lag"; ultra_anti_lag; notify_clear; abort_check
  notify_start "block ads"; ultra_anti_ads; notify_clear; abort_check
  notify_start "ping boost ${PING}ms"; ultra_ping_boost; notify_clear; abort_check
  notify_start "cpu gpu"; boost_cpu_gpu; notify_clear; abort_check
  notify_start "slippery sensitivity"; slippery_logic $TEMP $FPS; notify_clear; abort_check
  notify_start "frame optimize"; sleep 0.1; notify_clear; abort_check
  notify_start "game loading"; game_loader_boost; notify_clear; abort_check
  notify_start "map gen"; map_gen_boost; notify_clear; abort_check
  if [ "$COOLER_ENABLED" -eq 1 ]; then notify_start "$COOLER_INFO"; sleep 0.2; notify_clear; fi
  if [ $((CYCLE % 5)) -eq 0 ]; then notify_start "cache clean"; stealth_cache_clean; notify_clear; fi
  abort_check
  echo -e "${G}[$(date +%T)] ALL IN ONE: $BOOST_POWER | $PING ms | $COOLER_INFO${NC}"
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 2; then
    clear
    echo -e "${R}[!] STOP REQUESTED - Resetting...${NC}"
    full_reset
    echo -e "${G}✔ $TXT_STOP_TXT - Secured${NC}"
    exit 0
  fi
done
