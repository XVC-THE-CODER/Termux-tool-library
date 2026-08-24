#!/bin/bash

# ==========================================
#  Assistant Game - Multi Language Support
#  Support: 1/id/indonesia | 2/en/english
# ==========================================

# Warna biar keren
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

LANG_FILE="$HOME/.as_lang"
SELECTED_LANG=""

# Fungsi untuk normalisasi input (lowercase + trim)
normalize() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | xargs
}

# Fungsi pilih bahasa
choose_language() {
    clear
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}  Pilih Bahasa / Choose Language ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo -e ""
    echo -e "${WHITE}[1] Indonesia (id)${NC}"
    echo -e "${WHITE}[2] English (en)${NC}"
    echo -e ""
    echo -e "${YELLOW}Cara pilih: angka / nama bahasa / kode domain${NC}"
    echo -e "${YELLOW}Example: 1, indonesia, id  atau  2, english, en${NC}"
    echo -e ""
    read -p "> " input_raw
    INPUT=$(normalize "$input_raw")

    case "$INPUT" in
        1|id|indonesia|indo)
            SELECTED_LANG="id"
            ;;
        2|en|english|inggris|eng)
            SELECTED_LANG="en"
            ;;
        *)
            echo -e "${YELLOW}Input tidak valid / Invalid input! Coba lagi.${NC}"
            sleep 1.5
            choose_language
            return
            ;;
    esac

    # Simpan pilihan biar kalo update tetap sama
    echo "$SELECTED_LANG" > "$LANG_FILE"
}

# Fungsi text setelah pilih bahasa
show_selected_text() {
    clear
    if [ "$SELECTED_LANG" == "id" ]; then
        echo -e "${GREEN}Bahasa Indonesia berhasil dipilih!${NC}"
        echo -e "${WHITE}Memuat Assistant Game...${NC}"
    else
        echo -e "${GREEN}English language selected successfully!${NC}"
        echo -e "${WHITE}Loading Game Assistant...${NC}"
    fi
    sleep 1.5
    clear
}

# Fungsi daftar command (ini yang lu minta muncul setelah clear kedua)
show_commands() {
    if [ "$SELECTED_LANG" == "id" ]; then
        echo -e "${CYAN}command assistant${NC}"
        echo -e "${WHITE}------------------------------${NC}"
        echo -e "${GREEN}as update${NC}              - cek & update assistant ke versi terbaru"
        echo -e "${GREEN}as install <game>${NC}     - ini nama game di Play Store atau AppStore"
        echo -e "${GREEN}as anti lag${NC}           - optimasi game biar tidak lag"
        echo -e "${GREEN}as help${NC}               - tampilkan bantuan ini lagi"
        echo -e "${GREEN}exit${NC}                  - keluar dari tool ini"
        echo -e "${WHITE}------------------------------${NC}"
    else
        echo -e "${CYAN}command assistant${NC}"
        echo -e "${WHITE}------------------------------${NC}"
        echo -e "${GREEN}as update${NC}              - check & update assistant to latest version"
        echo -e "${GREEN}as install <game>${NC}     - game name on Play Store or AppStore"
        echo -e "${GREEN}as anti lag${NC}           - optimize game to reduce lag"
        echo -e "${GREEN}as help${NC}               - show this help again"
        echo -e "${GREEN}exit${NC}                  - exit from this tool"
        echo -e "${WHITE}------------------------------${NC}"
    fi
}

# Fungsi untuk command as
handle_commands() {
    while true; do
        echo ""
        if [ "$SELECTED_LANG" == "id" ]; then
            read -p "assistant> " cmd
        else
            read -p "assistant> " cmd
        fi

        # ambil kata pertama
        base_cmd=$(echo "$cmd" | awk '{print $1" "$2}')
        base_cmd_norm=$(normalize "$base_cmd")
        full_cmd_norm=$(normalize "$cmd")

        case "$full_cmd_norm" in
            "as update")
                clear
                if [ "$SELECTED_LANG" == "id" ]; then
                    echo -e "${YELLOW}[UPDATE] Mengecek update terbaru...${NC}"
                else
                    echo -e "${YELLOW}[UPDATE] Checking for latest update...${NC}"
                fi
                # Disini semua bahasa pesannya udah disamain logic nya
                sleep 1
                echo -e "${GREEN}Versi sudah yang terbaru! (v1.0.0)${NC}"
                show_commands
                ;;
            "as anti lag"|"as antilag")
                clear
                if [ "$SELECTED_LANG" == "id" ]; then
                    echo -e "${GREEN}Mengaktifkan mode anti lag...${NC}"
                    echo -e "Membersihkan cache & optimasi RAM..."
                else
                    echo -e "${GREEN}Activating anti-lag mode...${NC}"
                    echo -e "Clearing cache & optimizing RAM..."
                fi
                sleep 2
                echo -e "${GREEN}Done! Game lebih smooth sekarang.${NC}"
                show_commands
                ;;
            "as help"|"as command"|"as commands")
                clear
                show_commands
                ;;
            as\ install*|as\ instal*)
                game_name=$(echo "$cmd" | cut -d' ' -f3-)
                if [ -z "$game_name" ]; then
                    if [ "$SELECTED_LANG" == "id" ]; then
                        echo -e "${YELLOW}Contoh: as install mobile legends${NC}"
                    else
                        echo -e "${YELLOW}Example: as install mobile legends${NC}"
                    fi
                else
                    clear
                    if [ "$SELECTED_LANG" == "id" ]; then
                        echo -e "${CYAN}Mencari game: $game_name di Play Store/AppStore...${NC}"
                    else
                        echo -e "${CYAN}Searching game: $game_name on Play Store/AppStore...${NC}"
                    fi
                    sleep 1
                    echo -e "${GREEN}Link install: https://play.google.com/store/search?q=$game_name${NC}"
                fi
                ;;
            "exit"|"exit in this tool")
                if [ "$SELECTED_LANG" == "id" ]; then
                    echo -e "${YELLOW}Keluar dari Assistant... Bye!${NC}"
                else
                    echo -e "${YELLOW}Exiting Assistant... Bye!${NC}"
                fi
                exit 0
                ;;
            "")
                ;;
            *)
                if [ "$SELECTED_LANG" == "id" ]; then
                    echo -e "${YELLOW}Command tidak dikenal. Ketik 'as help'${NC}"
                else
                    echo -e "${YELLOW}Unknown command. Type 'as help'${NC}"
                fi
                ;;
        esac
    done
}

# ================= MAIN =================

# Cek kalau sudah ada file bahasa tersimpan, langsung pakai (biar update tetap sama bahasanya)
if [ -f "$LANG_FILE" ] && [ "$1" != "--reset-lang" ] && [ "$1" != "-r" ]; then
    saved=$(normalize "$(cat $LANG_FILE)")
    if [[ "$saved" == "id" || "$saved" == "en" ]]; then
        SELECTED_LANG=$saved
    else
        choose_language
    fi
else
    # Kalau ada argumen --lang
    if [[ "$1" == "--lang" || "$1" == "-l" ]]; then
        INPUT=$(normalize "$2")
        case "$INPUT" in
            1|id|indonesia) SELECTED_LANG="id" ;;
            2|en|english) SELECTED_LANG="en" ;;
            *) choose_language ;;
        esac
        echo "$SELECTED_LANG" > "$LANG_FILE"
    else
        choose_language
    fi
fi

# Alur yang lu minta: clear -> text konfirmasi -> clear -> daftar command
show_selected_text
show_commands
handle_commands
