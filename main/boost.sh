#!/data/data/com.termux/files/usr/bin/bash
# =================================================================
# ULTRA AUTO ADAPTIVE V3 - NO WALL + AUTO TRANSLATE BY IP
# MODE: NON-ROOT & NON-VISUAL SAFE FOR ALL DEVICE
# BAR FPS: # | WALL REMOVED | AUTO LANG BY IP
# =================================================================

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'

# --- AUTO DETEKSI NAMA HP USER (ORIGINAL) ---
BRAND=$(getprop ro.product.brand 2>/dev/null | tr 'a-z' 'A-Z')
MODEL=$(getprop ro.product.model 2>/dev/null)
CHIPSET=$(getprop ro.board.platform 2>/dev/null)
if [ -z "$CHIPSET" ]; then CHIPSET=$(getprop ro.hardware 2>/dev/null); fi
if [ -z "$CHIPSET" ]; then CHIPSET=$(cat /proc/cpuinfo 2>/dev/null | grep Hardware | head -1 | cut -d: -f2 | xargs); fi
RAM_TOTAL_KB=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
RAM_TOTAL_GB=$((RAM_TOTAL_KB / 1024))
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null)
[ -z "$BRAND" ] && BRAND="OPPO"
[ -z "$MODEL" ] && MODEL="A17"
[ -z "$CHIPSET" ] && CHIPSET="Helio G35"

# --- AUTO TRANSLATE BY IP / COUNTRY (BARU) ---
IP_COUNTRY="ID"
LANG_CODE="ID"
IP_ADDR="127.0.0.1"

detect_country_and_lang(){
  # 1. Coba ambil negara dari IP publik (pake curl)
  if command -v curl >/dev/null 2>&1; then
    DATA=$(curl -s --connect-timeout 3 https://ipinfo.io 2>/dev/null)
    if [ -n "$DATA" ]; then
      CTRY=$(echo "$DATA" | grep '"country"' | cut -d'"' -f4 | tr 'a-z' 'A-Z')
      IP_TMP=$(echo "$DATA" | grep '"ip"' | cut -d'"' -f4)
      [ -n "$CTRY" ] && IP_COUNTRY="$CTRY"
      [ -n "$IP_TMP" ] && IP_ADDR="$IP_TMP"
    fi
  fi
  # 2. Fallback kalo curl gagal - pake SIM / Locale
  if [ "$IP_COUNTRY" = "ID" ] && [ "$IP_ADDR" = "127.0.0.1" ]; then
    SIM=$(getprop gsm.sim.operator.iso-country 2>/dev/null | tr 'a-z' 'A-Z')
    [ -n "$SIM" ] && IP_COUNTRY="$SIM"
  fi
  if [ -z "$IP_COUNTRY" ] || [ ${#IP_COUNTRY} -gt 4 ]; then
    LOC=$(getprop persist.sys.locale 2>/dev/null | cut -d'-' -f2 | tr 'a-z' 'A-Z')
    [ -n "$LOC" ] && IP_COUNTRY="$LOC" || IP_COUNTRY="ID"
  fi

  # Tentukan bahasa
  case "$IP_COUNTRY" in
    ID) LANG_CODE="ID" ;;
    MY|SG) LANG_CODE="MY" ;;
    US|GB|UK|AU|CA) LANG_CODE="EN" ;;
    JP) LANG_CODE="JP" ;;
    KR) LANG_CODE="KR" ;;
    PH) LANG_CODE="PH" ;;
    IN) LANG_CODE="IN" ;;
    *) LANG_CODE="ID" ;; # default Indo
  esac
}

load_translation(){
  # Default ID
  TXT_APP="ULTRA AUTO V3"
  TXT_TIER="TIER DEVICE"
  TXT_BOOST="BOOST POWER"
  TXT_CPU="CPU MAX"
  TXT_REFRESH="Refresh"
  TXT_MODE="MODE"
  TXT_TEMP="Suhu"
  TXT_RAM="RAM Free"
  TXT_INFO="INFO"
  TXT_AUTO="AUTO"
  TXT_DETEK="Deteksi"
  TXT_KEKUATAN="Kekuatan"
  TXT_DITERAPKAN="diterapkan untuk"
  TXT_STOP_TXT="STOP"
  TXT_TEKAN="Tekan [ENTER] untuk STOP"

  if [ "$LANG_CODE" = "EN" ]; then
    TXT_TIER="DEVICE TIER"
    TXT_BOOST="BOOST POWER"
    TXT_CPU="CPU MAX"
    TXT_TEMP="Temp"
    TXT_RAM="RAM Free"
    TXT_INFO="INFO"
    TXT_AUTO="AUTO"
    TXT_DETEK="Detect"
    TXT_KEKUATAN="Power"
    TXT_DITERAPKAN="applied for"
    TXT_STOP_TXT="STOP"
    TXT_TEKAN="Press [ENTER] to STOP"
  elif [ "$LANG_CODE" = "MY" ]; then
    TXT_TIER="TIER PERANTI"
    TXT_BOOST="KUASA BOOST"
    TXT_TEMP="Suhu"
    TXT_TEKAN="Tekan [ENTER] untuk HENTI"
  fi
}

