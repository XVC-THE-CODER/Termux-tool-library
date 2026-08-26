#!/data/data/com.termux/files/usr/bin/bash

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

LANG_FILE="$HOME/.as_lang"
SAVE_FILE="$HOME/.rbx_saves"
SELECTED=""

ROBLOX_PLAYER_URL="https://www.roblox.com/users/"
ROBLOX_PLAYER_DEEP="roblox://users/"

norm() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | xargs
}

gen_uuid() {
    cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "cfed5fc6-80be-4d6f-ac0a-d95126cf2b39"
}

choose_lang() {
    clear
    echo -e "${C}================================${NC}"
    echo -e "${W}  Pilih Bahasa / Choose Language${NC}"
    echo -e "${C}================================${NC}"
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
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}command assistant${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}as update${NC}  - update via github & restart"
        echo -e "${G}as roblox${NC}  - masuk ke Roblox lobby"
        echo -e "${G}as antilag${NC} - boost performance"
        echo -e "${G}as fileman${NC} - file manager hp full akses"
        echo -e "${G}as lang <id/en>${NC} - ganti bahasa"
        echo -e "${G}exit${NC}     - keluar"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}command assistant${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}as update${NC}  - update via github & restart"
        echo -e "${G}as roblox${NC}  - enter Roblox lobby"
        echo -e "${G}as antilag${NC} - boost performance"
        echo -e "${G}as fileman${NC} - full phone file manager"
        echo -e "${G}as lang <id/en>${NC} - change language"
        echo -e "${G}exit${NC}     - exit"
        echo -e "${W}------------------------------${NC}"
    fi
}

# Bentuk Roblox lobby mirip v16 - sama di semua tempat
show_roblox_lobby_v16() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}playgame <id> / rbx playgame <id>${NC} - langsung masuk ke map (auto server tidak penuh)"
        echo -e "${G}searchgame <keyword> / rbx searchgame <keyword>${NC} - cari game via discover (max 25, next 26-50)"
        echo -e "${G}playersearch <id> / rbx playersearch <id>${NC} - cari player"
        echo -e "${G}save <name> <id> / rbx save <name> <id>${NC} - simpan map (spasi jadi _)"
        echo -e "${G}listjoin [name/angka] / rbx listjoin [name/angka]${NC} - join dari save pakai nomor"
        echo -e "${G}rmls [name/angka] / rbx rmls [name/angka]${NC} - hapus save dari database"
        echo -e "${G}exit${NC} - keluar dari Roblox lobby"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}playgame <id> / rbx playgame <id>${NC} - join map (auto non-full server)"
        echo -e "${G}searchgame <keyword> / rbx searchgame <keyword>${NC} - search game via discover"
        echo -e "${G}playersearch <id> / rbx playersearch <id>${NC} - search player"
        echo -e "${G}save <name> <id> / rbx save <name> <id>${NC} - save map (space to _)"
        echo -e "${G}listjoin [name/number] / rbx listjoin${NC} - join from save"
        echo -e "${G}rmls [name/number] / rbx rmls${NC} - delete save"
        echo -e "${G}exit${NC} - exit from Roblox lobby"
        echo -e "${W}------------------------------${NC}"
    fi
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
        echo -e "${G}Join map ID: $id (auto server tidak penuh)${NC}"
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
    echo -e "${G}Disimpan: $name -> $id${NC}"
}

