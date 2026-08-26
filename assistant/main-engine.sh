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
        echo -e "${G}as lang <id/en/indonesia/english>${NC} - ganti bahasa"
        echo -e "${G}exit${NC}     - keluar dari tool ini"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}command assistant${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}as update${NC}  - update via github & restart"
        echo -e "${G}as roblox${NC}  - enter Roblox lobby"
        echo -e "${G}as antilag${NC} - boost performance"
        echo -e "${G}as fileman${NC} - full phone file manager"
        echo -e "${G}as lang <id/en/indonesia/english>${NC} - change language"
        echo -e "${G}exit${NC}     - exit from this tool"
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
    local url="https://www.roblox.com/discover/?Keyword=${encoded}"

    # Buka link sebagai latar belakang termux
    termux-open-url "$url" >/dev/null 2>&1 &
    am start -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1 &

    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Mencari game: $keyword ...${NC}"
        echo -e "${W}Link: $url (dibuka di background)${NC}"
    else
        echo -e "${C}Searching games: $keyword ...${NC}"
        echo -e "${W}Link: $url (opened in background)${NC}"
    fi

    sleep 1

    # Ambil halaman discover
    local html=$(curl -s -L -A "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36" "$url" --max-time 12 2>/dev/null)

    # Parse /games/ID/Name
    local games_raw=$(echo "$html" | grep -oE '/games/[0-9]+/[^"<> ?&#]+' | head -n 200)

    # Fallback coba search page biasa kalau discover kosong
    if [ -z "$games_raw" ]; then
        local search_url="https://www.roblox.com/search?Keyword=${encoded}"
        local html2=$(curl -s -L -A "Mozilla/5.0" "$search_url" --max-time 12 2>/dev/null)
        games_raw=$(echo "$html2" | grep -oE '/games/[0-9]+/[^"<> ?&#]+' | head -n 200)
    fi

    declare -a GAME_IDS
    declare -a GAME_NAMES
    declare -A seen

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        id=$(echo "$line" | cut -d'/' -f3)
        raw_name=$(echo "$line" | cut -d'/' -f4 | cut -d'?' -f1)
        # Ganti - jadi spasi
        name=$(echo "$raw_name" | sed 's/-/ /g' | xargs)
        [ -z "$id" ] && continue
        [ -z "$name" ] && name="Game $id"
        if [ -z "${seen[$id]}" ]; then
            seen[$id]=1
            GAME_IDS+=("$id")
            GAME_NAMES+=("$name")
        fi
    done <<< "$games_raw"

    if [ ${#GAME_IDS[@]} -eq 0 ]; then
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Tidak ada game ditemukan untuk: $keyword${NC}"
        else
            echo -e "${Y}No games found for: $keyword${NC}"
        fi
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
            echo -e "${C}Hasil pencarian: $keyword (Total: $total)${NC}"
            echo -e "${W}Menampilkan $((start+1)) sampai $end${NC}"
        else
            echo -e "${C}Search results: $keyword (Total: $total)${NC}"
            echo -e "${W}Showing $((start+1)) to $end${NC}"
        fi
        echo -e "${W}------------------------------${NC}"

        for ((i=start; i<end; i++)); do
            num=$((i+1))
            # Di sebelah angka ada nama game, di sebelah kanan id game, - sudah jadi spasi
            echo -e "${W}${num}. ${G}${GAME_NAMES[$i]}${NC} ${W}- ${GAME_IDS[$i]}${NC}"
        done

        echo -e "${W}------------------------------${NC}"
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Ketik nomor game (1-infinite) untuk pilih${NC}"
            echo -e "${Y}Ketik 'next' / 'lanjut' untuk 26-50, 'prev' untuk kembali, '0' untuk keluar${NC}"
            echo -e "${Y}Max 25 per halaman, setelah pilih, 1-25 dihapus, muncul 26-50 dst${NC}"
        else
            echo -e "${Y}Type game number (1-infinite) to select${NC}"
            echo -e "${Y}Type 'next' for 26-50, 'prev' to go back, '0' to exit${NC}"
        fi
        echo ""
        read -p "searchgame> " choice
        choice=$(echo "$choice" | xargs | tr '[:upper:]' '[:lower:]')

        if [ "$choice" = "0" ] || [ "$choice" = "exit" ] || [ "$choice" = "q" ]; then
            break
        elif [ "$choice" = "next" ] || [ "$choice" = "lanjut" ] || [ "$choice" = "more" ] || [ "$choice" = "26" ]; then
            if [ $end -lt $total ]; then
                page=$((page+1))
            else
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Sudah di halaman terakhir${NC}"
                else
                    echo -e "${Y}Already at last page${NC}"
                fi
                sleep 1
            fi
            continue
        elif [ "$choice" = "prev" ] || [ "$choice" = "kembali" ] || [ "$choice" = "back" ]; then
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
                        echo -e "${G}2. save ke listjoin (input nama dulu)${NC}"
                        echo -e "${G}0. batal / kembali ke pencarian${NC}"
                    else
                        echo -e "${C}Selected game: $sel_name - $sel_id${NC}"
                        echo -e "${W}------------------------------${NC}"
                        echo -e "${G}1. play using ro.blox.com${NC}"
                        echo -e "${G}2. save to listjoin${NC}"
                        echo -e "${G}0. cancel / back to search${NC}"
                    fi
                    echo -e "${W}------------------------------${NC}"
                    read -p "Pilih> " opt
                    case "$opt" in
                        1)
                            roblox_join_by_id "$sel_id"
                            sleep 1
                            break
                            ;;
                        2)
                            if [ "$SELECTED" = "id" ]; then
                                echo -e "${Y}Masukkan nama save (enter untuk pakai nama asli: $sel_name)${NC}"
                                read -p "Nama save: " save_name
                            else
                                echo -e "${Y}Enter save name (enter to use original: $sel_name)${NC}"
                                read -p "Save name: " save_name
                            fi
                            save_name=$(echo "$save_name" | xargs)
                            if [ -z "$save_name" ]; then
                                save_name="$sel_name"
                            fi
                            save_rbx "$save_name" "$sel_id"
                            sleep 1
                            break
                            ;;
                        0)
                            break
                            ;;
                        *)
                            echo -e "${Y}Pilihan tidak valid${NC}"
                            sleep 1
                            ;;
                    esac
                done
            else
                echo -e "${Y}Nomor tidak valid${NC}"
                sleep 1
            fi
        else
            echo -e "${Y}Input tidak dikenal${NC}"
            sleep 1
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
        echo -e "${W}hidden command - not shown in Roblox lobby list${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}exp search <keyword>${NC} - search script on ScriptBlox"
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
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Contoh: exp search speed hub x${NC}"
                    else
                        echo -e "${Y}Example: exp search speed hub x${NC}"
                    fi
                else
                    search_plus=$(echo "$earg" | sed 's/ /+/g')
                    link="https://scriptblox.com/?q=${search_plus}"
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${C}[EXP] Mencari: $earg${NC}"
                        echo -e "${W}Link: $link${NC}"
                        echo -e "${G}Membuka ScriptBlox...${NC}"
                    else
                        echo -e "${C}[EXP] Searching: $earg${NC}"
                        echo -e "${W}Link: $link${NC}"
                        echo -e "${G}Opening ScriptBlox...${NC}"
                    fi
                    termux-open-url "$link" >/dev/null 2>&1
                    am start -a android.intent.action.VIEW -d "$link" >/dev/null 2>&1
                fi
                ;;

            exit|quit|q|keluar|00)
                clear
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${C}Roblox lobby${NC}"
                    echo -e "${W}------------------------------${NC}"
                    echo -e "${G}playgame / rbx playgame${NC} - join map"
                    echo -e "${G}listjoin / rbx listjoin${NC} - join dari save"
                    echo -e "${G}searchgame / rbx searchgame${NC} - cari game via discover"
                    echo -e "${G}rmls / rbx rmls${NC} - hapus save"
                    echo -e "${G}exit${NC} - keluar"
                    echo -e "${W}------------------------------${NC}"
                else
                    echo -e "${C}Roblox lobby${NC}"
                    echo -e "${W}------------------------------${NC}"
                    echo -e "${G}playgame${NC} - join map"
                    echo -e "${G}searchgame${NC} - search game"
                    echo -e "${W}------------------------------${NC}"
                fi
                break
                ;;

            *)
                if [ "$SELECTED" = "id" ]; then
                    echo -e "${Y}Command tidak dikenal. Gunakan: exp search <keyword> / exit${NC}"
                else
                    echo -e "${Y}Unknown command. Use: exp search <keyword> / exit${NC}"
                fi
                ;;
        esac
    done
}

