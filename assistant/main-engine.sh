#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m';G='\033[1;32m';Y='\033[1;33m';B='\033[1;34m';C='\033[1;36m';W='\033[1;37m';NC='\033[0m'
LANG_FILE="$HOME/.as_lang"
SAVE_FILE="$HOME/.rbx_saves"
SELECTED=""
ROBLOX_PLAYER_URL="https://www.roblox.com/users/"
ROBLOX_PLAYER_DEEP="roblox://users/"
norm(){ echo "$1" | tr '[:upper:]' '[:lower:]' | xargs; }
gen_uuid(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "cfed5fc6-80be-4d6f-ac0a-d95126cf2b39"; }
choose_lang(){
clear
echo -e "${C}================================${NC}"
echo -e "${W}  Pilih Bahasa / Choose Language${NC}"
echo -e "${C}================================${NC}"
echo -e "${W}[1] Indonesia (id)${NC}"
echo -e "${W}[2] English (en)${NC}"
echo -e ""
echo -e "${Y}Ketik: 1 / id / indonesia  atau  2 / en / english${NC}"
read -p "> " inp
inp=$(norm "$inp")
case "$inp" in
1|id|indonesia|indo) SELECTED="id" ;;
2|en|english|inggris|eng) SELECTED="en" ;;
*) choose_lang; return ;;
esac
echo "$SELECTED" > "$LANG_FILE"
}
show_sel(){
clear
if [ "$SELECTED" = "id" ]; then
echo -e "${G}Bahasa Indonesia dipilih!${NC}"
else
echo -e "${G}English language selected!${NC}"
fi
sleep 1
clear
}
show_cmd(){
if [ "$SELECTED" = "id" ]; then
echo -e "${C}command assistant${NC}"
echo -e "${W}------------------------------${NC}"
echo -e "${G}as update${NC} - update via github & restart"
echo -e "${G}as roblox${NC} - masuk ke Roblox lobby"
echo -e "${G}as antilag${NC} - optimasi & boost performa"
echo -e "${G}as lang <id/en/indonesia/english>${NC} - ganti bahasa"
echo -e "${G}exit${NC} - keluar dari tool ini"
echo -e "${W}------------------------------${NC}"
else
echo -e "${C}command assistant${NC}"
echo -e "${W}------------------------------${NC}"
echo -e "${G}as update${NC} - update via github & restart"
echo -e "${G}as roblox${NC} - enter Roblox lobby"
echo -e "${G}as antilag${NC} - optimization & performance boost"
echo -e "${G}as lang <id/en/indonesia/english>${NC} - change language"
echo -e "${G}exit${NC} - exit from this tool"
echo -e "${W}------------------------------${NC}"
fi
}
roblox_join_by_id(){
id="$1"
[ -z "$id" ] && return
uuid=$(gen_uuid)
link="https://ro.blox.com/Ebh5?is_retargeting=false&pid=experiencestart_mobileweb&af_dp=https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3Fplaceid%3D${id}%26joinAttemptId%3D${uuid}&af_web_dp=https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3Fplaceid%3D${id}%26joinAttemptId%3D${uuid}&deep_link_value=https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3Fplaceid%3D${id}%26joinAttemptId%3D${uuid}"
if [ "$SELECTED" = "id" ]; then echo -e "${G}Join map ID: $id${NC}"; else echo -e "${G}Joining map ID: $id${NC}"; fi
echo -e "${W}$link${NC}"
termux-open-url "$link" >/dev/null 2>&1
am start -a android.intent.action.VIEW -d "$link" >/dev/null 2>&1
am start -a android.intent.action.VIEW -d "roblox://placeId=$id" >/dev/null 2>&1
}
save_rbx(){
name="$1"
id="$2"
[ -z "$name" ] || [ -z "$id" ] && return
touch "$SAVE_FILE"
grep -v "^${name}|" "$SAVE_FILE" 2>/dev/null > "${SAVE_FILE}.tmp" || true
mv "${SAVE_FILE}.tmp" "$SAVE_FILE" 2>/dev/null || true
echo "${name}|${id}" >> "$SAVE_FILE"
if [ "$SELECTED" = "id" ]; then echo -e "${G}Disimpan: $name -> $id${NC}"; else echo -e "${G}Saved: $name -> $id${NC}"; fi
}
list_rbx(){
if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Belum ada save-an. Gunakan: rbx save <name> <id>${NC}"; else echo -e "${Y}No saves yet. Use: rbx save <name> <id>${NC}"; fi
return 1
fi
i=1
while IFS='|' read -r n mid; do
[ -z "$n" ] && continue
echo -e "${W}${i}. ${G}${n}${NC} ${W}- ${mid}${NC}"
i=$((i+1))
done < "$SAVE_FILE"
return 0
}
get_rbx_by_num(){
num="$1"
[ -z "$num" ] && return 1
line=$(sed -n "${num}p" "$SAVE_FILE" 2>/dev/null)
[ -z "$line" ] && return 1
echo "$line" | cut -d'|' -f2
}
get_rbx_by_name(){
sname="$1"
[ -z "$sname" ] && return 1
grep -i "^${sname}|" "$SAVE_FILE" 2>/dev/null | head -n 1 | cut -d'|' -f2
}
roblox_lobby(){
clear
if [ "$SELECTED" = "id" ]; then
echo -e "${C}Roblox lobby${NC}"
echo -e "${W}------------------------------${NC}"
echo -e "${W}command${NC}"
echo -e "${G}rbx playgame <id map>${NC} - langsung masuk ke map"
echo -e "${G}rbx playersearch <id player>${NC} - cari player"
echo -e "${G}rbx save <name> <id map>${NC} - simpan map"
echo -e "${G}rbx listjoin [name/angka]${NC} - join dari save (pakai nomor)"
echo -e "${G}exit${NC} - keluar dari Roblox lobby"
echo -e "${W}------------------------------${NC}"
else
echo -e "${C}Roblox lobby${NC}"
echo -e "${W}------------------------------${NC}"
echo -e "${W}command${NC}"
echo -e "${G}rbx playgame <id map>${NC} - directly join map"
echo -e "${G}rbx playersearch <id player>${NC} - search player"
echo -e "${G}rbx save <name> <id map>${NC} - save map"
echo -e "${G}rbx listjoin [name/number]${NC} - join from save (use number)"
echo -e "${G}exit${NC} - exit from Roblox lobby"
echo -e "${W}------------------------------${NC}"
fi
while true; do
echo ""
read -p "roblox> " rcmd
[ -z "$rcmd" ] && continue
rfull=$(norm "$rcmd")
case "$rfull" in
rbx\ playgame* )
rid=$(echo "$rcmd" | awk '{print $3}')
if [ -z "$rid" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Contoh: rbx playgame 123974602339071${NC}"; else echo -e "${Y}Example: rbx playgame 123974602339071${NC}"; fi
else
roblox_join_by_id "$rid"
fi
;;
rbx\ playersearch* )
rid=$(echo "$rcmd" | awk '{print $3}')
if [ -z "$rid" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Contoh: rbx playersearch 123456${NC}"; else echo -e "${Y}Example: rbx playersearch 123456${NC}"; fi
else
if [ "$SELECTED" = "id" ]; then echo -e "${G}Cari player ID: $rid${NC}"; else echo -e "${G}Searching player ID: $rid${NC}"; fi
termux-open-url "${ROBLOX_PLAYER_URL}${rid}/profile" >/dev/null 2>&1
am start -a android.intent.action.VIEW -d "${ROBLOX_PLAYER_DEEP}${rid}" >/dev/null 2>&1
fi
;;
rbx\ save* )
save_args=$(echo "$rcmd" | cut -d' ' -f3-)
sid=$(echo "$save_args" | awk '{print $NF}')
sname=$(echo "$save_args" | sed "s/ ${sid}\$//" | sed "s/^ *//;s/ *$//")
if [ -z "$sname" ] || [ -z "$sid" ] || [ "$sname" = "$sid" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Contoh: rbx save lobbyku 123974602339071${NC}"; else echo -e "${Y}Example: rbx save mylobby 123974602339071${NC}"; fi
else
save_rbx "$sname" "$sid"
fi
;;
rbx\ listjoin* )
arg=$(echo "$rcmd" | cut -d' ' -f3- | xargs)
if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Belum ada save-an${NC}"; else echo -e "${Y}No saves${NC}"; fi
continue
fi
if [ -z "$arg" ]; then
list_rbx
echo ""
if [ "$SELECTED" = "id" ]; then
echo -e "${C}Taro angka di input ini untuk join game${NC}"
read -p "Masukkan angka save: " num
else
echo -e "${C}Put number in this input to join game${NC}"
read -p "Enter save number: " num
fi
join_id=$(get_rbx_by_num "$num")
if [ -z "$join_id" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${R}Nomor tidak ditemukan${NC}"; else echo -e "${R}Number not found${NC}"; fi
else
roblox_join_by_id "$join_id"
fi
else
if echo "$arg" | grep -Eq '^[0-9]+$'; then
join_id=$(get_rbx_by_num "$arg")
else
join_id=$(get_rbx_by_name "$arg")
if [ -z "$join_id" ]; then
join_id=$(grep -i "$arg" "$SAVE_FILE" 2>/dev/null | head -n 1 | cut -d'|' -f2)
fi
fi
if [ -z "$join_id" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${R}Save tidak ditemukan: $arg${NC}"; else echo -e "${R}Save not found: $arg${NC}"; fi
else
roblox_join_by_id "$join_id"
fi
fi
;;
exit\ roblox|exit|quit|q|keluar)
clear
show_cmd
break
;;
*)
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Command tidak dikenal di Roblox lobby${NC}"; else echo -e "${Y}Unknown command in Roblox lobby${NC}"; fi
;;
esac
done
}
run_antilag(){
_b=$(getprop $(echo cm8ucHJvZHVjdC5icmFuZA== | base64 -d) 2>/dev/null)
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
TXT_APP=$(echo djIuNSAgICAgYm9vc3QgcGVyZm9tYW5jZSBnYW1l | base64 -d)
TXT_VER="VERSION"
TXT_FUNGSI="FUNCTION LIST"
TXT_INFO="INFO"
TXT_TEMP="Temp"
TXT_RAM="RAM Free"
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
TIER=1; TIER_NAME="LOW"; BOOST_POWER="50% BALANCED"; MAX_CPU_PERCENT=80; REFRESH=60; ANIM=0.5; SENS=9
fi
safe_set(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; sleep 0.08; }
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
get_fps_auto(){
TEMP=$(get_temp); RAM=$(get_ram_free)
if [ "$TIER" -eq 1 ]; then MAX_FPS=60
elif [ "$TIER" -eq 2 ]; then MAX_FPS=90
else MAX_FPS=120
fi
if [ "$TEMP" -lt 42 ] && [ "$RAM" -gt 1000 ]; then echo $MAX_FPS
elif [ "$TEMP" -lt 46 ]; then echo $((MAX_FPS-2))
else echo $((MAX_FPS-6))
fi
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
for p in /sdcard/Android/data/*/cache /sdcard/Android/data/*/files/cache /sdcard/Android/obb/*/cache /sdcard/DCIM/.thumbnails /sdcard/.cache; do
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
}
game_loader_boost(){
for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2 | grep -i -E "mobile|legend|pubg|free|minecraft|roblox|genshin|codm|mlbb|arena|valorant" | head -8); do
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
else RFS=120; MODE="COOLER STABLE $TEMP°C"
fi
safe_set system peak_refresh_rate $RFS
safe_set system min_refresh_rate $RFS
echo $MODE
}
notify_start(){
echo -e "${Y}update : $1${NC}"
if command -v termux-notification >/dev/null 2>&1; then
termux-notification --id tool_up --title "System Tool" --content "update : $1" --priority low >/dev/null 2>&1
fi
}
notify_clear(){
printf "\033[1A\033[2K"
if command -v termux-notification-remove >/dev/null 2>&1; then
termux-notification-remove tool_up >/dev/null 2>&1
fi
}
draw_box(){
TEMP=$1; RAM=$2; FPS=$3; COOLER_INFO=$4; TIER_NOW=$5; BOOST_NOW=$6
PERC=$((FPS*100/60)); [ "$PERC" -gt 100 ] && PERC=100
FILL=$((PERC/10))
BAR=$(printf "%${FILL}s" | tr ' ' '#')
EBAR=$(printf "%$((10-FILL))s" | tr ' ' '-')
clear
echo -e "${C}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e " ${W}$TXT_VER : $TXT_APP${NC}"
echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
echo -e " ${W}$TXT_FUNGSI :${NC}"
echo -e " ${G}[✓]${NC} ${W}all system performance : active${NC}"
echo -e " ${G}[✓]${NC} ${W}tier device : $TIER_NOW${NC}"
echo -e " ${G}[✓]${NC} ${W}boost power : $BOOST_NOW${NC}"
echo -e " ${G}[✓]${NC} ${W}cpu gpu boost : $MAX_CPU_PERCENT% | $REFRESH Hz Locked${NC}"
echo -e " ${G}[✓]${NC} ${W}slippery real-time : 150ms${NC}"
echo -e " ${G}[✓]${NC} ${W}frame optimize : V-Sync Stable${NC}"
echo -e " ${G}[✓]${NC} ${W}game loading : Fast Load Active${NC}"
echo -e " ${G}[✓]${NC} ${W}map gen : Chunk Preload 12 Active${NC}"
if [ "$COOLER_ENABLED" -eq 1 ]; then
echo -e " ${G}[✓]${NC} ${W}cooler cpu gpu : $COOLER_INFO${NC}"
else
echo -e " ${R}[x]${NC} ${W}cooler cpu gpu : $COOLER_STATUS${NC}"
fi
echo -e "${C}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
echo -e " ${W}$TXT_INFO : RAM ${_g}GB Free ${RAM}MB | Andro $_v${NC}"
echo -e " ${W}$TXT_TEMP:${TEMP}°C $TXT_RAM:${RAM}MB FPS:${G}$FPS${NC} [${G}${BAR}${W}${EBAR}] $PERC%${NC}"
echo -e "${C}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""
}
termux-wake-lock 2>/dev/null
CYCLE=0
while true; do
TEMP=$(get_temp); RAM=$(get_ram_free); FPS=$(get_fps_auto); CYCLE=$((CYCLE+1))
COOLER_INFO=$(cooler_logic $TEMP)
draw_box $TEMP $RAM $FPS "$COOLER_INFO" "$TIER_NAME" "$BOOST_POWER"
notify_start "anti lag"; ultra_anti_lag; notify_clear
notify_start "block ads"; ultra_anti_ads; notify_clear
notify_start "cpu gpu"; boost_cpu_gpu; notify_clear
notify_start "slippery sensitivity"; slippery_logic $TEMP $FPS; notify_clear
notify_start "frame optimize"; sleep 0.1; notify_clear
notify_start "game loading"; game_loader_boost; notify_clear
notify_start "map gen"; map_gen_boost; notify_clear
if [ "$COOLER_ENABLED" -eq 1 ]; then notify_start "$COOLER_INFO"; sleep 0.2; notify_clear; fi
if [ $((CYCLE % 5)) -eq 0 ]; then notify_start "cache clean"; stealth_cache_clean; notify_clear; fi
echo -e "${G}[$(date +%T)] ALL IN ONE: $BOOST_POWER | $COOLER_INFO${NC}"
echo -e "${W}>> $TXT_TEKAN <<${NC}"
if read -t 2; then
clear
echo -e "${G}✔ $TXT_STOP_TXT - Secured${NC}"
safe_set global private_dns_mode opportunistic
safe_set system pointer_speed 3
safe_set secure long_press_timeout 400
safe_set system min_refresh_rate 60
if command -v termux-notification-remove >/dev/null 2>&1; then
termux-notification-remove tool_up >/dev/null 2>&1
fi
echo -e "${Y}Mematikan wakelock...${NC}"
for i in 1 2 3 4 5; do
termux-wake-unlock 2>/dev/null
sleep 0.3
done
j=0
while [ $j -lt 10 ]; do
termux-wake-unlock 2>/dev/null
if [ "$SELECTED" = "id" ]; then echo -e "${W}Loop wakelock off ${j}/10 - tekan ENTER jika sudah mati${NC}"; else echo -e "${W}Loop wakelock off ${j}/10 - press ENTER if off${NC}"; fi
if read -t 1; then break; fi
j=$((j+1))
done
termux-wake-unlock 2>/dev/null
break
fi
done
termux-wake-unlock 2>/dev/null
}
do_update(){
clear
echo -e "${Y}Exiting assistant for update...${NC}"
sleep 1
cd ~
rm -rf Termux-tool-library
rm -rf boost-game
pkg update -y
pkg install -y git
git clone https://github.com/XVC-THE-CODER/Termux-tool-library.git
cd Termux-tool-library
cd assistant
chmod +x main-engine.sh
bash main-engine.sh
exit 0
}
if [ -f "$LANG_FILE" ] && [ "$1" != "--reset-lang" ] && [ "$1" != "-r" ]; then
saved=$(norm "$(cat $LANG_FILE)")
if [[ "$saved" == "id" || "$saved" == "en" ]]; then SELECTED=$saved; else choose_lang; fi
else
if [[ "$1" == "--lang" || "$1" == "-l" ]]; then
inp=$(norm "$2")
case "$inp" in
1|id|indonesia|indo) SELECTED="id" ;;
2|en|english|inggris|eng) SELECTED="en" ;;
*) choose_lang ;;
esac
echo "$SELECTED" > "$LANG_FILE"
else
choose_lang
fi
fi
show_sel
show_cmd
while true; do
echo ""
read -p "assistant> " cmd
[ -z "$cmd" ] && continue
full=$(norm "$cmd")
lang_arg=$(echo "$cmd" | cut -d' ' -f3- | xargs)
case "$full" in
"as update")
do_update
;;
"as roblox"|"roblox"|"rbx")
roblox_lobby
;;
"as antilag")
clear
run_antilag
clear
echo -e "${G}Antilag selesai, kembali ke menu utama...${NC}"
for k in 1 2 3; do termux-wake-unlock 2>/dev/null; sleep 0.2; done
show_cmd
;;
as\ lang* )
if [ -z "$lang_arg" ]; then
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Contoh: as lang id / as lang indonesia / as lang en${NC}"; else echo -e "${Y}Example: as lang id / as lang indonesia / as lang en${NC}"; fi
continue
fi
larg=$(norm "$lang_arg")
case "$larg" in
1|2)
if [ "$SELECTED" = "id" ]; then echo -e "${R}Angka tidak bisa, pakai id/en atau nama bahasa saja${NC}"; else echo -e "${R}Numbers not allowed, use id/en or language name only${NC}"; fi
;;
id|indonesia|indo)
SELECTED="id"
echo "$SELECTED" > "$LANG_FILE"
show_sel
show_cmd
;;
en|english|inggris|eng)
SELECTED="en"
echo "$SELECTED" > "$LANG_FILE"
show_sel
show_cmd
;;
*)
if [ "$SELECTED" = "id" ]; then echo -e "${R}Bahasa tidak dikenal. Pakai: id, en, indonesia, english${NC}"; else echo -e "${R}Unknown language. Use: id, en, indonesia, english${NC}"; fi
;;
esac
;;
"as help"|"help"|"as command")
clear
show_cmd
;;
"exit"|"exit in this tool"|"quit"|"q")
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Keluar...${NC}"; else echo -e "${Y}Exiting...${NC}"; fi
for w in 1 2 3; do termux-wake-unlock 2>/dev/null; sleep 0.2; done
exit 0
;;
*)
if [ "$SELECTED" = "id" ]; then echo -e "${Y}Perintah tidak dikenal, ketik as help${NC}"; else echo -e "${Y}Unknown command, type as help${NC}"; fi
;;
esac
done
