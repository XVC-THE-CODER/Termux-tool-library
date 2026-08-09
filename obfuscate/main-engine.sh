#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator - Fixed Version
# Title: OBFUSCATE
# Fix error: /data/data/com.termux/files/usr/bin/python3: can't open file '/tmp/gen_obf.py'

PROJECT_FILE="./code-to-obfuscate.lua"
BACKUP_FILE="$HOME/.obfuscate_original.lua"
SETTINGS_FILE="$HOME/.obfuscate_settings"
ENGINE_FILE="$HOME/.obfuscate_engine.py"
CACHE_DIR="$HOME/.cache"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

init_settings() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        mkdir -p "$(dirname "$SETTINGS_FILE")"
        echo "oneline=off" > "$SETTINGS_FILE"
        echo "damage=3" >> "$SETTINGS_FILE"
        echo "anti_bug=on" >> "$SETTINGS_FILE"
    fi
    source "$SETTINGS_FILE"
}

init_engine() {
    mkdir -p "$CACHE_DIR"
    cat > "$ENGINE_FILE" << 'PYEOF'
import sys, os, random, string, subprocess, tempfile, re

def rand_name(damage):
    if damage >= 4:
        parts = ["_", "__", "_0x", "_0X", "_Alj", "_Bin", "_Hex", "_Ent"]
        base = random.choice(parts)
        suffix = ''.join(random.choices("0123456789ABCDEF", k=random.randint(4,8)))
        return base + suffix
    elif damage >= 2:
        return "_0x" + ''.join(random.choices("ABCDEF0123456789", k=random.randint(4,6))) + random.choice(["a","b","c","x","z"])
    else:
        return "_var" + str(random.randint(100,999))

def gen_base_vars(damage):
    count = 3 if damage <=2 else 4 if damage==3 else 6
    names = []
    vals = {}
    for i in range(count):
        n = rand_name(damage)
        while n in names:
            n = rand_name(damage)
        names.append(n)
        vals[n] = random.randint(111, 9999)
    return names, vals

def expr_for_bit(bit, var_names, damage):
    v = random.choice(var_names)
    v2 = random.choice(var_names)
    while v2 == v and len(var_names)>1:
        v2 = random.choice(var_names)
    if bit == '0':
        templates = [
            f"({v}-{v})",
            f"(({v}*2)-({v}*2))",
            f"(({v}+{v2})-({v}+{v2}))",
            f"({v}*0)",
            f"(({v}*{v2})-({v}*{v2}))",
        ]
        if damage >= 3:
            templates += [
                f"(({v}*{v2}+{v2}*{v})-({v}*{v2}*2))",
                f"(({v}//{v})-1)",
                f"(({v2}//{v2})-({v}//{v}))",
            ]
    else:
        templates = [
            f"({v}//{v})",
            f"(({v}*2)//({v}*2))",
            f"(({v}+{v2})//({v}+{v2}))",
            f"(({v}-{v})+({v}//{v}))",
            f"({v2}//{v2})",
        ]
        if damage >= 3:
            templates += [
                f"(({v}*{v2})//({v}*{v2}))",
            ]
    safe = [t for t in templates if "//0" not in t and "/0" not in t]
    return random.choice(safe if safe else [f"({v}-{v})" if bit=='0' else f"({v}//{v})"])

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug):
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    hex_str = ''.join(f"{ord(ch):02x}" for ch in html_entity)
    binary_str = ''.join(f"{int(ch,16):04b}" for ch in hex_str)

    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name} = {var_vals[name]}")
    
    if damage >= 4:
        for _ in range(damage):
            junk_name = rand_name(damage) + "_junk"
            junk_val = random.randint(1,999)
            base = random.choice(var_names)
            lua_vars.append(f"local {junk_name} = {junk_val} * {base}")
            lua_vars.append(f"if ({base}-{base}==1) then local {rand_name(damage)} = 0 end")

    chunk_size = 50 if damage <=3 else 30
    chunks = []
    for i in range(0, len(binary_str), chunk_size):
        chunk_bits = binary_str[i:i+chunk_size]
        exprs = [expr_for_bit(b, var_names, damage) for b in chunk_bits]
        chunk_code = "..".join(exprs)
        chunks.append(f"({chunk_code})")

    bin_assembly = "..".join(chunks) if len(chunks)>1 else chunks[0]

    bin_var = rand_name(damage) + "_BIN"
    hex_var = rand_name(damage) + "_HEX"
    ent_var = rand_name(damage) + "_ENT"
    code_var = rand_name(damage) + "_CODE"
    b_var = rand_name(damage) + "_b"
    n_var = rand_name(damage) + "_n"
    h_var = rand_name(damage) + "_h"
    i_var = rand_name(damage) + "_i"
    j_var = rand_name(damage) + "_j"

    lua_vars_code = "\n".join(lua_vars)

    lua_template = "-- OBFUSCATED BY TERMUX OBFUSCATE TOOL\n"
    lua_template += "-- Layers: HTML Entity -> Hex String -> Binary Symbol -> Algebra Math\n"
    lua_template += lua_vars_code + "\n"
    lua_template += f"local {bin_var} = {bin_assembly}\n\n"
    lua_template += f"-- deobfuscate layer: binary -> hex\n"
    lua_template += f"local {hex_var} = \"\"\n"
    lua_template += f"for {i_var}=1, #{bin_var}, 4 do\n"
    lua_template += f"    local {b_var} = {bin_var}:sub({i_var},{i_var}+3)\n"
    lua_template += f"    local {n_var} = 0\n"
    lua_template += f"    for {j_var}=1,4 do\n"
    lua_template += f"        {n_var} = {n_var}*2 + ({b_var}:sub({j_var},{j_var})==\"1\" and 1 or 0)\n"
    lua_template += f"    end\n"
    lua_template += f"    {hex_var} = {hex_var} .. string.format(\"%x\", {n_var})\n"
    lua_template += f"end\n\n"
    lua_template += f"-- hex -> html entity\n"
    lua_template += f"local {ent_var} = \"\"\n"
    lua_template += f"for {i_var}=1, #{hex_var}, 2 do\n"
    lua_template += f"    local {h_var} = {hex_var}:sub({i_var},{i_var}+1)\n"
    lua_template += f"    {ent_var} = {ent_var} .. string.char(tonumber({h_var},16))\n"
    lua_template += f"end\n\n"
    lua_template += f"-- html entity -> original lua\n"
    lua_template += f"local {code_var} = {ent_var}:gsub(\"&#(%d+);\", function(n) return string.char(tonumber(n)) end)\n\n"
    lua_template += f"-- execute original code with anti-bug pcall\n"
    lua_template += f"local _load = loadstring or load\n"
    lua_template += f"local _ok, _fn = pcall(_load, {code_var})\n"
    lua_template += f"if _ok and _fn then\n"
    lua_template += f"    local _s, _e = pcall(_fn)\n"
    lua_template += f"end\n\n"
    lua_template += f'print("[OBFUSCATE] code executed | obfuscate berhasil")\n'

    final_code = lua_template

    if oneline == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s+', ' ', final_code)

    if anti_bug == "on":
        for attempt in range(5):
            with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False) as tf:
                tf.write(final_code)
                tf_path = tf.name
            try:
                result = subprocess.run(["luac", "-p", tf_path], capture_output=True, text=True, timeout=5)
                os.unlink(tf_path)
                if result.returncode == 0:
                    break
                else:
                    if attempt >=2:
                        damage = max(1, damage-1)
                    if attempt == 4:
                        print("SYNTAX_FAIL:"+result.stderr)
                        return False
            except FileNotFoundError:
                try: os.unlink(tf_path)
                except: pass
                break
            except Exception as e:
                try: os.unlink(tf_path)
                except: pass
                print(f"TEST_ERROR:{e}")
                return False

    with open(output_path, 'w', encoding='utf-8') as out:
        out.write(final_code)
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: engine.py <input> <output> <oneline> <damage> <anti_bug>")
        sys.exit(1)
    inp = sys.argv[1]
    outp = sys.argv[2]
    oneline = sys.argv[3] if len(sys.argv)>3 else "off"
    damage = int(sys.argv[4]) if len(sys.argv)>4 else 3
    anti_bug = sys.argv[5] if len(sys.argv)>5 else "on"
    ok = obfuscate_file(inp, outp, oneline, damage, anti_bug)
    print("OK" if ok else "FAIL")
    sys.exit(0 if ok else 2)
