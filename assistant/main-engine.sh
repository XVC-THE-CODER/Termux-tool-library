#!/data/data/com.termux/files/usr/bin/bash
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
M='\033[1;35m'
NC='\033[0m'
LANG_FILE="$HOME/.as_lang"
SAVE_FILE="$HOME/.rbx_saves"
SELECTED=""
VERSION="1.3"
ROBLOX_PLAYER_URL="https://www.roblox.com/users/"
ROBLOX_PLAYER_DEEP="roblox://users/"
norm() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | xargs
}
gen_uuid() {
    cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "cfed5fc6-80be-4d6f-ac0a-d95126cf2b39"
}
auto_line() {
    local cols=$(tput cols 2>/dev/null)
    if [ -z "$cols" ]; then cols=${COLUMNS:-60}; fi
    if [ "$cols" -gt 120 ]; then cols=120; fi
    if [ "$cols" -lt 20 ]; then cols=30; fi
    printf '═%.0s' $(seq 1 $cols)
}
closest_match() {
    local input="$1"
    shift
    local cands=("$@")
    python3 -c "
import sys
def lev(a,b):
    if len(a)<len(b):
        return lev(b,a)
    if len(b)==0:
        return len(a)
    prev=list(range(len(b)+1))
    for i,ca in enumerate(a):
        cur=[i+1]
        for j,cb in enumerate(b):
            ins=prev[j+1]+1
            dels=cur[j]+1
            subs=prev[j]+(ca!=cb)
            cur.append(min(ins,dels,subs))
        prev=cur
    return prev[-1]
inp=sys.argv[1].lower()
best=''
bestd=999
for cand in sys.argv[2:]:
    d=lev(inp,cand.lower())
    if d<bestd:
        bestd=d
        best=cand
print(f'{best}|{bestd}')
" "$input" "${cands[@]}"
}
choose_lang() {
    clear
    echo -e "${C}$(auto_line)${NC}"
    echo -e "${W}  Pilih Bahasa / Choose Language${NC}"
    echo -e "${C}$(auto_line)${NC}"
    echo -e "${W}[1] Indonesia (id)${NC}"
    echo -e "${W}[2] English (en)${NC}"
    echo ""
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
show_sel() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${G}Bahasa Indonesia dipilih!${NC}"
    else
        echo -e "${G}English language selected!${NC}"
    fi
    sleep 1
    clear
}
show_cmd() {
    clear
    local line=$(auto_line)
    printf "${M}%s${NC}\n" '                 __                 __   '
    printf "${M}%s${NC}\n" '_____    _______/  |_  ______ _____/  |_ '
    printf "${M}%s${NC}\n" '\__  \  /  ___/\   __\/  ___//    \   __\'
    printf "${M}%s${NC}\n" ' / __ \_\___ \  |  |  \___ \|   |  \  |  '
    printf "${M}%s${NC}\n" '(____  /____  > |__| /____  >___|  /__|  '
    printf "${M}%s${NC}\n" '     \/     \/            \/     \/       '
    echo -e "${W}${line}${NC}"
    echo -e "${C}command${NC}"
    echo -e "${C}assistant 1.3${NC}"
    echo -e "${W}${line}${NC}"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${G}as up${NC}      - update github & restart (ringkas)"
        echo -e "${G}as update${NC}  - update github & restart"
        echo -e "${G}as roblox${NC}  - masuk Roblox lobby"
        echo -e "${G}as antilag${NC} - boost performa"
        echo -e "${G}as fileman${NC} - file manager hp"
        echo -e "${G}as lang <id/en>${NC} - ganti bahasa"
        echo -e "${G}as help${NC}  - panduan lengkap"
        echo -e "${G}exit${NC}     - keluar"
    else
        echo -e "${G}as up${NC}      - update github & restart (short)"
        echo -e "${G}as update${NC}  - update github & restart"
        echo -e "${G}as roblox${NC}  - enter Roblox lobby"
        echo -e "${G}as antilag${NC} - boost performance"
        echo -e "${G}as fileman${NC} - phone file manager"
        echo -e "${G}as lang <id/en>${NC} - change language"
        echo -e "${G}as help${NC}  - full guide"
        echo -e "${G}exit${NC}     - exit"
    fi
    echo -e "${W}${line}${NC}"
}
show_assistant_help() {
    clear
    local line=$(auto_line)
    printf "${M}%s${NC}\n" '                 __                 __   '
    printf "${M}%s${NC}\n" '_____    _______/  |_  ______ _____/  |_ '
    printf "${M}%s${NC}\n" '\__  \  /  ___/\   __\/  ___//    \   __\'
    printf "${M}%s${NC}\n" ' / __ \_\___ \  |  |  \___ \|   |  \  |  '
    printf "${M}%s${NC}\n" '(____  /____  > |__| /____  >___|  /__|  '
    printf "${M}%s${NC}\n" '     \/     \/            \/     \/       '
    echo -e "${W}${line}${NC}"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}=== PANDUAN ASSISTANT - FULL & SINGKAT ===${NC}"
        echo -e "${W}Bahasa: Indonesia${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}1. as up / as update${NC} - update github & restart"
        echo -e ""
        echo -e "${G}2. as roblox${NC} - masuk Roblox lobby (auto-correct jika typo)"
        echo -e ""
        echo -e "${G}3. as antilag${NC} - boost performa"
        echo -e ""
        echo -e "${G}4. as fileman${NC} - file manager hp"
        echo -e ""
        echo -e "${G}5. as lang <id/en>${NC} - ganti bahasa"
        echo -e ""
        echo -e "${G}6. as help${NC} - panduan ini"
        echo -e ""
        echo -e "${G}7. exit${NC} - keluar"
        echo -e "${W}${line}${NC}"
        echo -e "${Y}Fitur auto-correct: jika typo seperti as rploc akan ditanya y/n${NC}"
    else
        echo -e "${C}=== ASSISTANT GUIDE - FULL & SHORT ===${NC}"
        echo -e "${W}Language: English${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}1. as up / as update${NC} - update github & restart"
        echo -e ""
        echo -e "${G}2. as roblox${NC} - enter Roblox lobby (auto-correct on typo)"
        echo -e ""
        echo -e "${G}3. as antilag${NC} - boost performance"
        echo -e ""
        echo -e "${G}4. as fileman${NC} - phone file manager"
        echo -e ""
        echo -e "${G}5. as lang <id/en>${NC} - change language"
        echo -e ""
        echo -e "${G}6. as help${NC} - this guide"
        echo -e ""
        echo -e "${G}7. exit${NC} - exit assistant"
        echo -e "${W}${line}${NC}"
        echo -e "${Y}Auto-correct: typo like as rploc will ask y/n${NC}"
    fi
    echo ""
    if [ "$SELECTED" = "id" ]; then
        read -p "Tekan ENTER untuk kembali: " _
    else
        read -p "Press ENTER to back: " _
    fi
    show_cmd
}
show_roblox_lobby_v16() {
    clear
    local line=$(auto_line)
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}rbx playgame <id>${NC} - join map"
        echo -e "${G}rbx playersearch <id>${NC} - cari player"
        echo -e "${G}rbx save <name> <id>${NC} - simpan map"
        echo -e "${G}rbx listjoin [name/angka]${NC} - join dari save"
        echo -e "${G}rbx rmls [name/angka]${NC} - hapus save"
        echo -e "${G}rbx searchgame <keyword>${NC} - cari game mirip keyword (5 pencari background)"
        echo -e "${G}help${NC} - panduan lengkap & singkat"
        echo -e "${G}exit${NC} - keluar lobby"
        echo -e "${W}${line}${NC}"
    else
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}rbx playgame <id>${NC} - join map"
        echo -e "${G}rbx playersearch <id>${NC} - find player"
        echo -e "${G}rbx save <name> <id>${NC} - save map"
        echo -e "${G}rbx listjoin [name/number]${NC} - join saved"
        echo -e "${G}rbx rmls [name/number]${NC} - delete saved"
        echo -e "${G}rbx searchgame <keyword>${NC} - search games similar to keyword (5 background searchers)"
        echo -e "${G}help${NC} - full & short guide"
        echo -e "${G}exit${NC} - exit lobby"
        echo -e "${W}${line}${NC}"
    fi
}
show_roblox_help() {
    clear
    local line=$(auto_line)
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}=== PANDUAN ROBLOX LOBBY - FULL & SINGKAT ===${NC}"
        echo -e "${W}Bahasa: Indonesia${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}1. rbx playgame <id>${NC} - join map"
        echo -e ""
        echo -e "${G}2. rbx playersearch <id>${NC} - cari player"
        echo -e ""
        echo -e "${G}3. rbx save <name> <id>${NC} - simpan map"
        echo -e ""
        echo -e "${G}4. rbx listjoin [name/angka]${NC} - join dari save"
        echo -e ""
        echo -e "${G}5. rbx rmls [name/angka]${NC} - hapus save"
        echo -e ""
        echo -e "${G}6. rbx searchgame <keyword>${NC} - cari game mirip"
        echo -e "${W}   instant: searchgame <keyword>${NC}"
        echo -e "${W}   spasi otomatis jadi - untuk pencocokan${NC}"
        echo -e "${W}   5 pencari background, filter 404, bisa lebih dari 1 hasil${NC}"
        echo -e ""
        echo -e "${G}7. help${NC} - panduan ini"
        echo -e ""
        echo -e "${G}8. exit${NC} - keluar lobby"
        echo -e "${W}${line}${NC}"
    else
        echo -e "${C}=== ROBLOX LOBBY GUIDE - FULL & SHORT ===${NC}"
        echo -e "${W}Language: English${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}1. rbx playgame <id>${NC} - join map"
        echo -e ""
        echo -e "${G}2. rbx playersearch <id>${NC} - find player"
        echo -e ""
        echo -e "${G}3. rbx save <name> <id>${NC} - save map"
        echo -e ""
        echo -e "${G}4. rbx listjoin [name/number]${NC} - join saved"
        echo -e ""
        echo -e "${G}5. rbx rmls [name/number]${NC} - delete saved"
        echo -e ""
        echo -e "${G}6. rbx searchgame <keyword>${NC} - search similar games"
        echo -e "${W}   instant: searchgame <keyword>${NC}"
        echo -e "${W}   spaces become - for matching${NC}"
        echo -e "${W}   5 background searchers, 404 filter, multiple results${NC}"
        echo -e ""
        echo -e "${G}7. help${NC} - this guide"
        echo -e ""
        echo -e "${G}8. exit${NC} - exit lobby"
        echo -e "${W}${line}${NC}"
    fi
    echo ""
    if [ "$SELECTED" = "id" ]; then
        read -p "Tekan ENTER untuk kembali: " _
    else
        read -p "Press ENTER to back: " _
    fi
    show_roblox_lobby_v16
}
find_available_server() {
    local placeId="$1"
    [ -z "$placeId" ] && echo "" && return
    command -v curl >/dev/null 2>&1 || { echo ""; return; }
    local universeJson=$(curl -s "https://apis.roblox.com/universes/v1/places/${placeId}/universe" --max-time 5 2>/dev/null)
    local universeId=$(echo "$universeJson" | grep -o '"universeId":[0-9]*' | head -n1 | cut -d: -f2)
    [ -z "$universeId" ] && echo "" && return
    local serversJson=$(curl -s "https://games.roblox.com/v1/games/${universeId}/servers/Public?limit=100&sortOrder=Asc" --max-time 7 2>/dev/null)
    local serverId=""
    if command -v python3 >/dev/null 2>&1; then
        serverId=$(echo "$serversJson" | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin)
    for s in data.get('data',[]):
        maxp=s.get('maxPlayers',10)
        playing=s.get('playing',10)
        if playing < maxp - 1:
            print(s.get('id',''))
            break
except:
    pass
" 2>/dev/null)
    fi
    echo "$serverId"
}
roblox_join_by_id() {
    local id="$1"
    [ -z "$id" ] && return
    local serverId=$(find_available_server "$id" 2>/dev/null)
    local uuid=$(gen_uuid)
    local inner=""
    if [ -n "$serverId" ]; then
        inner="https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3Fplaceid%3D${id}%26gameInstanceId%3D${serverId}%26joinAttemptId%3D${uuid}"
    else
        inner="https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3Fplaceid%3D${id}%26joinAttemptId%3D${uuid}"
    fi
    local link="https://ro.blox.com/Ebh5?is_retargeting=false&pid=experiencestart_mobileweb&af_dp=${inner}&af_web_dp=${inner}&deep_link_value=${inner}"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${G}Join map ID: $id${NC}"
    else
        echo -e "${G}Joining map ID: $id${NC}"
    fi
    termux-open-url "$link" >/dev/null 2>&1
    am start -a android.intent.action.VIEW -d "$link" >/dev/null 2>&1
}
save_rbx() {
    local name="$1"
    local id="$2"
    [ -z "$name" ] || [ -z "$id" ] && return
    name=$(echo "$name" | sed 's/ /_/g' | xargs)
    touch "$SAVE_FILE"
    grep -v "^${name}|" "$SAVE_FILE" 2>/dev/null > "${SAVE_FILE}.tmp" || true
    mv "${SAVE_FILE}.tmp" "$SAVE_FILE" 2>/dev/null || true
    echo "${name}|${id}" >> "$SAVE_FILE"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${G}Disimpan: $name -> $id${NC}"
    else
        echo -e "${G}Saved: $name -> $id${NC}"
    fi
}
list_rbx() {
    if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Belum ada save-an${NC}"
        else
            echo -e "${Y}No saved maps${NC}"
        fi
        return 1
    fi
    local i=1
    while IFS='|' read -r n mid; do
        [ -z "$n" ] && continue
        echo -e "${W}${i}. ${G}${n}${NC} ${W}- ${mid}${NC}"
        i=$((i+1))
    done < "$SAVE_FILE"
    return 0
}
get_rbx_by_num() {
    local num="$1"
    local line=$(sed -n "${num}p" "$SAVE_FILE" 2>/dev/null)
    [ -z "$line" ] && return 1
    echo "$line" | cut -d'|' -f2
}
get_rbx_by_name() {
    local sname="$1"
    sname=$(echo "$sname" | sed 's/ /_/g')
    grep -i "^${sname}|" "$SAVE_FILE" 2>/dev/null | head -n 1 | cut -d'|' -f2
}
delete_rbx_by_name() {
    local sname=$(echo "$1" | sed 's/ /_/g')
    grep -v -i "^${sname}|" "$SAVE_FILE" 2>/dev/null > "${SAVE_FILE}.tmp"
    mv "${SAVE_FILE}.tmp" "$SAVE_FILE" 2>/dev/null
}
rbx_searchgame() {
    local raw_kw="$1"
    raw_kw=$(echo "$raw_kw" | xargs)
    if [ -z "$raw_kw" ]; then
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Contoh: rbx searchgame Steal an Egg${NC}"
        else
            echo -e "${Y}Example: rbx searchgame Steal an Egg${NC}"
        fi
        return
    fi
    local kw_lower=$(echo "$raw_kw" | tr '[:upper:]' '[:lower:]' | xargs)
    local kw_hyphen=$(echo "$kw_lower" | sed 's/ /-/g')
    local kw_nospace=$(echo "$kw_lower" | sed 's/ //g')
    local TMPDIR="/data/data/com.termux/files/usr/tmp/rbx_search_$$"
    mkdir -p "$TMPDIR"
    local RESULTS="$TMPDIR/results.txt"
    > "$RESULTS"
    local FOUND="$TMPDIR/found"
    > "$FOUND"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Mencari game mirip: ${W}$raw_kw${NC}"
        echo -e "${Y}Spasi otomatis jadi - untuk pencocokan: $kw_hyphen${NC}"
        echo -e "${Y}5 pencari berjalan di belakang layar, filter 404...${NC}"
    else
        echo -e "${C}Searching similar games: ${W}$raw_kw${NC}"
        echo -e "${Y}Spaces become - for matching: $kw_hyphen${NC}"
        echo -e "${Y}5 searchers running in background, 404 filter...${NC}"
    fi
    worker_search() {
        local start_id=$1
        local wid=$2
        local scanned=0
        local max_scan=600
        local cur_id=$start_id
        while [ $scanned -lt $max_scan ]; do
            if [ $(wc -l < "$RESULTS" 2>/dev/null) -ge 15 ]; then
                break
            fi
            local json=$(curl -s --max-time 4 "https://api.roblox.com/marketplace/productinfo?assetId=$cur_id" 2>/dev/null)
            if [ -n "$json" ]; then
                if echo "$json" | grep -q '"Name"'; then
                    local name=$(echo "$json" | python3 -c "import sys,json; try: d=json.load(sys.stdin); print(d.get('Name','')) except: print('')" 2>/dev/null)
                    if [ -n "$name" ]; then
                        local lname=$(echo "$name" | tr '[:upper:]' '[:lower:]')
                        local match=0
                        if echo "$lname" | grep -qi "$kw_lower"; then
                            match=1
                        elif echo "$lname" | grep -qi "$kw_hyphen"; then
                            match=1
                        else
                            local all_words=1
                            for w in $kw_lower; do
                                if ! echo "$lname" | grep -qi "$w"; then
                                    all_words=0
                                    break
                                fi
                            done
                            if [ $all_words -eq 1 ]; then
                                match=1
                            fi
                        fi
                        if [ $match -eq 1 ]; then
                            if ! grep -q "^$cur_id|" "$RESULTS" 2>/dev/null; then
                                echo "$cur_id|$name" >> "$RESULTS"
                                echo -e "${G}[Pencari $wid] Ditemukan: $name - ID $cur_id${NC}"
                            fi
                        fi
                    fi
                fi
            fi
            cur_id=$((cur_id + 5))
            scanned=$((scanned + 1))
            if [ $((scanned % 50)) -eq 0 ]; then
                sleep 0.1
            fi
        done
    }
    worker_search 1 1 &
    worker_search 1000000 2 &
    worker_search 3000000 3 &
    worker_search 5000000 4 &
    worker_search 8000000 5 &
    wait
    sort -u "$RESULTS" -o "$RESULTS"
    if [ ! -s "$RESULTS" ]; then
        if [ "$SELECTED" = "id" ]; then
            echo -e "${R}Tidak ada game cocok untuk: $raw_kw${NC}"
        else
            echo -e "${R}No matching games for: $raw_kw${NC}"
        fi
        rm -rf "$TMPDIR"
        return
    fi
    echo ""
    echo -e "${W}$(auto_line)${NC}"
    echo -e "${C}Hasil ditemukan: $(wc -l < "$RESULTS") game${NC}"
    echo -e "${W}$(auto_line)${NC}"
    local idx=1
    while IFS='|' read -r gid gname; do
        echo -e "${W}${idx}. ${G}${gname}${NC} ${W}- ID ${gid}${NC}"
        idx=$((idx+1))
    done < "$RESULTS"
    echo -e "${W}$(auto_line)${NC}"
    if [ "$SELECTED" = "id" ]; then
        echo -e "${Y}Ketik nomor untuk join (0 batal, bisa lebih dari 1 dengan koma):${NC}"
    else
        echo -e "${Y}Enter number to join (0 cancel, multiple with comma):${NC}"
    fi
    read -p $'\033[1;37m┗━[pilih]<$ \033[0m' choice
    choice=$(echo "$choice" | xargs)
    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        rm -rf "$TMPDIR"
        return
    fi
    if echo "$choice" | grep -q ","; then
        IFS=',' read -ra nums <<< "$choice"
        for n in "${nums[@]}"; do
            n=$(echo "$n" | xargs)
            if echo "$n" | grep -Eq '^[0-9]+$'; then
                gid=$(sed -n "${n}p" "$RESULTS" | cut -d'|' -f1)
                if [ -n "$gid" ]; then
                    roblox_join_by_id "$gid"
                    sleep 1
                fi
            fi
        done
    else
        if echo "$choice" | grep -Eq '^[0-9]+$'; then
            gid=$(sed -n "${choice}p" "$RESULTS" | cut -d'|' -f1)
            if [ -n "$gid" ]; then
                roblox_join_by_id "$gid"
            fi
        fi
    fi
    rm -rf "$TMPDIR"
}
exploit_lobby() {
    clear
    local line=$(auto_line)
    if [ "$SELECTED" = "id" ]; then
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}rahasia - tidak ada di list Roblox lobby${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}exp search <keyword>${NC} - cari script (2 pilihan tersembunyi)"
        echo -e "${G}exit${NC} - kembali"
        echo -e "${W}${line}${NC}"
    else
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}secret - not in Roblox lobby list${NC}"
        echo -e "${W}${line}${NC}"
        echo -e "${G}exp search <keyword>${NC} - search script (2 hidden choices)"
        echo -e "${G}exit${NC} - back"
        echo -e "${W}${line}${NC}"
    fi
    while true; do
        echo ""
        echo -e "${W}┏━[exploit]┫${NC}"
        read -p $'\033[1;37m┗━<$ \033[0m' ecmd
        [ -z "$ecmd" ] && continue
        efull=$(norm "$ecmd")
        earg=$(echo "$ecmd" | cut -d' ' -f3- | xargs)
        case "$efull" in
            exp\ search* )
                if [ -z "$earg" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Contoh: exp search Steal an Egg${NC}"
                    else
                        echo -e "${Y}Example: exp search Steal an Egg${NC}"
                    fi
                else
                    search_plus=$(echo "$earg" | sed 's/ /+/g')
                    search_enc=$(echo "$earg" | sed 's/ /%20/g')
                    link1="https://scriptblox.com/?q=${search_plus}"
                    link2="https://rscripts.net/scripts?search=${search_enc}&focus=1"
                    echo ""
                    echo -e "${C}Hasil untuk: ${W}$earg${NC}"
                    echo -e "${W}$(auto_line)${NC}"
                    echo -e "${W}[1] ${G}ScriptBlox${NC}"
                    echo -e "${W}[2] ${G}RScripts${NC}"
                    echo -e "${W}$(auto_line)${NC}"
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Pilih angka depan 1-2 untuk buka (0 batal, link disembunyikan):${NC}"
                    else
                        echo -e "${Y}Choose front number 1-2 to open (0 cancel, link hidden):${NC}"
                    fi
                    read -p $'\033[1;37m┗━[pilih]<$ \033[0m' choice
                    choice=$(echo "$choice" | xargs)
                    case "$choice" in
                        1)
                            termux-open-url "$link1" >/dev/null 2>&1
                            am start -a android.intent.action.VIEW -d "$link1" >/dev/null 2>&1
                            ;;
                        2)
                            termux-open-url "$link2" >/dev/null 2>&1
                            am start -a android.intent.action.VIEW -d "$link2" >/dev/null 2>&1
                            ;;
                        0|"")
                            ;;
                        *)
                            echo -e "${R}Pilihan tidak valid${NC}"
                            ;;
                    esac
                fi
                ;;
            exit|quit|q|keluar|00)
                show_roblox_lobby_v16
                break
                ;;
            *)
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Gunakan: exp search <keyword> / exit${NC}"
                else
                    echo -e "${Y}Use: exp search <keyword> / exit${NC}"
                fi
                ;;
        esac
    done
}
roblox_lobby() {
    show_roblox_lobby_v16
    while true; do
        echo ""
        echo -e "${W}┏━[Roblox]┫${NC}"
        read -p $'\033[1;37m┗━<$ \033[0m' rcmd
        [ -z "$rcmd" ] && continue
        rfull=$(norm "$rcmd")
        rbase=$(echo "$rfull" | awk '{if($1=="rbx") print $1" "$2; else print $1}')
        rargs=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?[a-zA-Z]+[ ]*//I' | xargs)
        case "$rfull" in
            rbx\ playgame* | playgame* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                if ! echo "$rid" | grep -Eq '^[0-9]+$'; then
                    rid=$(echo "$rcmd" | awk '{print $3}')
                fi
                if [ -z "$rid" ] || ! echo "$rid" | grep -Eq '^[0-9]+$'; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Contoh: rbx playgame 2753915549${NC}"
                    else
                        echo -e "${Y}Example: rbx playgame 2753915549${NC}"
                    fi
                else
                    roblox_join_by_id "$rid"
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ playersearch* | playersearch* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                if [ -z "$rid" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Contoh: rbx playersearch 123456${NC}"
                    else
                        echo -e "${Y}Example: rbx playersearch 123456${NC}"
                    fi
                else
                    termux-open-url "${ROBLOX_PLAYER_URL}${rid}/profile" >/dev/null 2>&1
                    am start -a android.intent.action.VIEW -d "${ROBLOX_PLAYER_DEEP}${rid}" >/dev/null 2>&1
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ save* | save* )
                save_args=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?save[ ]+//I' | xargs)
                if [ -z "$save_args" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        read -p "Masukkan nama save (0 untuk keluar): " sname_in
                    else
                        read -p "Enter save name (0 to exit): " sname_in
                    fi
                    sname_in=$(echo "$sname_in" | xargs)
                    if [ "$sname_in" = "0" ]; then
                        show_roblox_lobby_v16
                        continue
                    fi
                    if [ "$SELECTED" = "id" ]; then
                        read -p "Masukkan ID map (0 untuk keluar): " sid_in
                    else
                        read -p "Enter map ID (0 to exit): " sid_in
                    fi
                    sid_in=$(echo "$sid_in" | xargs)
                    if [ "$sid_in" = "0" ]; then
                        show_roblox_lobby_v16
                        continue
                    fi
                    save_rbx "$sname_in" "$sid_in"
                else
                    if [ "$save_args" = "0" ]; then
                        show_roblox_lobby_v16
                        continue
                    fi
                    sid=$(echo "$save_args" | awk '{print $NF}')
                    if [ "$sid" = "0" ]; then
                        show_roblox_lobby_v16
                        continue
                    fi
                    if ! echo "$sid" | grep -Eq '^[0-9]+$'; then
                        if [ "$SELECTED" = "id" ]; then
                            read -p "Masukkan nama save (0 untuk keluar): " sname_in
                            read -p "Masukkan ID map (0 untuk keluar): " sid_in
                        else
                            read -p "Enter save name (0 to exit): " sname_in
                            read -p "Enter map ID (0 to exit): " sid_in
                        fi
                        sname_in=$(echo "$sname_in" | xargs)
                        sid_in=$(echo "$sid_in" | xargs)
                        if [ "$sname_in" = "0" ] || [ "$sid_in" = "0" ]; then
                            show_roblox_lobby_v16
                            continue
                        fi
                        save_rbx "$sname_in" "$sid_in"
                    else
                        sname=$(echo "$save_args" | rev | cut -d' ' -f2- | rev | xargs)
                        if [ "$sname" = "0" ]; then
                            show_roblox_lobby_v16
                            continue
                        fi
                        save_rbx "$sname" "$sid"
                    fi
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ listjoin* | listjoin* )
                arg=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?listjoin[ ]*//I' | xargs)
                if [ "$arg" = "0" ]; then
                    show_roblox_lobby_v16
                    continue
                fi
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Belum ada save-an${NC}"
                    else
                        echo -e "${Y}No saved maps${NC}"
                    fi
                else
                    if [ -z "$arg" ]; then
                        list_rbx
                        echo ""
                        if [ "$SELECTED" = "id" ]; then
                            read -p "Masukkan angka save (0 untuk keluar): " num
                        else
                            read -p "Enter save number (0 to exit): " num
                        fi
                        num=$(echo "$num" | xargs)
                        if [ "$num" = "0" ]; then
                            show_roblox_lobby_v16
                            continue
                        fi
                        join_id=$(get_rbx_by_num "$num")
                        if [ -z "$join_id" ]; then
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${R}Nomor tidak ditemukan${NC}"
                            else
                                echo -e "${R}Number not found${NC}"
                            fi
                        else
                            roblox_join_by_id "$join_id"
                        fi
                    else
                        if echo "$arg" | grep -Eq '^[0-9]+$'; then
                            join_id=$(get_rbx_by_num "$arg")
                        else
                            join_id=$(get_rbx_by_name "$arg")
                        fi
                        if [ -z "$join_id" ]; then
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${R}Save tidak ditemukan${NC}"
                            else
                                echo -e "${R}Save not found${NC}"
                            fi
                        else
                            roblox_join_by_id "$join_id"
                        fi
                    fi
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ rmls* | rmls* )
                arg=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?rmls[ ]*//I' | xargs)
                if [ "$arg" = "0" ]; then
                    show_roblox_lobby_v16
                    continue
                fi
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Belum ada save-an${NC}"
                    else
                        echo -e "${Y}No saved maps${NC}"
                    fi
                else
                    if [ -z "$arg" ]; then
                        list_rbx
                        echo ""
                        if [ "$SELECTED" = "id" ]; then
                            read -p "Masukkan angka yang mau dihapus (0 untuk keluar): " delnum
                        else
                            read -p "Enter number to delete (0 to exit): " delnum
                        fi
                        delnum=$(echo "$delnum" | xargs)
                        if [ "$delnum" = "0" ]; then
                            show_roblox_lobby_v16
                            continue
                        fi
                        if echo "$delnum" | grep -Eq '^[0-9]+$'; then
                            sed -i "${delnum}d" "$SAVE_FILE"
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${G}Dihapus nomor $delnum${NC}"
                            else
                                echo -e "${G}Deleted number $delnum${NC}"
                            fi
                        fi
                    else
                        if echo "$arg" | grep -Eq '^[0-9]+$'; then
                            sed -i "${arg}d" "$SAVE_FILE"
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${G}Dihapus nomor $arg${NC}"
                            else
                                echo -e "${G}Deleted number $arg${NC}"
                            fi
                        else
                            delete_rbx_by_name "$arg"
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${G}Dihapus: $arg${NC}"
                            else
                                echo -e "${G}Deleted: $arg${NC}"
                            fi
                        fi
                    fi
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ searchgame* | searchgame* )
                kw=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?searchgame[ ]*//I' | xargs)
                rbx_searchgame "$kw"
                sleep 1
                show_roblox_lobby_v16
                ;;
            help )
                show_roblox_help
                ;;
            exploit )
                exploit_lobby
                ;;
            exit|quit|q|keluar)
                clear
                show_cmd
                break
                ;;
            *)
                valid_rbx=("rbx playgame" "playgame" "rbx playersearch" "playersearch" "rbx save" "save" "rbx listjoin" "listjoin" "rbx rmls" "rmls" "rbx searchgame" "searchgame" "help" "exit" "exploit")
                cm=$(closest_match "$rbase" "${valid_rbx[@]}")
                sug=$(echo "$cm" | cut -d'|' -f1)
                dist=$(echo "$cm" | cut -d'|' -f2)
                if [ -n "$sug" ] && [ "$dist" -le 3 ] && [ "$dist" -gt 0 ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Apakah maksud Anda '${sug}'? (y/n)${NC}"
                    else
                        echo -e "${Y}Did you mean '${sug}'? (y/n)${NC}"
                    fi
                    read -p $'\033[1;37m┗━[y/n]<$ \033[0m' yn
                    yn=$(norm "$yn")
                    if [ "$yn" = "y" ] || [ "$yn" = "yes" ]; then
                        if echo "$sug" | grep -q "playgame\|playersearch\|save\|listjoin\|rmls\|searchgame"; then
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${Y}Ketik ulang dengan argumen, contoh: $sug <id/keyword>${NC}"
                            else
                                echo -e "${Y}Retype with args, example: $sug <id/keyword>${NC}"
                            fi
                        else
                            rcmd="$sug"
                            rfull=$(norm "$rcmd")
                            case "$rfull" in
                                help) show_roblox_help ;;
                                exploit) exploit_lobby ;;
                                exit|quit|q|keluar) clear; show_cmd; break ;;
                            esac
                        fi
                    fi
                else
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Perintah tidak dikenal. Ketik 'help' untuk panduan${NC}"
                    else
                        echo -e "${Y}Unknown command. Type 'help' for guide${NC}"
                    fi
                    sleep 1
                    show_roblox_lobby_v16
                fi
                ;;
        esac
    done
}
run_fileman() {
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 2
    fi
    command -v nano >/dev/null 2>&1 || pkg install -y nano >/dev/null 2>&1
    CUR_DIR="/sdcard"
    [ ! -d "$CUR_DIR" ] && CUR_DIR="$HOME"
    while true; do
        clear
        local line=$(auto_line)
        echo -e "${C}File Manager - $CUR_DIR${NC}"
        echo -e "${W}${line}${NC}"
        mapfile -t ENTRIES < <(ls "$CUR_DIR" 2>/dev/null)
        if [ ${#ENTRIES[@]} -eq 0 ]; then
            if [ "$SELECTED" = "id" ]; then
                echo -e "${Y}Folder kosong${NC}"
            else
                echo -e "${Y}Empty folder${NC}"
            fi
        else
            i=1
            for e in "${ENTRIES[@]}"; do
                if [ -d "$CUR_DIR/$e" ]; then
                    echo -e "${W}${i}. ${B}${e}${NC}"
                else
                    echo -e "${W}${i}. ${W}${e}${NC}"
                fi
                i=$((i+1))
            done
        fi
        echo -e "${W}${line}${NC}"
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Ketik angka 1-infinite untuk pilih file/folder${NC}"
            echo -e "${Y}Ketik 00 untuk kembali, 0 untuk keluar (hidden tetap tersembunyi)${NC}"
        else
            echo -e "${Y}Type number 1-infinite to select file/folder${NC}"
            echo -e "${Y}Type 00 to go back, 0 to exit (hidden stays hidden)${NC}"
        fi
        echo ""
        echo -e "${W}┏━[fileman]┫${NC}"
        read -p $'\033[1;37m┗━<$ \033[0m' finp
        finp_trim=$(echo "$finp" | xargs)
        [ -z "$finp_trim" ] && continue
        if [ "$finp_trim" = "0" ]; then
            clear
            show_cmd
            break
        fi
        if [ "$finp_trim" = "00" ]; then
            if [ "$CUR_DIR" = "/sdcard" ] || [ "$CUR_DIR" = "/storage/emulated/0" ] || [ "$CUR_DIR" = "$HOME" ] || [ "$CUR_DIR" = "/" ]; then
                clear
                show_cmd
                break
            else
                CUR_DIR=$(dirname "$CUR_DIR")
                continue
            fi
        fi
        if echo "$finp_trim" | grep -Eq '^[0-9]+$'; then
            num=$finp_trim
            if [ "$num" -ge 1 ] && [ "$num" -le ${#ENTRIES[@]} ]; then
                sel="${ENTRIES[$((num-1))]}"
                tpath="$CUR_DIR/$sel"
                if [ -d "$tpath" ]; then
                    CUR_DIR="$tpath"
                else
                    while true; do
                        clear
                        local line2=$(auto_line)
                        echo -e "${C}File: $sel${NC}"
                        echo -e "${W}${line2}${NC}"
                        if [ "$SELECTED" = "id" ]; then
                            echo -e "${W}1. buka${NC}"
                            echo -e "${W}2. hapus${NC}"
                            echo -e "${W}3. duplikat${NC}"
                            echo -e "${W}4. pindah${NC}"
                            echo -e "${W}5. ganti nama${NC}"
                            echo -e "${W}0. batal${NC}"
                        else
                            echo -e "${W}1. open${NC}"
                            echo -e "${W}2. delete${NC}"
                            echo -e "${W}3. dupe${NC}"
                            echo -e "${W}4. move${NC}"
                            echo -e "${W}5. rename${NC}"
                            echo -e "${W}0. cancel${NC}"
                        fi
                        echo -e "${W}${line2}${NC}"
                        read -p "Pilih> " opt
                        opt=$(echo "$opt" | xargs)
                        case "$opt" in
                            1)
                                if echo "$tpath" | grep -qi "\.apk$"; then
                                    termux-open "$tpath" >/dev/null 2>&1
                                    am start -a android.intent.action.VIEW -d "file://$tpath" -t "application/vnd.android.package-archive" >/dev/null 2>&1
                                else
                                    nano "$tpath"
                                fi
                                break
                                ;;
                            2)
                                if [ "$SELECTED" = "id" ]; then
                                    read -p "Yakin hapus $sel? (y/n): " conf
                                else
                                    read -p "Delete $sel? (y/n): " conf
                                fi
                                if [ "$conf" = "y" ] || [ "$conf" = "Y" ]; then
                                    rm -rf "$tpath"
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${G}Dihapus${NC}"
                                    else
                                        echo -e "${G}Deleted${NC}"
                                    fi
                                    sleep 1
                                fi
                                break
                                ;;
                            3)
                                base=$(basename "$tpath")
                                dir=$(dirname "$tpath")
                                ext="${base##*.}"
                                name="${base%.*}"
                                if [ "$name" = "$ext" ]; then
                                    cp "$tpath" "$dir/${base}_copy"
                                else
                                    cp "$tpath" "$dir/${name}_copy.${ext}" 2>/dev/null || cp "$tpath" "$dir/${base}_copy"
                                fi
                                if [ "$SELECTED" = "id" ]; then
                                    echo -e "${G}Duplikat berhasil${NC}"
                                else
                                    echo -e "${G}Duplicated OK${NC}"
                                fi
                                sleep 1
                                break
                                ;;
                            4)
                                ORIG_FILE="$tpath"
                                DEST_DIR="$CUR_DIR"
                                while true; do
                                    clear
                                    local line3=$(auto_line)
                                    echo -e "${C}Pindah: $(basename "$ORIG_FILE")${NC}"
                                    echo -e "${W}Tujuan: $DEST_DIR${NC}"
                                    echo -e "${W}${line3}${NC}"
                                    mapfile -t MOVE_ENTRIES < <(ls "$DEST_DIR" 2>/dev/null)
                                    if [ ${#MOVE_ENTRIES[@]} -eq 0 ]; then
                                        if [ "$SELECTED" = "id" ]; then
                                            echo -e "${Y}Folder kosong${NC}"
                                        else
                                            echo -e "${Y}Empty folder${NC}"
                                        fi
                                    else
                                        i=1
                                        for me in "${MOVE_ENTRIES[@]}"; do
                                            if [ -d "$DEST_DIR/$me" ]; then
                                                echo -e "${W}${i}. ${B}${me}${NC}"
                                            else
                                                echo -e "${W}${i}. ${W}${me}${NC}"
                                            fi
                                            i=$((i+1))
                                        done
                                    fi
                                    echo -e "${W}${line3}${NC}"
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${Y}Ketik angka untuk masuk folder${NC}"
                                        echo -e "${Y}Ketik 00 untuk mundur ke folder sebelumnya${NC}"
                                        echo -e "${Y}Ketik 0 untuk pindahkan file ke folder ini${NC}"
                                    else
                                        echo -e "${Y}Type number to enter folder${NC}"
                                        echo -e "${Y}Type 00 to go back${NC}"
                                        echo -e "${Y}Type 0 to move file to this folder${NC}"
                                    fi
                                    echo ""
                                    echo -e "${W}┏━[move]┫${NC}"
                                    read -p $'\033[1;37m┗━<$ \033[0m' minp
                                    minp_trim=$(echo "$minp" | xargs)
                                    if [ "$minp_trim" = "0" ]; then
                                        mv "$ORIG_FILE" "$DEST_DIR/"
                                        if [ "$SELECTED" = "id" ]; then
                                            echo -e "${G}Dipindahkan ke $DEST_DIR${NC}"
                                        else
                                            echo -e "${G}Moved to $DEST_DIR${NC}"
                                        fi
                                        sleep 1
                                        break
                                    fi
                                    if [ "$minp_trim" = "00" ]; then
                                        if [ "$DEST_DIR" != "/sdcard" ] && [ "$DEST_DIR" != "/" ]; then
                                            DEST_DIR=$(dirname "$DEST_DIR")
                                        fi
                                        continue
                                    fi
                                    if echo "$minp_trim" | grep -Eq '^[0-9]+$'; then
                                        mnum=$minp_trim
                                        if [ "$mnum" -ge 1 ] && [ "$mnum" -le ${#MOVE_ENTRIES[@]} ]; then
                                            msel="${MOVE_ENTRIES[$((mnum-1))]}"
                                            mpath="$DEST_DIR/$msel"
                                            if [ -d "$mpath" ]; then
                                                DEST_DIR="$mpath"
                                            fi
                                        fi
                                    fi
                                done
                                break
                                ;;
                            5)
                                if [ "$SELECTED" = "id" ]; then
                                    read -p "Masukkan nama baru: " newname
                                else
                                    read -p "Enter new name: " newname
                                fi
                                newname=$(echo "$newname" | xargs)
                                if [ -n "$newname" ]; then
                                    mv "$tpath" "$(dirname "$tpath")/$newname"
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${G}Berhasil ganti nama${NC}"
                                    else
                                        echo -e "${G}Renamed OK${NC}"
                                    fi
                                    sleep 1
                                fi
                                break
                                ;;
                            0) break ;;
                            *)
                                if [ "$SELECTED" = "id" ]; then
                                    echo -e "${Y}Pilihan tidak valid${NC}"
                                else
                                    echo -e "${Y}Invalid choice${NC}"
                                fi
                                sleep 1
                                ;;
                        esac
                    done
                fi
            fi
        fi
    done
}
run_antilag() {
    clear
    local line=$(auto_line)
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Menjalankan tool boost-performance terbaru...${NC}"
    else
        echo -e "${C}Running latest boost-performance tool...${NC}"
    fi
    echo -e "${W}${line}${NC}"
    cd ~
    rm -rf Termux-tool-library 2>/dev/null
    pkg update -y
    pkg install -y git
    git clone https://github.com/XVC-THE-CODER/Termux-tool-library.git
    cd Termux-tool-library
    cd boost-performance
    chmod +x command.sh main-engine.sh
    bash command.sh
    bash main-engine.sh
    cd ~
    if [ "$SELECTED" = "id" ]; then
        echo -e "${G}Selesai, kembali ke menu utama...${NC}"
    else
        echo -e "${G}Done, back to main menu...${NC}"
    fi
    sleep 1
    clear
}
do_update() {
    clear
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
if [ -f "$LANG_FILE" ] && [ "$1" != "--reset-lang" ]; then
    saved=$(norm "$(cat $LANG_FILE)")
    if [[ "$saved" == "id" || "$saved" == "en" ]]; then
        SELECTED=$saved
    else
        choose_lang
    fi
else
    choose_lang
fi
show_sel
show_cmd
while true; do
    echo ""
    echo -e "${W}┏━[assistant]┫${NC}"
    read -p $'\033[1;37m┗━<$ \033[0m' cmd
    [ -z "$cmd" ] && continue
    full=$(norm "$cmd")
    lang_arg=$(echo "$cmd" | cut -d' ' -f3- | xargs)
    base_cmd=$(echo "$full" | awk '{print $1" "$2}' | xargs)
    if [ -z "$base_cmd" ]; then base_cmd="$full"; fi
    case "$full" in
        "as update"|"as up") do_update ;;
        "as roblox"|"roblox"|"rbx") roblox_lobby ;;
        "as antilag") run_antilag; show_cmd ;;
        "as fileman") run_fileman ;;
        as\ lang* )
            if [ -z "$lang_arg" ]; then
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Contoh: as lang id${NC}"
                else
                    echo -e "${Y}Example: as lang id${NC}"
                fi
                continue
            fi
            larg=$(norm "$lang_arg")
            case "$larg" in
                1|2)
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${R}Angka tidak bisa${NC}"
                    else
                        echo -e "${R}Numbers not allowed${NC}"
                    fi
                    ;;
                id|indonesia|indo) SELECTED="id"; echo "$SELECTED" > "$LANG_FILE"; show_sel; show_cmd ;;
                en|english|inggris|eng) SELECTED="en"; echo "$SELECTED" > "$LANG_FILE"; show_sel; show_cmd ;;
                *)
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${R}Bahasa tidak dikenal${NC}"
                    else
                        echo -e "${R}Unknown language${NC}"
                    fi
                    ;;
            esac
            ;;
        "as help"|"help") show_assistant_help ;;
        "exit"|"quit"|"q")
            cd ~
            exit 0
            ;;
        *)
            valid_main=("as update" "as up" "as roblox" "as antilag" "as fileman" "as lang" "as help" "exit" "roblox" "rbx")
            check_input=$(echo "$full" | awk '{print $1" "$2}' | xargs)
            if [ -z "$(echo "$full" | grep " ")" ]; then
                check_input="$full"
            fi
            cm=$(closest_match "$check_input" "${valid_main[@]}")
            sug=$(echo "$cm" | cut -d'|' -f1)
            dist=$(echo "$cm" | cut -d'|' -f2)
            if [ -n "$sug" ] && [ "$dist" -le 3 ] && [ "$dist" -gt 0 ]; then
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Apakah maksud Anda '${sug}'? (y/n)${NC}"
                else
                    echo -e "${Y}Did you mean '${sug}'? (y/n)${NC}"
                fi
                read -p $'\033[1;37m┗━[y/n]<$ \033[0m' yn
                yn=$(norm "$yn")
                if [ "$yn" = "y" ] || [ "$yn" = "yes" ]; then
                    case "$sug" in
                        "as update"|"as up") do_update ;;
                        "as roblox"|"roblox"|"rbx") roblox_lobby ;;
                        "as antilag") run_antilag; show_cmd ;;
                        "as fileman") run_fileman ;;
                        "as lang") 
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${Y}Contoh: as lang id${NC}"
                            else
                                echo -e "${Y}Example: as lang id${NC}"
                            fi
                            ;;
                        "as help"|"help") show_assistant_help ;;
                        "exit") cd ~; exit 0 ;;
                    esac
                fi
            else
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Perintah tidak dikenal${NC}"
                else
                    echo -e "${Y}Unknown command${NC}"
                fi
            fi
            ;;
    esac
done