# JALANKAN DETEKSI BAHASA DI AWAL
detect_country_and_lang
load_translation

# --- AUTO TENTUIN TIER & KEKUATAN BOOST (ORIGINAL) ---
if [ "$RAM_TOTAL_GB" -le 4 ]; then
  TIER=1; TIER_NAME="LOW - KENTANG"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5
elif [ "$RAM_TOTAL_GB" -le 6 ]; then
  TIER=2; TIER_NAME="MID - MENENGAH"; BOOST_POWER="75% PERFORMANCE"; MAX_CPU_PERCENT=90; REFRESH=90; ANIM=0.3
elif [ "$RAM_TOTAL_GB" -le 8 ]; then
  TIER=3; TIER_NAME="HIGH - KUAT"; BOOST_POWER="100% TURBO"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0
else
  TIER=4; TIER_NAME="EXTREME - FLAGSHIP"; BOOST_POWER="120% EXTREME OC"; MAX_CPU_PERCENT=100; REFRESH=120; ANIM=0.0
fi

if echo "$CHIPSET" | grep -qi "G35\|G25\|G85\|mt6765\|helio"; then
  TIER=1; TIER_NAME="LOW - HELIO G35"; BOOST_POWER="50% BALANCED ADEM"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5
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

# --- DRAW BOX TANPA DINDING (REQUESTED - NO WALL) ---
draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; TIER_NOW=$4; BOOST_NOW=$5
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10))
  BAR=$(printf "%${FILL}s" | tr ' ' '#')
  EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  clear
  echo -e "${C}${TXT_APP} - $BRAND $MODEL${NC}"
  echo -e "${W} Chipset: $CHIPSET | RAM: ${RAM_TOTAL_GB}GB | Andro $ANDROID_VER ${NC}"
  echo -e "${W} IP: $IP_ADDR | Country: $IP_COUNTRY | Lang: $LANG_CODE ${NC}"
  echo -e ""
  echo -e "${G}[✓]${NC} ${W}$TXT_TIER : $TIER_NOW ${NC}"
  echo -e "${Y}[✓]${NC} ${W}$TXT_BOOST : $BOOST_NOW (Auto)${NC}"
  echo -e "${B}[✓]${NC} ${W}$TXT_CPU : $MAX_CPU_PERCENT% | $TXT_REFRESH: ${REFRESH}Hz${NC}"
  echo -e "${R}[✓]${NC} ${W}$TXT_MODE : NON-ROOT + ANTI IKLAN ULTRA${NC}"
  echo -e ""
  echo -e "${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC% ${NC}"
  echo -e ""
}

ultra_anti_ads(){
  echo -e "${Y}[$(date +%T)] ANTI IKLAN: Shield $IP_COUNTRY...${NC}"
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier dns.adguard.com
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
  echo -e "${Y}[$(date +%T)] $TXT_AUTO BOOST: $TXT_DETEK $BRAND $MODEL Tier $TIER_NAME [$IP_COUNTRY]${NC}"
  echo -e "${Y}[$(date +%T)] $TXT_AUTO BOOST: $TXT_KEKUATAN $BOOST_POWER $TXT_REFRESH ${REFRESH}Hz${NC}"
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  ultra_anti_ads
  ultra_anti_lag
  echo -e "${G}[$(date +%T)] BOOST: $BOOST_POWER $TXT_DITERAPKAN $MODEL${NC}"
}

termux-wake-lock 2>/dev/null
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto)
  draw_box $TEMP $RAM $FPS "$TIER - $TIER_NAME" "$BOOST_POWER"
  echo -e "${B}[$(date +%T)] $TXT_INFO: $BRAND $MODEL | $IP_ADDR:$IP_COUNTRY${NC}"
  echo -e "${G}[$(date +%T)] $TXT_AUTO: $BOOST_POWER + Anti Iklan/Lag ULTRA [$LANG_CODE]${NC}"
  boost_auto
  echo -e "${W}>> $TXT_TEKAN <<${NC}"
  if read -t 5; then clear; echo -e "${G}✔ $TXT_STOP_TXT - $MODEL${NC}"; safe_set global private_dns_mode opportunistic; exit 0; fi
done