PYEOF
    chmod +x "$ENGINE_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "   ____  ____  ______ _   _  ____   ____    _   _____ _____ "
    echo "  / __ \| __ )|  ___/| | | |/ ___| / ___|  / \ |_   _| ____|"
    echo " | |  | |  _ \| |_   | | | |\___ \| |     / _ \  | | |  _|  "
    echo " | |__| | |_) |  _|  | |_| | ___) | |___ / ___ \ | | | |___ "
    echo "  \____/|____/|_|     \___/ |____/ \____/_/   \_\|_| |_____|"
    echo -e "${RESET}"
    echo -e "${WHITE}         Termux Lua Obfuscator v2.0 - Algebra Edition${RESET}"
    echo -e "${YELLOW}         HTML Entity > Hex String > Binary > Algebra Math${RESET}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${WHITE}[ MENU ]${RESET}"
    echo -e "  ${YELLOW}start${RESET}   - Buat & obfuscate code lua"
    echo -e "  ${YELLOW}setting${RESET} - Atur oneline & damage level"
    echo -e "  ${YELLOW}exit${RESET}    - Keluar tool"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -ne "${CYAN}obfuscate > ${RESET}"
}

do_copy_with_retry() {
    local file="$1"
    local success=0

    # === AUTO INSTALL TERMUX-API KALO BELUM ADA ===
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] termux-api belum terinstall${RESET}"
        echo -e "${CYAN}[*] Auto download termux-api...${RESET}"
        pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null
        pkg install termux-api -y
        if command -v termux-clipboard-set >/dev/null 2>&1; then
            echo -e "${GREEN}[✓] termux-api berhasil diinstall otomatis${RESET}"
        else
            echo -e "${RED}[x] Auto install gagal, coba manual: pkg install termux-api${RESET}"
            echo -e "${YELLOW}[!] Pastikan juga aplikasi Termux:API terinstall dari F-Droid${RESET}"
            sleep 2
        fi
    fi

    echo -e "${YELLOW}[*] Mencoba copy ke clipboard 10x...${RESET}"
    for i in {1..10}; do
        if command -v termux-clipboard-set >/dev/null 2>&1; then
            if termux-clipboard-set < "$file"; then
                echo -e "${GREEN}[✓] Copy berhasil di percobaan ke-$i${RESET}"
                success=1
                break
            fi
        else
            echo -e "${RED}[!] termux-clipboard-set masih tidak ditemukan${RESET}"
            break
        fi
        echo -e "${YELLOW}[.] Percobaan $i gagal, retry...${RESET}"
        sleep 0.3
    done
    if [ $success -eq 0 ] && command -v termux-clipboard-set >/dev/null 2>&1; then
        echo -e "${RED}[x] Copy gagal setelah 10x percobaan, coba buka manual: cat $file${RESET}"
    fi
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    if [ -d "/data/data/com.termux/files/usr/tmp" ]; then
        tmp_out="/data/data/com.termux/files/usr/tmp/obf_temp.lua"
    fi

    echo -e "${YELLOW}[*] Membaca setting...${RESET}"
    init_settings
    echo -e "${CYAN}    oneline: $oneline | damage: $damage | anti_bug: $anti_bug${RESET}"
    echo -e "${YELLOW}[*] Backup original code...${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}[*] Menjalankan engine obfuscate...${RESET}"
    echo -e "${YELLOW}    Layer 1: HTML Entity -> &#code;${RESET}"
    echo -e "${YELLOW}    Layer 2: Hex String -> 26 23...${RESET}"
    echo -e "${YELLOW}    Layer 3: Binary Symbol -> 0101...${RESET}"
    echo -e "${YELLOW}    Layer 4: Algebra Math -> (var-var) (var/var)${RESET}"

    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug"
    local status=$?

    if [ $status -ne 0 ] || [ ! -f "$tmp_out" ]; then
        echo -e "${RED}[x] Obfuscate gagal! Check code lua lu${RESET}"
        return 1
    fi

    echo -e "${YELLOW}[*] Testing berkali-kali agar bisa dibaca komputer...${RESET}"
    local test_ok=0
    for t in {1..5}; do
        if command -v luac >/dev/null 2>&1; then
            if luac -p "$tmp_out" >/dev/null 2>&1; then
                echo -e "${GREEN}    [✓] Test $t: luac -p OK${RESET}"
                test_ok=1
            else
                echo -e "${RED}    [x] Test $t: syntax error, regenerating...${RESET}"
                python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug"
            fi
        else
            echo -e "${GREEN}    [✓] Test $t: skip luac (not installed), python logic OK${RESET}"
            test_ok=1
            break
        fi
        sleep 0.2
    done

    if [ $test_ok -eq 1 ]; then
        cat "$tmp_out" > "$PROJECT_FILE"
        # === BUAT FILE BARU obfuscate-code.lua SESUAI REQUEST ===
        cat "$tmp_out" > "./obfuscate-code.lua"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}[✓] OBFUSCATE BERHASIL!${RESET}"
        echo -e "${WHITE}File tersimpan: $PROJECT_FILE${RESET}"
        echo -e "${WHITE}File baru   : ./obfuscate-code.lua (buat di-open)${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        
        while true; do
            echo ""
            echo -e "${CYAN}Pilihan: [1] copy  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}pilih > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c)
                    do_copy_with_retry "$PROJECT_FILE"
                    ;;
                2|recreate|r)
                    echo -e "${YELLOW}[*] Recreate obfuscate dengan variasi baru...${RESET}"
                    cp "$BACKUP_FILE" "$PROJECT_FILE"
                    do_obfuscate
                    break
                    ;;
                3|open|o)
                    echo -e "${YELLOW}[*] Menyiapkan obfuscate-code.lua...${RESET}"
                    cp "$PROJECT_FILE" "./obfuscate-code.lua"
                    echo -e "${GREEN}[*] Membuka nano obfuscate-code.lua (hasil obfuscate)${RESET}"
                    echo -e "${CYAN}    Isinya adalah code obfuscate yang sudah jadi${RESET}"
                    sleep 0.8
                    nano "./obfuscate-code.lua"
                    echo -e "${GREEN}[✓] File obfuscate-code.lua tersimpan${RESET}"
                    ;;
                4|exit|e|q)
                    break
                    ;;
                *)
                    echo -e "${RED}Pilihan tidak valid${RESET}"
                    ;;
            esac
        done
        rm -f "$tmp_out"
    else
        echo -e "${RED}[x] Gagal validasi setelah 5x test${RESET}"
    fi
}