list_rbx() {
    if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
        echo -e "${Y}Belum ada save-an${NC}"
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

search_roblox_games() {
    local keyword="$1"
    [ -z "$keyword" ] && return
    local encoded=$(echo "$keyword" | sed 's/ /%20/g')
    local plus=$(echo "$keyword" | sed 's/ /+/g')

    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Mencari game: $keyword ... (background, tidak buka browser)${NC}"
    else
        echo -e "${C}Searching: $keyword ... (background)${NC}"
    fi

    declare -a GAME_IDS
    declare -a GAME_NAMES
    declare -A seen

    for attempt in 1 2 3; do
        local html=""
        if [ $attempt -eq 1 ]; then
            html=$(curl -s -L -A "Mozilla/5.0 (Linux; Android 10)" "https://www.roblox.com/discover/?Keyword=${encoded}" --max-time 10 2>/dev/null)
        elif [ $attempt -eq 2 ]; then
            html=$(curl -s -L -A "Mozilla/5.0" "https://www.roblox.com/search?Keyword=${encoded}" --max-time 10 2>/dev/null)
        else
            html=$(curl -s -L -A "Mozilla/5.0" "https://search.roblox.com/catalog/json?Category=All&Keyword=${plus}&MaxRows=100" --max-time 10 2>/dev/null)
        fi

        local games_raw=$(echo "$html" | grep -oE '/games/[0-9]+/[^"<> ?&#]+' | head -n 200)
        local place_raw=$(echo "$html" | grep -oE '"(rootPlaceId|placeId)":[0-9]+' | grep -oE '[0-9]+' | head -n 200)
        local combined="$games_raw $place_raw"

        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local id=""
            local raw_name=""
            local name=""
            if echo "$line" | grep -q '/games/'; then
                id=$(echo "$line" | cut -d'/' -f3)
                raw_name=$(echo "$line" | cut -d'/' -f4 | cut -d'?' -f1 | cut -d'"' -f1)
                name=$(echo "$raw_name" | sed 's/-/ /g' | sed 's/_/ /g' | xargs)
                [ -z "$name" ] && name="Game $id"
            else
                id=$(echo "$line" | grep -oE '[0-9]+' | head -n1)
                name="Game $id"
            fi
            [ -z "$id" ] && continue
            if [ -z "${seen[$id]}" ]; then
                seen[$id]=1
                GAME_IDS+=("$id")
                GAME_NAMES+=("$name")
            fi
        done <<< "$(echo "$combined" | tr ' ' '\n' | sort -u)"

        if [ ${#GAME_IDS[@]} -gt 5 ]; then
            break
        fi
    done

    if [ ${#GAME_IDS[@]} -eq 0 ]; then
        echo -e "${Y}Tidak ada game ditemukan untuk: $keyword${NC}"
        sleep 2
        return
    fi

    local page=0
    local page_size=25
    local total=${#GAME_IDS[@]}

    while true; do
        clear
        local start=$((page*page_size))
        local end=$((start+page_size))
        [ $end -gt $total ] && end=$total

        if [ "$SELECTED" = "id" ]; then
            echo -e "${C}=== HASIL PENCARIAN ROBLOX ===${NC}"
            echo -e "${W}Keyword: $keyword | Total: $total game | Menampilkan $((start+1))-$end${NC}"
        else
            echo -e "${C}=== ROBLOX SEARCH RESULTS ===${NC}"
            echo -e "${W}Keyword: $keyword | Total: $total | Showing $((start+1))-$end${NC}"
        fi
        echo -e "${W}------------------------------${NC}"
        for ((i=start; i<end; i++)); do
            num=$((i+1))
            echo -e "${W}${num}. ${G}${GAME_NAMES[$i]}${NC} ${W}- ${GAME_IDS[$i]}${NC}"
        done
        echo -e "${W}------------------------------${NC}"
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Ketik nomor (1-infinite) untuk pilih | 'next' untuk 26-50 | 'prev' kembali | '0' keluar${NC}"
        else
            echo -e "${Y}Type number (1-infinite) | 'next' 26-50 | 'prev' | '0' exit${NC}"
        fi
        echo ""
        read -p "searchgame> " choice
        choice=$(echo "$choice" | xargs | tr '[:upper:]' '[:lower:]')

        if [ "$choice" = "0" ] || [ "$choice" = "exit" ] || [ "$choice" = "q" ]; then
            break
        elif [ "$choice" = "next" ] || [ "$choice" = "lanjut" ] || [ "$choice" = "more" ]; then
            if [ $end -lt $total ]; then
                page=$((page+1))
            else
                echo -e "${Y}Sudah di halaman terakhir${NC}"
                sleep 1
            fi
            continue
        elif [ "$choice" = "prev" ] || [ "$choice" = "kembali" ] || [ "$choice" = "back" ] || [ "$choice" = "00" ]; then
            if [ $page -gt 0 ]; then
                page=$((page-1))
            fi
            continue
        elif echo "$choice" | grep -Eq '^[0-9]+$'; then
            sel_num=$choice
            if [ $sel_num -ge 1 ] && [ $sel_num -le $total ]; then
                idx=$((sel_num-1))
                sel_id=${GAME_IDS[$idx]}
                sel_name=${GAME_NAMES[$idx]}
                while true; do
                    clear
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${C}Game dipilih: $sel_name - $sel_id${NC}"
                        echo -e "${W}------------------------------${NC}"
                        echo -e "${G}1. play menggunakan ro.blox.com${NC}"
                        echo -e "${G}2. save ke listjoin (input nama, enter untuk save)${NC}"
                        echo -e "${G}0. batal${NC}"
                    else
                        echo -e "${C}Selected: $sel_name - $sel_id${NC}"
                        echo -e "${W}------------------------------${NC}"
                        echo -e "${G}1. play using ro.blox.com${NC}"
                        echo -e "${G}2. save to listjoin${NC}"
                        echo -e "${G}0. cancel${NC}"
                    fi
                    echo -e "${W}------------------------------${NC}"
                    read -p "Pilih> " opt
                    case "$opt" in
                        1) roblox_join_by_id "$sel_id"; sleep 1; break ;;
                        2)
                            if [ "$SELECTED" = "id" ]; then
                                read -p "Nama save (enter untuk '$sel_name'): " save_name
                            else
                                read -p "Save name (enter for '$sel_name'): " save_name
                            fi
                            save_name=$(echo "$save_name" | xargs)
                            [ -z "$save_name" ] && save_name="$sel_name"
                            save_rbx "$save_name" "$sel_id"
                            sleep 1
                            break
                            ;;
                        0) break ;;
                        *) echo -e "${Y}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
            fi
        fi
    done
}

exploit_lobby() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}command rahasia - tidak ditampilkan di Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}exp search <keyword>${NC} - cari script di ScriptBlox"
        echo -e "${G}exit${NC}                 - kembali ke Roblox lobby"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}hidden command${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}exp search <keyword>${NC} - search script"
        echo -e "${G}exit${NC}                 - back to Roblox lobby"
        echo -e "${W}------------------------------${NC}"
    fi

    while true; do
        echo ""
        read -p "exploit> " ecmd
        [ -z "$ecmd" ] && continue
        efull=$(norm "$ecmd")
        earg=$(echo "$ecmd" | cut -d' ' -f3- | xargs)

        case "$efull" in
            exp\ search* )
                if [ -z "$earg" ]; then
                    echo -e "${Y}Contoh: exp search speed hub x${NC}"
                else
                    search_plus=$(echo "$earg" | sed 's/ /+/g')
                    link="https://scriptblox.com/?q=${search_plus}"
                    echo -e "${C}[EXP] Mencari: $earg${NC}"
                    echo -e "${W}Link: $link${NC}"
                    termux-open-url "$link" >/dev/null 2>&1
                    am start -a android.intent.action.VIEW -d "$link" >/dev/null 2>&1
                fi
                ;;

            exit|quit|q|keluar|00)
                # Balik ke Roblox lobby dengan bentuk SAMA persis seperti v16 - exploit tidak masuk list tapi masih ada
                show_roblox_lobby_v16
                break
                ;;

            *)
                echo -e "${Y}Gunakan: exp search <keyword> / exit${NC}"
                ;;
        esac
    done
}