roblox_lobby() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}playgame <id> / rbx playgame${NC} - join map (auto server tidak penuh)"
        echo -e "${G}searchgame <keyword> / rbx searchgame${NC} - cari game di discover (max 25 per halaman)"
        echo -e "${G}playersearch / rbx playersearch${NC} - cari player"
        echo -e "${G}save <name> <id> / rbx save${NC} - simpan map"
        echo -e "${G}listjoin / rbx listjoin${NC} - join dari save"
        echo -e "${G}rmls / rbx rmls${NC} - hapus save"
        echo -e "${G}exit${NC} - keluar"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}playgame <id>${NC} - join map"
        echo -e "${G}searchgame <keyword>${NC} - search game via discover"
        echo -e "${G}listjoin${NC} - join from save"
        echo -e "${G}rmls${NC} - delete save"
        echo -e "${W}------------------------------${NC}"
    fi

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
                ;;

            rbx\ searchgame* | searchgame* )
                keyword=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?searchgame[ ]*//I' | xargs)
                if [ -z "$keyword" ]; then
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${Y}Contoh: searchgame steal an egg${NC}"
                        echo -e "${Y}Contoh: rbx searchgame blox fruit${NC}"
                    else
                        echo -e "${Y}Example: searchgame steal an egg${NC}"
                    fi
                else
                    search_roblox_games "$keyword"
                    clear
                    if [ "$SELECTED" = "id" ]; then
                        echo -e "${C}Roblox lobby${NC}"
                        echo -e "${W}------------------------------${NC}"
                        echo -e "${G}playgame / searchgame / listjoin / rmls / exit${NC}"
                        echo -e "${W}------------------------------${NC}"
                    else
                        echo -e "${C}Roblox lobby${NC}"
                        echo -e "${W}------------------------------${NC}"
                        echo -e "${G}playgame / searchgame / listjoin / rmls / exit${NC}"
                        echo -e "${W}------------------------------${NC}"
                    fi
                fi
                ;;

            rbx\ playersearch* | playersearch* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                termux-open-url "${ROBLOX_PLAYER_URL}${rid}/profile" >/dev/null 2>&1
                am start -a android.intent.action.VIEW -d "${ROBLOX_PLAYER_DEEP}${rid}" >/dev/null 2>&1
                ;;

            rbx\ save* | save* )
                save_args=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?save[ ]+//I' | xargs)
                if [ -z "$save_args" ]; then
                    read -p "Masukkan nama save: " sname_in
                    read -p "Masukkan ID map: " sid_in
                    save_rbx "$sname_in" "$sid_in"
                    continue
                fi
                sid=$(echo "$save_args" | awk '{print $NF}')
                if ! echo "$sid" | grep -Eq '^[0-9]+$'; then
                    read -p "Masukkan nama save: " sname_in
                    read -p "Masukkan ID map: " sid_in
                    save_rbx "$sname_in" "$sid_in"
                else
                    sname=$(echo "$save_args" | rev | cut -d' ' -f2- | rev | xargs)
                    save_rbx "$sname" "$sid"
                fi
                ;;

            rbx\ listjoin* | listjoin* )
                arg=$(echo "$rcmd" | sed -E 's/^(rbx[ ]+)?listjoin[ ]*//I' | xargs)
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    echo -e "${Y}Belum ada save-an${NC}"
                    continue
                fi
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
                ;;

            rbx\ rmls* | rmls* )
                if [ ! -f "$SAVE_FILE" ] || [ ! -s "$SAVE_FILE" ]; then
                    echo -e "${Y}Belum ada save-an${NC}"
                    continue
                fi
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
                echo -e "${Y}Command tidak dikenal${NC}"
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
        echo -e "${C}File Manager - $CUR_DIR${NC}"
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
        if [ "$SELECTED" = "id" ]; then
            echo -e "${Y}Ketik angka 1-infinite untuk pilih file/folder${NC}"
            echo -e "${Y}Ketik 00 untuk kembali, 0 untuk keluar${NC}"
        else
            echo -e "${Y}Type number 1-infinite to select${NC}"
            echo -e "${Y}Type 00 to go back, 0 to exit${NC}"
        fi
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
                                if [ "$SELECTED" = "id" ]; then
                                    read -p "Yakin hapus $sel? (y/n): " conf
                                else
                                    read -p "Delete $sel? (y/n): " conf
                                fi
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
                                if [ "$SELECTED" = "id" ]; then
                                    echo -e "${G}Duplikat berhasil${NC}"
                                else
                                    echo -e "${G}Duplicated${NC}"
                                fi
                                sleep 1
                                break
                                ;;
                            4)
                                ORIG_FILE="$tpath"
                                DEST_DIR="$CUR_DIR"
                                while true; do
                                    clear
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${C}Pindah File: $(basename "$ORIG_FILE")${NC}"
                                        echo -e "${W}Asal: $ORIG_FILE${NC}"
                                        echo -e "${W}Tujuan sekarang: $DEST_DIR${NC}"
                                    else
                                        echo -e "${C}Move File: $(basename "$ORIG_FILE")${NC}"
                                        echo -e "${W}From: $ORIG_FILE${NC}"
                                        echo -e "${W}Current dest: $DEST_DIR${NC}"
                                    fi
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
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${Y}Ketik angka untuk masuk folder${NC}"
                                        echo -e "${Y}Ketik 00 untuk mundur${NC}"
                                        echo -e "${Y}Ketik 0 untuk pindahkan file ke folder ini${NC}"
                                    else
                                        echo -e "${Y}Type number to enter folder${NC}"
                                        echo -e "${Y}Type 00 to go back${NC}"
                                        echo -e "${Y}Type 0 to move file here${NC}"
                                    fi
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
                                if [ "$SELECTED" = "id" ]; then
                                    echo -e "${Y}Nama lama: $sel${NC}"
                                    read -p "Masukkan nama baru: " newname
                                else
                                    echo -e "${Y}Old name: $sel${NC}"
                                    read -p "Enter new name: " newname
                                fi
                                newname=$(echo "$newname" | xargs)
                                if [ -n "$newname" ]; then
                                    mv "$tpath" "$(dirname "$tpath")/$newname"
                                    if [ "$SELECTED" = "id" ]; then
                                        echo -e "${G}Berhasil ganti nama jadi $newname${NC}"
                                    else
                                        echo -e "${G}Renamed to $newname${NC}"
                                    fi
                                    sleep 1
                                fi
                                break
                                ;;
                            0)
                                break
                                ;;
                            *)
                                echo -e "${Y}Pilihan tidak valid${NC}"
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
