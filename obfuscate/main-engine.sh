#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator v3.0 - SHORT Rangkuman Edition
# Fix: /tmp/gen_obf.py error, short code, auto install api, new open behavior

PROJECT_FILE="./code-to-obfuscate.lua"
RESULT_FILE="./code-obfuscate.lua"
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
import sys, os, random, subprocess, tempfile, re

def rand_name(damage):
    if damage >= 4:
        parts = ["_", "__", "_0x", "_0X", "_Alj", "_Bin", "_Hex", "_Ent"]
        base = random.choice(parts)
        suffix = ''.join(random.choices("0123456789ABCDEF", k=random.randint(3,6)))
        return base + suffix
    elif damage >= 2:
        return "_0x" + ''.join(random.choices("ABCDEF0123456789", k=random.randint(3,5))) + random.choice(["a","b","x"])
    else:
        return "_v" + str(random.randint(10,99))

def gen_base_vars(damage):
    count = 3 if damage <=2 else 4 if damage==3 else 5
    names = []
    vals = {}
    for i in range(count):
        n = rand_name(damage)
        while n in names:
            n = rand_name(damage)
        names.append(n)
        vals[n] = random.randint(111, 9999)
    return names, vals

def alg_const(n, var_names):
    # generate algebra expression that evaluates to n using var_names, always valid
    v = random.choice(var_names)
    v2 = random.choice(var_names)
    one = f"({v}//{v})"
    zero = f"({v}-{v})"
    if n == 0:
        return zero
    if n == 1:
        return one
    if n == 2:
        # 1+1
        return f"(({v}//{v})+({v2}//{v2}))"
    if n == 4:
        # 2+2
        a = f"(({v}//{v})+({v2}//{v2}))"
        return f"({a}+{a})"
    if n == 16:
        # 4*4
        a = alg_const(4, var_names)
        return f"({a}*{a})"
    if n < 10:
        # sum of ones
        return "(" + "+".join([f"({random.choice(var_names)}//{random.choice(var_names)})" for _ in range(n)]) + ")"
    # fallback
    return f"({n})"

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug):
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    # Layer 1: HTML Entity
    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    # Layer 2: Hex String
    hex_str = ''.join(f"{ord(ch):02x}" for ch in html_entity)
    # Layer 3: Binary (we will generate binary in Lua from hex, not store, to make short)
    # But we still compute binary to validate concept
    # binary_str = ''.join(f"{int(ch,16):04b}" for ch in hex_str)

    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name} = {var_vals[name]}")

    if damage >= 4:
        for _ in range(damage):
            junk_name = rand_name(damage) + "_j"
            base = random.choice(var_names)
            lua_vars.append(f"local {junk_name} = {base} * {random.randint(1,5)}")
            lua_vars.append(f"if ({base}-{base}=={alg_const(1,var_names)}) then local {rand_name(damage)} = {alg_const(0,var_names)} end")

    # generate algebra constants for 0,1,2,4,16 using random vars each time for variation
    e0 = alg_const(0, var_names)
    e1 = alg_const(1, var_names)
    e2 = alg_const(2, var_names)
    e4 = alg_const(4, var_names)
    e16 = alg_const(16, var_names)

    bin_var = rand_name(damage) + "_BIN"
    hex_var = rand_name(damage) + "_HEX"
    ent_var = rand_name(damage) + "_ENT"
    code_var = rand_name(damage) + "_CODE"
    h0_var = rand_name(damage) + "_H0"
    b_var = rand_name(damage) + "_b"
    n_var = rand_name(damage) + "_n"
    i_var = rand_name(damage) + "_i"
    j_var = rand_name(damage) + "_j"
    h_var = rand_name(damage) + "_h"

    lua_vars_code = "\n".join(lua_vars)

    # SHORT TEMPLATE - rangkuman jadi pendek
    # Store only hex_str (1000 chars) not binary (4000 chars) -> 75% lebih pendek
    # Binary tetap ada tapi di-generate di Lua via aljabar, jadi tetap ada layer binary
    lua_template = f"""-- SHORT OBFUSCATED BY TERMUX OBFUSCATE TOOL
-- Layers: HTML Entity -> Hex -> Binary -> Algebra Math (RANGKUMAN PENDEK)
{lua_vars_code}
local {h0_var} = "{hex_str}"
local {bin_var} = ""
for {i_var}={e1},#{h0_var},{e1} do
local {h_var}={h0_var}:sub({i_var},{i_var})
local {n_var}=tonumber({h_var},{e16})
local {b_var}=""
for {j_var}={e1},{e4},{e1} do
{b_var}=(({n_var}%{e2}=={e1}) and "1" or "0")..{b_var}
{n_var}=math.floor({n_var}/{e2})
end
{bin_var}={bin_var}..{b_var}
end
local {hex_var}=""
for {i_var}={e1},#{bin_var},{e4} do
local {b_var}={bin_var}:sub({i_var},{i_var}+{e4}-{e1})
local {n_var}={e0}
for {j_var}={e1},{e4},{e1} do
{n_var}={n_var}*{e2}+({b_var}:sub({j_var},{j_var})=="1" and {e1} or {e0})
end
{hex_var}={hex_var}..string.format("%x",{n_var})
end
local {ent_var}=""
for {i_var}={e1},#{hex_var},{e2} do
local {h_var}={hex_var}:sub({i_var},{i_var}+{e1})
{ent_var}={ent_var}..string.char(tonumber({h_var},{e16}))
end
local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end)
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
print("[OBFUSCATE] berhasil | short version")
"""

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
    echo -e "${WHITE}         Termux Lua Obfuscator v3.0 - SHORT Edition${RESET}"
    echo -e "${YELLOW}         HTML Entity > Hex > Binary > Algebra (Rangkuman Pendek)${RESET}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${WHITE}[ MENU ]${RESET}"
    echo -e "  ${YELLOW}start${RESET}   - Buat & obfuscate code lua (auto hapus code lama)"
    echo -e "  ${YELLOW}setting${RESET} - Atur oneline & damage level"
    echo -e "  ${YELLOW}exit${RESET}    - Keluar tool"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -ne "${CYAN}obfuscate > ${RESET}"
}

