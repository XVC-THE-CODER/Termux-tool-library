#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator - by Meta AI
# Title: OBFUSCATE

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m'

CODE_FILE="code-to-obfuscate.lua"
CONFIG_FILE="$HOME/.obfuscate_config"
TMP_FINAL="/tmp/obf_final.lua"

# default config
ONELINE=false
DAMAGE=3

load_config(){
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_config(){
    echo "ONELINE=$ONELINE" > "$CONFIG_FILE"
    echo "DAMAGE=$DAMAGE" >> "$CONFIG_FILE"
}

show_title(){
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███████╗██╗   ██╗███████╗ ██████╗ █████╗ ████████╗███████╗"
    echo "  ██╔═══██╗██╔══██╗██╔════╝██║   ██║██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝"
    echo "  ██║   ██║██████╔╝█████╗  ██║   ██║███████╗██║     ███████║   ██║   █████╗  "
    echo "  ██║   ██║██╔══██╗██╔══╝  ██║   ██║╚════██║██║     ██╔══██║   ██║   ██╔══╝  "
    echo "  ╚██████╔╝██████╔╝██║     ╚██████╔╝███████║╚██████╗██║  ██║   ██║   ███████╗"
    echo "   ╚═════╝ ╚═════╝ ╚═╝      ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
    echo -e "${RESET}"
    echo -e "${YELLOW}  [ Termux Lua Obfuscator v2 - HTML Entity > Hex > Binary > Algebra ]${RESET}"
    echo -e "${WHITE}  Config: Oneline=$ONELINE | Damage Level=$DAMAGE${RESET}"
    echo ""
}

ensure_files(){
    if [ ! -f "$CODE_FILE" ]; then
        echo "-- taro code lua original kamu disini" > "$CODE_FILE"
        echo "print('hello world')" >> "$CODE_FILE"
    fi
}

generate_obfuscator_py(){
cat > /tmp/gen_obf.py << 'PYEOF'
import os, random, string, sys
code_path = os.environ.get("CODE_FILE","code-to-obfuscate.lua")
damage = int(os.environ.get("DAMAGE","3"))
oneline = os.environ.get("ONELINE","false").lower() == "true"
tmp_out = os.environ.get("TMP_FINAL","/tmp/obf_final.lua")

try:
    with open(code_path,"r",encoding="utf-8") as f:
        orig = f.read()
except:
    print("Gagal baca file")
    sys.exit(1)

if not orig.strip():
    print("File kosong")
    sys.exit(1)

# 1. HTML Entity
html = ''.join(f'&#{ord(c)};' for c in orig)

# 2. Hex String
hex_str = html.encode('utf-8').hex()  # ini hex dari html entity

# 3. Binary (dari hex_str, yang mana hex_str ini adalah representasi dari html entity yang mengandung symbol & # ;)
binary_str = ''.join(f'{ord(c):08b}' for c in hex_str)

# generate algebraic variables
var_count = 2 + damage
vars_list = []
for i in range(var_count):
    name = f"_Al{random.randint(10,99)}{chr(65+i)}{random.randint(1,9)}"
    val = random.randint(10,99)
    vars_list.append((name,val))

def gen_zero():
    v = random.choice(vars_list)
    # semua harus evaluasi 0
    choices = [
        f"({v[0]}-{v[0]})",
        f"({v[0]}*0)",
        f"(({v[0]}-{v[0]})*{random.randint(2,9)})",
    ]
    return random.choice(choices)

def gen_one():
    v = random.choice(vars_list)
    choices = [
        f"({v[0]}/{v[0]})",
        f"(({v[0]}*0)+{v[0]}/{v[0]})",
        f"({v[0]}*{v[0]}/{v[0]}/{v[0]})",
    ]
    return random.choice(choices)

parts = []
for bit in binary_str:
    if bit == '0':
        parts.append(f"tostring{gen_zero()}")
    else:
        parts.append(f"tostring{gen_one()}")

bin_lua = "..".join(parts)

var_defs = "\n".join([f"local {n}={v}" for n,v in vars_list])

# junk based on damage
junk = ""
if damage >= 3:
    for i in range(damage):
        junk += f"local _junk{i}_{random.randint(100,999)}={random.randint(1000,9999)}; "
        if i % 2 == 0:
            junk += "\n"
if damage >= 4:
    junk += f"local _unused=function() return {random.randint(1,100)} end\n"

# TEMPLATE: Obfuscate di atas, Deobfuscate di bawah
lua_code = f"""{junk}
{var_defs}
-- [ OBFUSCATE PAYLOAD ] HTML Entity > Hex > Binary > Algebra
local _BIN = {bin_lua}

-- [ DEOBFUSCATE CODE ] di bawah code obfuscate
local function _b(s)
    local r=""
    for i=1,#s,8 do
        local b=s:sub(i,i+7)
        if #b==8 then
            local c=tonumber(b,2)
            if c then r=r..string.char(c) end
        end
    end
    return r
end

local function _h(s)
    return (s:gsub('..', function(c) return string.char(tonumber(c,16)) end))
end

local function _e(s)
    return (s:gsub('&#(%d+);', function(n) return string.char(tonumber(n)) end))
end

local _HEX = _b(_BIN)
local _HTML = _h(_HEX)
local _CODE = _e(_HTML)
local _f,_err = load(_CODE)
if _f then
    _f()
else
    error("Deobfuscate failed: "..tostring(_err))
end
print(">> Obfuscated Successfully <<")
"""

# oneline handling
if oneline:
    # hilangkan newline tapi jaga syntax
    lua_code = lua_code.replace("\n", " ")
    # rapikan spasi ganda
    import re
    lua_code = re.sub(r'\s+', ' ', lua_code)
    lua_code = lua_code.replace(" ;", ";")

with open(tmp_out,"w",encoding="utf-8") as out:
    out.write(lua_code)

print(f"Generated {len(lua_code)} bytes | HTML {len(html)} | Hex {len(hex_str)} | Bin {len(binary_str)}")
PYEOF
}

obfuscate_process(){
    echo -e "${YELLOW}[*] Memulai obfuscate...${RESET}"
    export CODE_FILE DAMAGE ONELINE TMP_FINAL
    generate_obfuscator_py

    success=false
    for i in $(seq 1 10); do
        echo -e "${BLUE}  -> Percobaan generate #$i (Damage: $DAMAGE)...${RESET}"
        python3 /tmp/gen_obf.py
        if [ $? -ne 0 ]; then
            echo -e "${RED}  Generate gagal, ulang...${RESET}"
            continue
        fi

        # TEST BERKALI-KALI: check syntax + bisa di-load komputer
        echo -e "${CYAN}  -> Testing apakah bisa dibaca komputer...${RESET}"
        # test 1: syntax check dengan luac -p jika ada, fallback loadfile
        if command -v luac >/dev/null 2>&1; then
            luac -p "$TMP_FINAL" 2>/tmp/lua_err
            if [ $? -ne 0 ]; then
                cat /tmp/lua_err
                echo -e "${RED}  Syntax error, regenerate...${RESET}"
                continue
            fi
        fi

        # test 2: loadfile
        lua -e "assert(loadfile('$TMP_FINAL'))" 2>/tmp/lua_err
        if [ $? -ne 0 ]; then
            cat /tmp/lua_err
            echo -e "${RED}  Load test gagal, regenerate...${RESET}"
            continue
        fi

        # test 3: coba jalankan di sandbox (optional, 2 detik timeout)
        # timeout 3 lua "$TMP_FINAL" > /dev/null 2>&1
        # Jika timeout tidak ada, skip
        # if [ $? -ne 0 ] && [ $DAMAGE -lt 4 ]; then echo "Runtime warning tapi lanjut"; fi

        echo -e "${GREEN}  Test #$i LULUS - komputer bisa baca!${RESET}"
        success=true
        break
    done

    if [ "$success" = false ]; then
        echo -e "${RED}[!] Gagal generate code valid setelah 10x percobaan.${RESET}"
        return 1
    fi

    # SAVE ke nano file tadi (overwrite)
    cp "$TMP_FINAL" "$CODE_FILE"
    echo -e "${GREEN}[✓] Obfuscate BERHASIL! Code sudah disimpan di $CODE_FILE${RESET}"
    
    post_menu
}

post_menu(){
    while true; do
        echo ""
        echo -e "${MAGENTA}=== Hasil Obfuscate ===${RESET}"
        echo -e "${WHITE}[copy] [recreate] [open] [exit]${RESET}"
        read -p "$(echo -e ${YELLOW}Pilih > ${RESET})" pilih
        pilih=$(echo "$pilih" | tr '[:upper:]' '[:lower:]')
        case $pilih in
            copy)
                echo -e "${CYAN}[*] Mencoba copy ke clipboard 10x percobaan...${RESET}"
                for c in $(seq 1 10); do
                    if command -v termux-clipboard-set >/dev/null 2>&1; then
                        termux-clipboard-set "$(cat $CODE_FILE)"
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}[✓] Berhasil copy di percobaan $c${RESET}"
                            break
                        fi
                    elif command -v xclip >/dev/null 2>&1; then
                        cat $CODE_FILE | xclip -selection clipboard
                        echo -e "${GREEN}[✓] Berhasil copy via xclip${RESET}"
                        break
                    else
                        echo -e "${RED}[!] termux-clipboard-set tidak ditemukan. Install: pkg install termux-api${RESET}"
                        echo -e "${YELLOW}Menampilkan code untuk manual copy:${RESET}"
                        echo "----------------------------------------"
                        cat "$CODE_FILE"
                        echo "----------------------------------------"
                        break
                    fi
                    echo -e "${RED}  Copy gagal percobaan $c, retry...${RESET}"
                    sleep 0.5
                    if [ $c -eq 10 ]; then
                        echo -e "${RED}[!] Copy gagal setelah 10x${RESET}"
                    fi
                done
                ;;
            recreate)
                obfuscate_process
                ;;
            open)
                echo -e "${CYAN}[*] Isi file $CODE_FILE:${RESET}"
                echo "----------------------------------------"
                cat "$CODE_FILE"
                echo ""
                echo "----------------------------------------"
                ;;
            exit)
                break
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid. Ketik: copy, recreate, open, exit${RESET}"
                ;;
        esac
    done
}