roblox_lobby() {
    # Tampilkan bentuk mirip v16 - sama di semua tempat
    show_roblox_lobby_v16

    while true; do
        echo ""
        read -p "roblox> " rcmd
        [ -z "$rcmd" ] && continue
        rfull=$(norm "$rcmd")

        case "$rfull" in
            rbx\ playgame* | playgame* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                if ! echo "$rid" | grep -Eq '^[0-9]+$'; then
                    rid=$(echo "$rcmd" | awk '{print $3}')
                fi
                if [ -z "$rid" ] || ! echo "$rid" | grep -Eq '^[0-9]+$'; then
                    echo -e "${Y}Contoh: playgame 2753915549${NC}"
                else
                    roblox_join_by_id "$rid"
                fi
                echo -e "${W}--- Roblox lobby tetap ada (tidak hilang) ---${NC}"
                sleep 1
                show_roblox_lobby_v16
                ;;

            rbx\ searchgame* | searchgame* )
                keyword=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?searchgame[ ]*//I' | xargs)
                if [ -z "$keyword" ]; then
                    echo -e "${Y}Contoh: searchgame steal an egg${NC}"
                else
                    search_roblox_games "$keyword"
                    # Setelah search selesai, tampilkan lagi bentuk SAMA persis v16
                    show_roblox_lobby_v16
                fi
                ;;

            rbx\ playersearch* | playersearch* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                if [ -z "$rid" ]; then
                    echo -e "${Y}Contoh: playersearch 123456${NC}"
                else
                    termux-open-url "${ROBLOX_PLAYER_URL}${rid}/profile" >/dev/null 2>&1
                    am start -a android.intent.action.VIEW -d "${ROBLOX_PLAYER_DEEP}${rid}" >/dev/null 2>&1
                fi
                show_roblox_lobby_v16
                ;;

            rbx\ save* | save* )
                save_args=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?save[ ]+//I' | xargs)
                if [ -z "$save_args" ]; then
                    read -p "Masukkan nama save: " sname_in
                    read -p "Masukkan ID map: " sid_in
                    save_rbx "$sname_in" "$sid_in"
                else
                    sid=$(echo "$save_args" | awk '{print $NF}')
                    if ! echo "$sid" | grep -Eq '^[0-9]+$'; then
                        read -p "Masukkan nama save: " sname_in
                        read -p "Masukkan ID map: " sid_in
                        save_rbx "$sname_in" "$sid_in"
                    else
                        sname=$(echo "$save_args" | rev | cut -d' ' -f2- | rev | xargs)
                        save_rbx "$sname" "$sid"
                    fi
                fi
                show_roblox_lobby_v16
                ;;

            rbx\ listjoin* | listjoin* )
                arg=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?listjoin[ ]*//I' | xargs)
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    echo -e "${Y}Belum ada save-an${NC}"
                else
                    if [ -z "$arg" ]; then
                        list_rbx
                        echo ""
                        read -p "Masukkan angka save: " num
                        join_id=$(get_rbx_by_num "$num")
                        [ -z "$join_id" ] && echo -e "${R}Nomor tidak ditemukan${NC}" || roblox_join_by_id "$join_id"
                    else
                        if echo "$arg" | grep -Eq '^[0-9]+$'; then
                            join_id=$(get_rbx_by_num "$arg")
                        else
                            join_id=$(get_rbx_by_name "$arg")
                        fi
                        [ -z "$join_id" ] && echo -e "${R}Save tidak ditemukan${NC}" || roblox_join_by_id "$join_id"
                    fi
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;

            rbx\ rmls* | rmls* )
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    echo -e "${Y}Belum ada save-an${NC}"
                else
                    arg=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?rmls[ ]*//I' | xargs)
                    if [ -z "$arg" ]; then
                        list_rbx
                        echo ""
                        read -p "Masukkan angka yang mau dihapus: " delnum
                        if echo "$delnum" | grep -Eq '^[0-9]+$'; then
                            sed -i "${delnum}d" "$SAVE_FILE"
                            echo -e "${G}Dihapus nomor $delnum${NC}"
                        fi
                    else
                        if echo "$arg" | grep -Eq '^[0-9]+$'; then
                            sed -i "${arg}d" "$SAVE_FILE"
                            echo -e "${G}Dihapus nomor $arg${NC}"
                        else
                            delete_rbx_by_name "$arg"
                            echo -e "${G}Dihapus: $arg${NC}"
                        fi
                    fi
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;

            exploit )
                # Secret command - tidak masuk ke list Roblox lobby tapi masih ada
                exploit_lobby
                ;;

            exit|quit|q|keluar)
                clear
                show_cmd
                break
                ;;

            *)
                echo -e "${Y}Command tidak dikenal di Roblox lobby${NC}"
                echo -e "${Y}Gunakan: playgame, searchgame, playersearch, save, listjoin, rmls, exit (exploit = rahasia)${NC}"
                sleep 1
                show_roblox_lobby_v16
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
        echo -e "${C}File Manager - $CUR_DIR (hidden tetap tersembunyi)${NC}"
        echo -e "${W}------------------------------${NC}"

        mapfile -t ENTRIES < <(ls "$CUR_DIR" 2>/dev/null)

        if [ ${#ENTRIES[@]} -eq 0 ]; then
            echo -e "${Y}Folder kosong${NC}"
        else
            i=1
            for e in "${ENTRIES[@]}"; do
                if [ -d "$CUR_DIR/$e" ]; then
                    echo -e "${W}${i}. ${B}[DIR] ${e}${NC}"
                else
                    echo -e "${W}${i}. ${W}${e}${NC}"
                fi
                i=$((i+1))
            done
        fi

        echo -e "${W}------------------------------${NC}"
        echo -e "${Y}Ketik angka 1-infinite untuk pilih | 00 kembali | 0 keluar${NC}"
        echo ""

        read -p "fileman> " finp
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
                        echo -e "${C}File: $sel${NC}"
                        echo -e "${W}Path: $tpath${NC}"
                        echo -e "${W}------------------------------${NC}"
                        if [ "$SELECTED" = "id" ]; then
                            echo -e "${W}1. buka${NC}"
                            echo -e "${W}2. hapus${NC}"
                            echo -e "${W}3. duplikat${NC}"
                            echo -e "${W}4. pindah (move)${NC}"
                            echo -e "${W}5. ganti nama (rename)${NC}"
                            echo -e "${W}0. batal${NC}"
                        else
                            echo -e "${W}1. open${NC}"
                            echo -e "${W}2. delete${NC}"
                            echo -e "${W}3. dupe${NC}"
                            echo -e "${W}4. move${NC}"
                            echo -e "${W}5. rename${NC}"
                            echo -e "${W}0. cancel${NC}"
                        fi
                        echo -e "${W}------------------------------${NC}"
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
                                read -p "Yakin hapus $sel? (y/n): " conf
                                if [ "$conf" = "y" ] || [ "$conf" = "Y" ]; then
                                    rm -rf "$tpath"
                                    echo -e "${G}Dihapus${NC}"
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
                                echo -e "${G}Duplikat berhasil${NC}"
                                sleep 1
                                break
                                ;;
                            4)
                                ORIG_FILE="$tpath"
                                DEST_DIR="$CUR_DIR"
                                while true; do
                                    clear
                                    echo -e "${C}Pindah File: $(basename "$ORIG_FILE")${NC}"
                                    echo -e "${W}Asal: $ORIG_FILE${NC}"
                                    echo -e "${W}Tujuan sekarang: $DEST_DIR${NC}"
                                    echo -e "${W}------------------------------${NC}"
                                    mapfile -t MOVE_ENTRIES < <(ls "$DEST_DIR" 2>/dev/null)
                                    if [ ${#MOVE_ENTRIES[@]} -eq 0 ]; then
                                        echo -e "${Y}Folder kosong${NC}"
                                    else
                                        i=1
                                        for me in "${MOVE_ENTRIES[@]}"; do
                                            if [ -d "$DEST_DIR/$me" ]; then
                                                echo -e "${W}${i}. ${B}[DIR] ${me}${NC}"
                                            else
                                                echo -e "${W}${i}. ${W}${me}${NC}"
                                            fi
                                            i=$((i+1))
                                        done
                                    fi
                                    echo -e "${W}------------------------------${NC}"
                                    echo -e "${Y}Ketik angka untuk masuk folder, 00 mundur, 0 untuk pindahkan ke folder ini${NC}"
                                    echo ""
                                    read -p "move> " minp
                                    minp_trim=$(echo "$minp" | xargs)
                                    if [ "$minp_trim" = "0" ]; then
                                        mv "$ORIG_FILE" "$DEST_DIR/"
                                        echo -e "${G}File dipindahkan ke $DEST_DIR${NC}"
                                        sleep 1
                                        break
                                    fi
                                    if [ "$minp_trim" = "00" ]; then
                                        if [ "$DEST_DIR" = "/sdcard" ] || [ "$DEST_DIR" = "/storage/emulated/0" ] || [ "$DEST_DIR" = "$HOME" ] || [ "$DEST_DIR" = "/" ]; then
                                            continue
                                        else
                                            DEST_DIR=$(dirname "$DEST_DIR")
                                            continue
                                        fi
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
                                read -p "Masukkan nama baru: " newname
                                newname=$(echo "$newname" | xargs)
                                if [ -n "$newname" ]; then
                                    mv "$tpath" "$(dirname "$tpath")/$newname"
                                    echo -e "${G}Renamed${NC}"
                                    sleep 1
                                fi
                                break
                                ;;
                            0) break ;;
                            *) echo -e "${Y}Pilihan tidak valid${NC}"; sleep 1 ;;
                        esac
                    done
                fi
            fi
        fi
    done
}