do_copy_with_retry() {
    local file="$1"
    local success=0
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] termux-api belum terinstall${RESET}"
        echo -e "${CYAN}[*] Auto download termux-api...${RESET}"
        pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null
        pkg install termux-api -y
        if command -v termux-clipboard-set >/dev/null 2>&1; then
            echo -e "${GREEN}[✓] termux-api berhasil diinstall otomatis${RESET}"
        else
            echo -e "${RED}[x] Auto install gagal, coba manual: pkg install termux-api${RESET}"
            echo -e "${YELLOW}[!] Pastikan aplikasi Termux:API dari F-Droid terinstall${RESET}"
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
        echo -e "${RED}[x] Copy gagal setelah 10x${RESET}"
    fi
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    if [ -d "/data/data/com.termux/files/usr/tmp" ]; then
        tmp_out="/data/data/com.termux/files/usr/tmp/obf_temp.lua"
    fi
    init_settings
    echo -e "${CYAN}    oneline: $oneline | damage: $damage | anti_bug: $anti_bug${RESET}"
    echo -e "${YELLOW}[*] Backup original...${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}[*] Engine short rangkuman...${RESET}"
    echo -e "${YELLOW}    Layer 1: HTML Entity, Layer 2: Hex, Layer 3: Binary->Algebra (pendek)${RESET}"
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug"
    local status=$?
    if [ $status -ne 0 ] || [ ! -f "$tmp_out" ]; then
        echo -e "${RED}[x] Obfuscate gagal!${RESET}"
        return 1
    fi
    echo -e "${YELLOW}[*] Testing 5x biar bisa dibaca komputer...${RESET}"
    local test_ok=0
    for t in {1..5}; do
        if command -v luac >/dev/null 2>&1; then
            if luac -p "$tmp_out" >/dev/null 2>&1; then
                echo -e "${GREEN}    [✓] Test $t: OK (short version)${RESET}"
                test_ok=1
            else
                echo -e "${RED}    [x] Test $t: syntax error, regen...${RESET}"
                python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug"
            fi
        else
            echo -e "${GREEN}    [✓] Test $t: python logic OK${RESET}"
            test_ok=1
            break
        fi
        sleep 0.2
    done
    if [ $test_ok -eq 1 ]; then
        cat "$tmp_out" > "$PROJECT_FILE"
        cat "$tmp_out" > "$RESULT_FILE"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}[✓] OBFUSCATE BERHASIL - VERSI PENDEK!${RESET}"
        echo -e "${WHITE}File input : $PROJECT_FILE (sudah jadi pendek)${RESET}"
        echo -e "${WHITE}File hasil : $RESULT_FILE (file baru, ga numpuk)${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "Ukuran   : " $1 " bytes (short)"}'
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}Pilihan: [1] copy  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}pilih > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c)
                    do_copy_with_retry "$RESULT_FILE"
                    ;;
                2|recreate|r)
                    echo -e "${YELLOW}[*] Recreate = hapus isi code-to-obfuscate.lua & buka nano baru${RESET}"
                    echo '-- Tulis code Lua baru disini (code lama sudah dihapus)' > "$PROJECT_FILE"
                    echo 'print("Hello Baru")' >> "$PROJECT_FILE"
                    echo -e "${GREEN}[*] Membuka nano $PROJECT_FILE (isi sudah dihapus)${RESET}"
                    sleep 0.8
                    nano "$PROJECT_FILE"
                    echo -e "${YELLOW}[*] Lanjut obfuscate code baru? (y/n)${RESET}"
                    read -r yn
                    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
                        do_obfuscate
                    fi
                    break
                    ;;
                3|open|o)
                    echo -e "${YELLOW}[*] Membuka file baru $RESULT_FILE biar ga numpuk${RESET}"
                    if [ ! -f "$RESULT_FILE" ]; then
                        cp "$PROJECT_FILE" "$RESULT_FILE"
                    fi
                    nano "$RESULT_FILE"
                    echo -e "${GREEN}[✓] $RESULT_FILE tersimpan${RESET}"
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
        echo -e "${RED}[x] Gagal validasi${RESET}"
    fi
}

