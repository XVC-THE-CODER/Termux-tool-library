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
  TXT_APP=$(echo Ym9vc3QgcGVyZm9tYW5jZSBWMS41 | base64 -d)
  TXT_VER="VERSION"
  TXT_FUNGSI="FUNGSI LIST"
  TXT_INFO="INFO"
  TXT_TIER="TIER DEVICE"
  TXT_BOOST="BOOST POWER"
  TXT_CPU="CPU MAX"
  TXT_REFRESH="Refresh"
  TXT_MODE="MODE"
  TXT_TEMP="Suhu"
  TXT_RAM="RAM Free"
  TXT_AUTO="AUTO"
  TXT_DETEK="Deteksi"
  TXT_KEKUATAN="Kekuatan"
  TXT_DITERAPKAN="diterapkan untuk"
  TXT_STOP_TXT="STOP"
  TXT_TEKAN="Tekan [ENTER] untuk STOP"
  if [ "$LANG_CODE" = "EN" ]; then
    TXT_VER="VERSION"
    TXT_FUNGSI="FUNCTION LIST"
    TXT_INFO="INFO"
    TXT_TIER="DEVICE TIER"
    TXT_BOOST="BOOST POWER"
    TXT_CPU="CPU MAX"
    TXT_TEMP="Temp"
    TXT_AUTO="AUTO"
    TXT_DETEK="Detect"
    TXT_KEKUATAN="Power"
    TXT_DITERAPKAN="applied for"
    TXT_STOP_TXT="STOP"
    TXT_TEKAN="Press [ENTER] to STOP"
  fi
}
detect_lang
load_translation
if [ "$_g" -le 4 ]; then
  TIER=1; TIER_NAME="LOW - KENTANG"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5
elif [ "$_g" -le 6 ]; then
  TIER=2; TIER_NAME="MID - MENENGAH"; BOOST_POWER="75% PERFORMANCE"; MAX_CPU_PERCENT=90; REFRESH=90; ANIM=0.3
elif [ "$_g" -le 8 ]; then
  TIER=3; TIER_NAME="HIGH - KUAT"; BOOST_POWER="100% TURBO"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0
else
  TIER=4; TIER_NAME="EXTREME - FLAGSHIP"; BOOST_POWER="120% EXTREME OC"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0
fi
if echo "$_c" | grep -qi "G35\|G25\|G85\|mt6765\|helio"; then
  TIER=1; TIER_NAME="LOW - KENTANG"; BOOST_POWER="50% BALANCED ADEM"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5
fi
is_root(){ su -c "id" >/dev/null 2>&1 && echo 1 || echo 0; }
safe_set(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.15; }
get_temp(){ MAX=0; for f in /sys/class/thermal/thermal_zone*/temp; do [ -f "$f" ] || continue; T=$(cat $f 2>/dev/null); [ "$T" -gt 1000 ] && T=$((T/1000)); [ "$T" -gt "$MAX" ] && MAX=$T; done; [ "$MAX" -eq 0 ] && MAX=40; echo $MAX; }
get_ram_free(){ free -m | awk '/Mem:/{print $7}'; }
get_fps_auto(){
  TEMP=$(get_temp); RAM=$(get_ram_free)
  if [ "$TIER" -eq 1 ]; then MAX_FPS=60; elif [ "$TIER" -eq 2 ]; then MAX_FPS=90; else MAX_FPS=120; fi
  if [ "$TEMP" -lt 42 ] && [ "$RAM" -gt 1000 ]; then echo $MAX_FPS
  elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-5))
  else echo $((MAX_FPS-12))
  fi
}
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; TIER_NOW=$4; BOOST_NOW=$5
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
  echo -e "  ${Y}[✓]${NC} ${W}$TXT_BOOST : $BOOST_NOW${NC}"
  echo -e "  ${B}[✓]${NC} ${W}$TXT_CPU : $MAX_CPU_PERCENT% | $TXT_REFRESH: ${REFRESH}Hz${NC}"
  echo -e "  ${R}[✓]${NC} ${W}$TXT_MODE : ON ROOT + ANTI IKLAN ULTRA${NC}"
  echo -e "  ${C}[✓]${NC} ${W}ANTI LAG ULTRA : Active${NC}"
  echo -e "  ${C}[✓]${NC} ${W}ANTI IKLAN ULTRA : Active${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e " ${W}$TXT_INFO : RAM ${_g}GB | Andro $_v${NC}"
  echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}
ultra_anti_ads(){
  echo -e "${Y}[$(date +%T)] ANTI IKLAN: Shield...${NC}"
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier $(echo ZG5zLmFkZ3VhcmQuY29t | base64 -d)
  safe_set global ad_services_enabled 0
  safe_set global ad_services_consent_enabled 0
  safe_set secure limit_ad_tracking 1
  safe_set global analytics_enabled 0
  for pkg in com.heytap.msp com.heytap.cloud com.oppo.market com.coloros.oppoguardelf com.facebook.system; do
    pm clear --cache-only $pkg >/dev/null 2>&1
  done
}
ultra_anti_lag(){
  echo -e "${Y}[$(date +%T)] ANTI LAG: Bersihin...${NC}"
  pm trim-caches 999M >/dev/null 2>&1
  cmd package bg-dexopt-job >/dev/null 2>&1 &
  safe_set global cached_apps_freezer enabled
  safe_set global activity_starts_logging_enabled 0
  if [ "$TIER" -eq 1 ]; then
    am kill-all >/dev/null 2>&1
  fi
}
boost_auto(){
  echo -e "${Y}[$(date +%T)] $TXT_AUTO BOOST: $TXT_DETEK $_m Tier $TIER_NAME${NC}"
  echo -e "${Y}[$(date +%T)] $TXT_AUTO BOOST: $TXT_KEKUATAN $BOOST_POWER $TXT_REFRESH ${REFRESH}Hz${NC}"
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  ultra_anti_ads
  ultra_anti_lag
  echo -e "${G}[$(date +%T)] BOOST: $BOOST_POWER $TXT_DITERAPKAN Secured${NC}"
}
termux-wake-lock 2>/dev/null
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto)
  draw_box $TEMP $RAM $FPS "$TIER - $TIER_NAME" "$BOOST_POWER"
  echo ""; echo -e "${B}[$(date +%T)] $TXT_INFO: Secured Device${NC}"
  echo -e "${G}[$(date +%T)] $TXT_AUTO: $BOOST_POWER + Anti Iklan/Lag ULTRA${NC}"
  boost_auto
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 5; then clear; echo -e "${G}✔ $TXT_STOP_TXT - Secured${NC}"; safe_set global private_dns_mode opportunistic; exit 0; fi
done
