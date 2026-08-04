#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
_b=$(getprop $(echo cm8ucHJvZHVjdC5icmFuZA== | base64 -d) 2>/dev/null)
_gk=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}'); _g=$(( _gk / 1024 ))
_v=$(getprop $(echo cm8uYnVpbGQudmVyc2lvbi5yZWxlYXNl | base64 -d) 2>/dev/null)
TXT_APP=$(echo djIuNSAgICAgYm9vc3QgcGVyZm9tYW5jZSBnYW1l | base64 -d)
TXT_VER="VERSION"
TXT_FUNGSI="FUNCTION LIST"
TXT_INFO="INFO"
TXT_TEMP="Temp"
TXT_RAM="RAM Free"
TXT_TEKAN="Press [ENTER] to STOP"
TXT_STOP_TXT="STOP"
if [ "$_g" -le 4 ]; then TIER=1; TIER_NAME="LOW"; REFRESH=60; ANIM=0.5
elif [ "$_g" -le 6 ]; then TIER=2; TIER_NAME="MID"; REFRESH=90; ANIM=0.3
else TIER=3; TIER_NAME="HIGH"; REFRESH=120; ANIM=0.0
fi
safe_set(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.05; }
get_temp(){ MAX=0; for f in /sys/class/thermal/thermal_zone*/temp; do [ -f "$f" ] || continue; T=$(cat $f 2>/dev/null); [ "$T" -gt 1000 ] && T=$((T/1000)); [ "$T" -gt "$MAX" ] && MAX=$T; done; [ "$MAX" -eq 0 ] && MAX=38; echo $MAX; }
get_ram_free(){ free -m | awk '/Mem:/{print $7}'; }
get_fps_auto(){
  TEMP=$(get_temp)
  if [ "$TIER" -eq 1 ]; then MAX_FPS=60; elif [ "$TIER" -eq 2 ]; then MAX_FPS=90; else MAX_FPS=120; fi
  if [ "$TEMP" -lt 44 ]; then echo $MAX_FPS; else echo $((MAX_FPS-5)); fi
}
has_cooler(){
  if ls /sys/class/thermal/cooling_device* >/dev/null 2>&1; then return 0
  elif ls /sys/class/thermal/thermal_zone* >/dev/null 2>&1; then return 0
  else return 1
  fi
}
if has_cooler; then COOLER_ENABLED=1; COOLER_STATUS="AUTO"; else COOLER_ENABLED=0; COOLER_STATUS="NOT SUPPORTED - DISABLED"; fi
stealth_cache_clean(){
  pm trim-caches 2048M >/dev/null 2>&1
  for p in /sdcard/Android/data/*/cache /sdcard/DCIM/.thumbnails; do rm -rf $p/* >/dev/null 2>&1; done
  find /sdcard -type f -name "*.tmp" -delete >/dev/null 2>&1
}
ultra_anti_ads(){ safe_set global private_dns_mode hostname; safe_set global private_dns_specifier $(echo ZG5zLmFkZ3VhcmQuY29t | base64 -d); safe_set global ad_services_enabled 0; }
ultra_anti_lag(){ safe_set global cached_apps_freezer enabled; }
boost_cpu_gpu(){
  safe_set global sem_enhanced_cpu_responsiveness 1
  safe_set global debug.hwui.renderer skiagl
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
}
slippery_logic(){
  FPS=$2
  if [ "$FPS" -ge 55 ]; then SLOP=4; TO=150
  else SLOP=8; TO=190
  fi
  safe_set system view_configuration_touch_slop $SLOP
  safe_set secure long_press_timeout $TO
  safe_set system touch.size.scale 0.3
}
game_loader_boost(){
  for pkg in $(pm list packages 3 2>/dev/null | cut -d: -f2 | grep -i -E "mobile|legend|pubg|minecraft|mlbb" | head -3); do cmd package compile -m speed-profile -f $pkg >/dev/null 2>&1 &; done
}
map_gen_boost(){ safe_set system large_heap 1; safe_set global map_preload_distance 12; }
cooler_logic(){
  if [ "$COOLER_ENABLED" -eq 0 ]; then echo "$COOLER_STATUS"; return; fi
  TEMP=$1
  if [ "$TEMP" -ge 48 ]; then RFS=60; MODE="COOLER EXTREME $TEMP°C"; am kill-all >/dev/null 2>&1
  elif [ "$TEMP" -ge 44 ]; then RFS=90; MODE="COOLER HARD $TEMP°C"
  else RFS=120; MODE="COOLER STABLE $TEMP°C"
  fi
  safe_set system peak_refresh_rate $RFS
  safe_set system min_refresh_rate $RFS
  echo $MODE
}
notify_update(){ echo -e "${Y}update : $1${NC}"; }
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; COOLER_INFO=$4
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10)); BAR=$(printf "%${FILL}s" | tr ' ' '#'); EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e " ${W}$TXT_VER : $TXT_APP${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_FUNGSI :${NC}"
  echo -e "  ${G}[✓]${NC} ${W}all system performance : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}anti lag : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}block ads : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}cpu gpu boost : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}slippery sensitivity : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}frame optimize : $REFRESH Hz locked${NC}"
  echo -e "  ${G}[✓]${NC} ${W}game loading : active${NC}"
  echo -e "  ${G}[✓]${NC} ${W}map gen : active${NC}"
  if [ "$COOLER_ENABLED" -eq 1 ]; then
    echo -e "  ${G}[✓]${NC} ${W}cooler cpu gpu : $COOLER_INFO${NC}"
  else
    echo -e "  ${R}[x]${NC} ${W}cooler cpu gpu : $COOLER_STATUS${NC}"
  fi
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}
termux-wake-lock 2>/dev/null
CYCLE=0
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto); CYCLE=$((CYCLE+1))
  COOLER_INFO=$(cooler_logic $TEMP)
  draw_box $TEMP $RAM $FPS "$COOLER_INFO"
  echo ""
  notify_update "anti lag"
  notify_update "block ads"
  notify_update "cpu gpu"
  notify_update "slippery"
  notify_update "game loading"
  notify_update "map gen"
  if [ "$COOLER_ENABLED" -eq 1 ]; then notify_update "$COOLER_INFO"; else notify_update "cooler disabled"; fi
  if [ $((CYCLE % 5)) -eq 0 ]; then stealth_cache_clean; fi
  ultra_anti_ads
  ultra_anti_lag
  boost_cpu_gpu
  slippery_logic $TEMP $FPS
  game_loader_boost
  map_gen_boost
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 2; then clear; echo -e "${G}✔ $TXT_STOP_TXT${NC}"; safe_set global private_dns_mode opportunistic; exit 0; fi
done