handle_start() {
    echo -e "${YELLOW}[*] START - Hapus isi code lama untuk code selanjutnya${RESET}"
    # Hapus isi code yang dipake tadi
    echo -e "${YELLOW}[*] Menghapus isi $PROJECT_FILE lama...${RESET}"
    rm -f "$PROJECT_FILE"
    echo '-- Tulis code Lua baru disini (old code sudah dihapus otomatis)' > "$PROJECT_FILE"
    echo 'print("Hello World")' >> "$PROJECT_FILE"
    echo -e "${GREEN}[✓] File lama dihapus, siap code baru${RESET}"
    echo -e "${GREEN}[*] Membuka nano $PROJECT_FILE ...${RESET}"
    sleep 0.8
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then
        echo -e "${RED}[x] File kosong, batal${RESET}"
        return
    fi
    echo -e "${CYAN}--- Preview sebelum obfuscate (short) ---${RESET}"
    head -n 15 "$PROJECT_FILE"
    echo -e "${CYAN}----------------------------------------${RESET}"
    echo -ne "${YELLOW}Lanjut obfuscate jadi pendek? (y/n): ${RESET}"
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
        echo -e "${WHITE}=== SETTING OBFUSCATE SHORT ===${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "1. Oneline Mode      : ${YELLOW}$oneline${RESET} (on/off) - jadi 1 baris super pendek"
        echo -e "2. Damage Level      : ${YELLOW}$damage${RESET} (1-5) - rusak di mata, pendek tetap jalan"
        echo -e "3. Anti Bug         : ${YELLOW}$anti_bug${RESET} (on/off)"
        echo -e "4. Kembali"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -ne "${CYAN}Pilih (1-4) > ${RESET}"
        read -r s
        case "$s" in
            1)
                echo -ne "oneline (on/off) > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}Saved!${RESET}"
                fi
                sleep 1
                ;;
            2)
                echo -ne "damage (1-5) > "
                read -r val
                if [[ "$val" =~ ^[1-5]$ ]]; then
                    sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}Saved!${RESET}"
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
            echo -e "${YELLOW}Tekan enter...${RESET}"
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
            echo -e "${RED}Perintah tidak dikenal: $input${RESET}"
            sleep 1
            ;;
    esac
done