handle_start(){
    ensure_files
    echo -e "${YELLOW}[*] Membuka nano $CODE_FILE... Taro code Lua kamu lalu Save (CTRL+O, Enter) dan Exit (CTRL+X)${RESET}"
    sleep 1
    nano "$CODE_FILE"
    if [ ! -s "$CODE_FILE" ]; then
        echo -e "${RED}[!] File kosong, batal.${RESET}"
        read -p "Tekan enter..."
        return
    fi
    obfuscate_process
    read -p "Tekan enter untuk kembali ke menu..."
}

handle_setting(){
    while true; do
        show_title
        echo -e "${CYAN}=== SETTING OBFUSCATE ===${RESET}"
        echo -e "${WHITE}1. Oneline Mode: $ONELINE (jadi 1 baris, susah dibaca)${RESET}"
        echo -e "${WHITE}2. Damage Level: $DAMAGE (1=santai, 5=hancur total tapi jalan)${RESET}"
        echo -e "${WHITE}3. Kembali${RESET}"
        echo ""
        read -p "$(echo -e ${YELLOW}Pilih setting [1/2/3] > ${RESET})" s
        case $s in
            1)
                echo -e "${WHITE}Pilih Oneline: true/false${RESET}"
                read -p "> " v
                if [[ "$v" == "true" || "$v" == "false" ]]; then
                    ONELINE=$v
                    save_config
                    echo -e "${GREEN}Oneline diset ke $ONELINE${RESET}"
                else
                    echo -e "${RED}Input harus true/false${RESET}"
                fi
                sleep 1
                ;;
            2)
                echo -e "${WHITE}Pilih Damage Level 1-5:${RESET}"
                read -p "> " v
                if [[ "$v" =~ ^[1-5]$ ]]; then
                    DAMAGE=$v
                    save_config
                    echo -e "${GREEN}Damage diset ke $DAMAGE${RESET}"
                else
                    echo -e "${RED}Harus angka 1-5${RESET}"
                fi
                sleep 1
                ;;
            3)
                break
                ;;
            *)
                echo "Pilihan salah"
                sleep 0.5
                ;;
        esac
    done
}

# MAIN
load_config
ensure_files
# check dependencies
for dep in python3 lua nano; do
    if ! command -v $dep >/dev/null 2>&1; then
        echo -e "${RED}[!] $dep belum terinstall. Jalankan: pkg install $dep -y${RESET}"
    fi
done

while true; do
    show_title
    echo -e "${GREEN}Ketik perintah:${RESET}"
    echo -e "${WHITE}  start   - mulai obfuscate (buka nano)${RESET}"
    echo -e "${WHITE}  setting - atur oneline & damage${RESET}"
    echo -e "${WHITE}  exit    - keluar${RESET}"
    echo ""
    read -p "$(echo -e ${MAGENTA}obfuscate@termux > ${RESET})" cmd
    cmd=$(echo "$cmd" | tr '[:upper:]' '[:lower:]' | xargs)
    case $cmd in
        start)
            handle_start
            ;;
        setting)
            handle_setting
            ;;
        exit|keluar|q)
            echo -e "${YELLOW}Bye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Perintah tidak dikenal. Ketik 'start' atau 'setting'${RESET}"
            sleep 1
            ;;
    esac
done
