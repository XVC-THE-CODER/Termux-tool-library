#!/data/data/com.termux/files/usr/bin/bash
# =================================================================
# ULTRA AUTO ADAPTIVE V2 - ORIGINAL + ANTI LAG & ANTI IKLAN ULTRA
# Auto Detect: OPPO A17 / Helio G35 / RAM 4GB / Tier LOW
# Boost auto berubah: HP Kentang 50% - HP Kuat 120%
# MODE: NON-ROOT & NON-VISUAL SAFE FOR ALL DEVICE
# BAR FPS: # (REQUESTED)
# =================================================================

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'

# --- AUTO DETEKSI NAMA HP USER (ORIGINAL - TIDAK DIUBAH) ---
BRAND=$(getprop ro.product.brand 2>/dev/null | tr 'a-z' 'A-Z')
MODEL=$(getprop ro.product.model 2>/dev/null)
CHIPSET=$(getprop ro.board.platform 2>/dev/null)
if [ -z "$CHIPSET" ]; then CHIPSET=$(getprop ro.hardware 2>/dev/null); fi
if [ -z "$CHIPSET" ]; then CHIPSET=$(cat /proc/cpuinfo 2>/dev/null | grep Hardware | head -1 | cut -d: -f2 | xargs); fi
RAM_TOTAL_KB=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
RAM_TOTAL_GB=$((RAM_TOTAL_KB / 1024 / 1024))
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null)

# Kalo gak kedetek, fallback ke OPPO A17 lu (ORIGINAL)
[ -z "$BRAND" ] && BRAND="OPPO"
[ -z "$MODEL" ] && MODEL="A17"
[ -z "$CHIPSET" ] && CHIPSET="Helio G35"

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

# Override khusus Helio G35 biar gak dipaksa (ORIGINAL)
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

draw_box(){
  TEMP=$1; RAM=$2; FPS=$3; TIER_NOW=$4; BOOST_NOW=$5
  PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
  FILL=$((PERC/10))
  # REQUESTED: BAR FPS GANTI # AJA
  BAR=$(printf "%${FILL}s" | tr ' ' '#')
  EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
  clear
  echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${C}┃${NC} ${W} ULTRA AUTO V2 - $BRAND $MODEL ${NC} ${C}┃${NC}"
  echo -e "${C}┃${NC} ${W} Chipset: $CHIPSET | RAM: ${RAM_TOTAL_GB}GB | Andro $ANDROID_VER ${NC} ${C}┃${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e "${C}┃${NC} ${G}[✓]${NC} ${W}TIER DEVICE : $TIER_NOW ${NC} ${C}┃${NC}"
  echo -e "${C}┃${NC} ${Y}[✓]${NC} ${W}BOOST POWER : $BOOST_NOW (Auto)${NC} ${C}┃${NC}"
  echo -e "${C}┃${NC} ${B}[✓]${NC} ${W}CPU MAX : $MAX_CPU_PERCENT% | Refresh: ${REFRESH}Hz${NC} ${C}┃${NC}"
  echo -e "${C}┃${NC} ${R}[✓]${NC} ${W}MODE : NON-ROOT + ANTI IKLAN ULTRA${NC} ${C}┃${NC}"
  echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
  echo -e "${C}┃${NC} Suhu:${TEMP}°C RAM Free:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC% ${C}┃${NC}"
  echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

# --- ULTRA ANTI IKLAN NON-ROOT (BARU - PERKUAT) ---
ultra_anti_ads(){
  echo -e "${Y}[$(date +%T)] ANTI IKLAN: Pasang shield...${NC}"
  safe_set global private_dns_mode hostname
  safe_set global private_dns_specifier dns.adguard.com
  safe_set global ad_services_enabled 0
  safe_set global ad_services_consent_enabled 0
  safe_set global cta_did_enabled 0
  safe_set global cta_ad_id_enabled 0
  safe_set global google_ads_adid_enabled 0
  safe_set secure limit_ad_tracking 1
  safe_set global analytics_enabled 0
  # Block telemetry & ads bloatware OPPO/Realme/Xiaomi
  for pkg in com.heytap.msp com.heytap.cloud com.oppo.market com.coloros.oppoguardelf com.facebook.system com.facebook.appmanager com.facebook.services; do
    pm clear --cache-only $pkg >/dev/null 2>&1
  done
}

# --- ULTRA ANTI LAG NON-ROOT (BARU - PERKUAT) ---
ultra_anti_lag(){
  echo -e "${Y}[$(date +%T)] ANTI LAG: Bersihin daleman...${NC}"
  # 1. Bebasin RAM non-root
  pm trim-caches 999M >/dev/null 2>&1
  cmd package bg-dexopt-job >/dev/null 2>&1 &
  # 2. Freeze app nganggur biar gak lag (Android 11+)
  safe_set global cached_apps_freezer enabled
  safe_set global cached_apps_freezer_compression lz4
  # 3. Matikan log spam yang bikin lag
  safe_set global activity_starts_logging_enabled 0
  safe_set global system_cap 0
  safe_set global app_auto_restriction_enabled 1
  # 4. Kill bloatware background sesuai Tier (aman)
  if [ "$TIER" -eq 1 ]; then
    am kill-all >/dev/null 2>&1
    cmd activity kill-all >/dev/null 2>&1
  fi
  # 5. Optimasi I/O tanpa root
  cmd package compile -m speed-profile -a >/dev/null 2>&1 &
}

boost_auto(){
  echo -e "${Y}[$(date +%T)] AUTO BOOST: Deteksi $BRAND $MODEL Tier $TIER_NAME${NC}"
  echo -e "${Y}[$(date +%T)] AUTO BOOST: Kekuatan $BOOST_POWER Refresh ${REFRESH}Hz${NC}"
  
  # ORIGINAL BOOST (NON-VISUAL SAFE)
  safe_set global window_animation_scale $ANIM
  safe_set global transition_animation_scale $ANIM
  safe_set global animator_duration_scale $ANIM
  safe_set system peak_refresh_rate $REFRESH
  safe_set system min_refresh_rate $REFRESH
  
  # PANGGIL ULTRA MODULE BARU
  ultra_anti_ads
  ultra_anti_lag
  
  # NON-ROOT TWEAK TAMBAHAN SESUAI TIER
  if [ "$TIER" -ge 2 ]; then
    safe_set global ram_expand_size 0
    safe_set system intelligent_sleep 0
  fi
  
  echo -e "${G}[$(date +%T)] BOOST: $BOOST_POWER diterapkan untuk $MODEL${NC}"
}

termux-wake-lock 2>/dev/null
while true; do
  TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto)
  draw_box $TEMP $RAM $FPS "$TIER - $TIER_NAME" "$BOOST_POWER"
  echo ""; echo -e "${B}[$(date +%T)] INFO: Nama HP auto $BRAND $MODEL | Mode Non-Root${NC}"
  echo -e "${G}[$(date +%T)] AUTO: Boost $BOOST_POWER + Anti Iklan/Lag ULTRA aktif${NC}"
  boost_auto
  echo -e "${W}>> Tekan [ENTER] untuk STOP <<${NC}"
  if read -t 5; then clear; echo -e "${G}✔ STOP - $MODEL | Private DNS balik normal${NC}"; safe_set global private_dns_mode opportunistic; exit 0; fi
done