handle_start() {
    echo -e "${YELLOW}[*] Menyiapkan project $PROJECT_FILE${RESET}"
    if [ ! -f "$PROJECT_FILE" ]; then
        echo '-- Tulis code Lua lu disini' > "$PROJECT_FILE"
        echo 'print("Hello World")' >> "$PROJECT_FILE"
    fi
    echo -e "${GREEN}[*] Membuka nano... (save: CTRL+O, exit: CTRL+X)${RESET}"
    sleep 1
    nano "$PROJECT_FILE"
    
    if [ ! -s "$PROJECT_FILE" ]; then
        echo -e "${RED}[x] File kosong, batal obfuscate${RESET}"
        return
    fi

    echo -e "${CYAN}--- Preview code sebelum obfuscate ---${RESET}"
    head -n 20 "$PROJECT_FILE"
    echo -e "${CYAN}--------------------------------------${RESET}"
    echo -ne "${YELLOW}Lanjut obfuscate? (y/n): ${RESET}"
    read -r yn
    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
        do_obfuscate
    else
        echo -e "${RED}Batal.${RESET}"
    fi
}

handle_setting() {
    while true; do
        init_settings
        clear
        show_banner
        echo -e "${WHITE}=== SETTING OBFUSCATE ===${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "1. Oneline Mode      : ${YELLOW}$oneline${RESET} (on/off)"
        echo -e "2. Damage Level      : ${YELLOW}$damage${RESET} (1-5) - seberapa rusak di mata"
        echo -e "   1 = rapi, 5 = sangat hancur & susah dibaca"
        echo -e "3. Anti Bug         : ${YELLOW}$anti_bug${RESET} (on/off)"
        echo -e "4. Kembali ke menu"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -ne "${CYAN}Pilih setting (1-4) > ${RESET}"
        read -r s
        case "$s" in
            1)
                echo -ne "oneline (on/off) > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}Saved!${RESET}"
                else
                    echo -e "${RED}Input harus on/off${RESET}"
                fi
                sleep 1
                ;;
            2)
                echo -ne "damage level (1-5) > "
                read -r val
                if [[ "$val" =~ ^[1-5]$ ]]; then
                    sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}Saved!${RESET}"
                else
                    echo -e "${RED}Harus 1-5${RESET}"
                fi
                sleep 1
                ;;
            3)
                echo -ne "anti_bug (on/off) > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^anti_bug=.*/anti_bug=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}Saved!${RESET}"
                fi
                sleep 1
                ;;
            4|exit|q)
                break
                ;;
        esac
    done
}

init_settings
init_engine

while true; do
    show_banner
    show_menu
    read -r input
    cmd=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)

    case "$cmd" in
        start|1|s)
            handle_start
            echo -e "${YELLOW}Tekan enter untuk kembali...${RESET}"
            read -r
            ;;
        setting|settings|2|set)
            handle_setting
            ;;
        exit|3|q|quit)
            echo -e "${GREEN}Bye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Perintah tidak dikenal: $input (ketik: start / setting / exit)${RESET}"
            sleep 1
            ;;
    esac
done
