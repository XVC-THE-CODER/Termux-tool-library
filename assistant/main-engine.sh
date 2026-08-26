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
        echo -e "${G}as fileman${NC} - file manager hp"
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
show_roblox_lobby_v16() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}rbx playgame <id>${NC} - join map"
        echo -e "${G}rbx playersearch <id>${NC} - cari player"
        echo -e "${G}rbx save <name> <id>${NC} - simpan map"
        echo -e "${G}rbx listjoin [name/angka]${NC} - join dari save"
        echo -e "${G}rbx rmls [name/angka]${NC} - hapus save"
        echo -e "${G}help${NC} - panduan lengkap & singkat"
        echo -e "${G}exit${NC} - keluar lobby"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${W}command${NC}"
        echo -e "${G}rbx playgame <id>${NC} - join map"
        echo -e "${G}rbx playersearch <id>${NC} - find player"
        echo -e "${G}rbx save <name> <id>${NC} - save map"
        echo -e "${G}rbx listjoin [name/number]${NC} - join saved"
        echo -e "${G}rbx rmls [name/number]${NC} - delete saved"
        echo -e "${G}help${NC} - full & short guide"
        echo -e "${G}exit${NC} - exit lobby"
        echo -e "${W}------------------------------${NC}"
    fi
}
show_roblox_help() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${C}=== PANDUAN ROBLOX LOBBY - FULL & SINGKAT ===${NC}"
        echo -e "${W}Bahasa: Indonesia (English translate di dalam kurung)${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}1. rbx playgame <id>${NC} - join map"
        echo -e "${W}   instant: playgame <id>${NC}"
        echo -e "${W}   EN: join map directly${NC}"
        echo -e ""
        echo -e "${G}2. rbx playersearch <id>${NC} - cari player"
        echo -e "${W}   instant: playersearch <id>${NC}"
        echo -e "${W}   EN: find player profile${NC}"
        echo -e ""
        echo -e "${G}3. rbx save <name> <id>${NC} - simpan map"
        echo -e "${W}   instant: save <name> <id>${NC}"
        echo -e "${W}   EN: save map to list${NC}"
        echo -e ""
        echo -e "${G}4. rbx listjoin [name/angka]${NC} - join dari save"
        echo -e "${W}   instant: listjoin [name/angka]${NC}"
        echo -e "${W}   EN: join from saved${NC}"
        echo -e ""
        echo -e "${G}5. rbx rmls [name/angka]${NC} - hapus save"
        echo -e "${W}   instant: rmls [name/angka]${NC}"
        echo -e "${W}   EN: remove saved map${NC}"
        echo -e ""
        echo -e "${G}6. help${NC} - panduan ini"
        echo -e "${W}   EN: show full & short usage${NC}"
        echo -e ""
        echo -e "${G}7. exploit${NC} - rahasia"
        echo -e "${W}   EN: secret exploit lobby${NC}"
        echo -e ""
        echo -e "${G}8. exit${NC} - keluar lobby"
        echo -e "${W}   EN: exit lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${Y}Catatan: command tanpa rbx tetap bisa dipakai walau tidak ditampilkan${NC}"
        echo -e "${Y}EN Note: instant commands without rbx still work even if not shown${NC}"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${C}=== ROBLOX LOBBY GUIDE - FULL & SHORT ===${NC}"
        echo -e "${W}Language: English${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}1. rbx playgame <id>${NC} - join map"
        echo -e "${W}   instant: playgame <id>${NC}"
        echo -e ""
        echo -e "${G}2. rbx playersearch <id>${NC} - find player"
        echo -e "${W}   instant: playersearch <id>${NC}"
        echo -e ""
        echo -e "${G}3. rbx save <name> <id>${NC} - save map"
        echo -e "${W}   instant: save <name> <id>${NC}"
        echo -e ""
        echo -e "${G}4. rbx listjoin [name/number]${NC} - join saved"
        echo -e "${W}   instant: listjoin${NC}"
        echo -e ""
        echo -e "${G}5. rbx rmls [name/number]${NC} - delete saved"
        echo -e "${W}   instant: rmls${NC}"
        echo -e ""
        echo -e "${G}6. help${NC} - this guide"
        echo -e ""
        echo -e "${G}7. exploit${NC} - secret"
        echo -e ""
        echo -e "${G}8. exit${NC} - exit lobby"
        echo -e "${W}------------------------------${NC}"
        echo -e "${Y}Note: instant commands without rbx still work${NC}"
        echo -e "${W}------------------------------${NC}"
    fi
    echo ""
    read -p "Tekan ENTER untuk kembali / Press ENTER to back: " _
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
exploit_lobby() {
    clear
    if [ "$SELECTED" = "id" ]; then
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}rahasia - tidak ada di list Roblox lobby${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}exp search <keyword>${NC} - cari script"
        echo -e "${G}exit${NC} - kembali"
        echo -e "${W}------------------------------${NC}"
    else
        echo -e "${R}=== SECRET EXPLOIT LOBBY ===${NC}"
        echo -e "${W}secret - not in Roblox lobby list${NC}"
        echo -e "${W}------------------------------${NC}"
        echo -e "${G}exp search <keyword>${NC} - search script"
        echo -e "${G}exit${NC} - back"
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
                    termux-open-url "$link" >/dev/null 2>&1
                    am start -a android.intent.action.VIEW -d "$link" >/dev/null 2>&1
                fi
                ;;
            exit|quit|q|keluar|00)
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
                    echo -e "${Y}Contoh: rbx playgame 2753915549${NC}"
                else
                    roblox_join_by_id "$rid"
                fi
                sleep 1
                show_roblox_lobby_v16
                ;;
            rbx\ playersearch* | playersearch* )
                rid=$(echo "$rcmd" | awk '{print $NF}')
                if [ -z "$rid" ]; then
                    echo -e "${Y}Contoh: rbx playersearch 123456${NC}"
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
                    read -p "Nama save: " sname_in
                    read -p "ID map: " sid_in
                    save_rbx "$sname_in" "$sid_in"
                else
                    sid=$(echo "$save_args" | awk '{print $NF}')
                    if ! echo "$sid" | grep -Eq '^[0-9]+$'; then
                        read -p "Nama save: " sname_in
                        read -p "ID map: " sid_in
                        save_rbx "$sname_in" "$sid_in"
                    else
                        sname=$(echo "$save_args" | rev | cut -d' ' -f2- | rev | xargs)
                        save_rbx "$sname" "$sid"
                    fi
                fi
                sleep 1
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
                        read -p "Masukkan angka: " num
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
                        read -p "Angka yang dihapus: " delnum
                        if echo "$delnum" | grep -Eq '^[0-9]+$'; then
                            sed -i "${delnum}d" "$SAVE_FILE"
                            echo -e "${G}Dihapus $delnum${NC}"
                        fi
                    else
                        if echo "$arg" | grep -Eq '^[0-9]+$'; then
                            sed -i "${arg}d" "$SAVE_FILE"
                            echo -e "${G}Dihapus $arg${NC}"
                        else
                            delete_rbx_by_name "$arg"
                            echo -e "${G}Dihapus: $arg${NC}"
                        fi
                    fi
                fi
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
                echo -e "${Y}Command tidak dikenal. Ketik 'help' untuk panduan${NC}"
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
        echo -e "${C}File Manager - $CUR_DIR${NC}"
        echo -e "${W}------------------------------${NC}"
        mapfile -t ENTRIES < <(ls "$CUR_DIR" 2>/dev/null)
        if [ ${#ENTRIES[@]} -eq 0 ]; then
            echo -e "${Y}Folder kosong${NC}"
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
        echo -e "${W}------------------------------${NC}"
        echo -e "${Y}angka=pilih | 00=kembali | 0=keluar${NC}"
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
                        echo -e "${W}------------------------------${NC}"
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
                                read -p "Hapus? (y/n): " conf
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
                                echo -e "${G}Duplikat OK${NC}"
                                sleep 1
                                break
                                ;;
                            4)
                                ORIG_FILE="$tpath"
                                DEST_DIR="$CUR_DIR"
                                while true; do
                                    clear
                                    echo -e "${C}Pindah: $(basename "$ORIG_FILE")${NC}"
                                    echo -e "${W}Tujuan: $DEST_DIR${NC}"
                                    echo -e "${W}------------------------------${NC}"
                                    mapfile -t MOVE_ENTRIES < <(ls "$DEST_DIR" 2>/dev/null)
                                    if [ ${#MOVE_ENTRIES[@]} -eq 0 ]; then
                                        echo -e "${Y}Folder kosong${NC}"
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
                                    echo -e "${W}------------------------------${NC}"
                                    echo -e "${Y}angka=masuk | 00=mundur | 0=pindahkan ke sini${NC}"
                                    echo ""
                                    read -p "move> " minp
                                    minp_trim=$(echo "$minp" | xargs)
                                    if [ "$minp_trim" = "0" ]; then
                                        mv "$ORIG_FILE" "$DEST_DIR/"
                                        echo -e "${G}Dipindahkan ke $DEST_DIR${NC}"
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
                                read -p "Nama baru: " newname
                                newname=$(echo "$newname" | xargs)
                                if [ -n "$newname" ]; then
                                    mv "$tpath" "$(dirname "$tpath")/$newname"
                                    echo -e "${G}Rename OK${NC}"
                                    sleep 1
                                fi
                                break
                                ;;
                            0) break ;;
                            *) echo -e "${Y}Tidak valid${NC}"; sleep 1 ;;
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
    echo -e "${G}Selesai${NC}"
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