run_antilag() {
    clear
    echo -e "${C}Menjalankan tool boost-performance terbaru...${NC}"
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
    echo -e "${G}Selesai, kembali ke menu utama...${NC}"
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
    read -p "assistant> " cmd
    [ -z "$cmd" ] && continue
    full=$(norm "$cmd")
    lang_arg=$(echo "$cmd" | cut -d' ' -f3- | xargs)

    case "$full" in
        "as update") do_update ;;
        "as roblox"|"roblox"|"rbx") roblox_lobby ;;
        "as antilag") run_antilag; show_cmd ;;
        "as fileman") run_fileman ;;
        as\ lang* )
            if [ -z "$lang_arg" ]; then
                echo -e "${Y}Contoh: as lang id${NC}"
                continue
            fi
            larg=$(norm "$lang_arg")
            case "$larg" in
                1|2) echo -e "${R}Angka tidak bisa${NC}" ;;
                id|indonesia|indo) SELECTED="id"; echo "$SELECTED" > "$LANG_FILE"; show_sel; show_cmd ;;
                en|english|inggris|eng) SELECTED="en"; echo "$SELECTED" > "$LANG_FILE"; show_sel; show_cmd ;;
                *) echo -e "${R}Bahasa tidak dikenal${NC}" ;;
            esac
            ;;
        "as help"|"help") clear; show_cmd ;;
        "exit"|"quit"|"q") exit 0 ;;
        *) echo -e "${Y}Perintah tidak dikenal${NC}" ;;
    esac
done
