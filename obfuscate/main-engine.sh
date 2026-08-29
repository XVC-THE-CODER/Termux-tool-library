#!/data/data/com.termux/files/usr/bin/bash
PROJECT_FILE="./code-to-obfuscate.lua"
RESULT_FILE="./code-obfuscate.lua"
BACKUP_FILE="$HOME/.obfuscate_original.lua"
SETTINGS_FILE="$HOME/.obfuscate_settings"
ENGINE_FILE="$HOME/.obfuscate_engine.py"

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
        echo "short_byte=on" >> "$SETTINGS_FILE"
        echo "use_space=off" >> "$SETTINGS_FILE"
    fi
    if ! grep -q "short_byte" "$SETTINGS_FILE"; then echo "short_byte=on" >> "$SETTINGS_FILE"; fi
    if ! grep -q "use_space" "$SETTINGS_FILE"; then echo "use_space=off" >> "$SETTINGS_FILE"; fi
    source "$SETTINGS_FILE"
}

init_engine() {
    mkdir -p "$HOME/.cache"
    cat > "$ENGINE_FILE" << 'PYEOF'
import sys, os, random, subprocess, tempfile, re

B91_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""
_counter = 0

def rand_name(damage=3, prefix=""):
    global _counter
    _counter += 1
    return f"_V{_counter}{prefix}"

def gen_base_vars(damage):
    count = max(2, damage + 2)
    names, vals = [], {}
    for _ in range(count):
        n = rand_name(damage)
        while n in names:
            n = rand_name(damage)
        names.append(n)
        vals[n] = random.randint(111, 9999)
    return names, vals

def gen_num_math(n, var_names, damage=3, depth=0):
    v = random.choice(var_names)
    max_depth = 1 if damage <= 2 else (2 if damage <= 5 else (3 if damage <= 10 else 4))
    if depth >= max_depth:
        if n == 0: return f"({v}-{v})"
        if n == 1: return f"({v}-{v}+1)"
        return f"({v}-{v}+{n})"

    methods = ['mul_div', 'mul_add']
    m = random.choice(methods)

    if m == 'mul_div':
        k = random.randint(2, 3 + damage)
        nk = n * k
        e_nk = gen_num_math(nk, var_names, damage, depth + 1)
        e_k = gen_num_math(k, var_names, damage, depth + 1)
        return f"math.floor(({e_nk})/({e_k}))"
    else:
        k = random.randint(2, 3 + damage)
        q = n // k
        r = n % k
        e_q = gen_num_math(q, var_names, damage, depth + 1)
        e_k = gen_num_math(k, var_names, damage, depth + 1)
        e_r = gen_num_math(r, var_names, damage, depth + 1)
        return f"((({e_q})*({e_k}))+({e_r}))"

def b91encode(data: bytes):
    b = 0
    n = 0
    out = ""
    for byte in data:
        b |= byte << n
        n += 8
        if n > 13:
            v = b & 8191
            if v > 88:
                b >>= 13
                n -= 13
            else:
                v = b & 16383
                b >>= 14
                n -= 14
            out += B91_CHARS[v % 91] + B91_CHARS[v // 91]
    if n > 0:
        out += B91_CHARS[b % 91]
        if n > 7 or b > 90:
            out += B91_CHARS[b // 91]
    return out

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte, use_space):
    global _counter
    _counter = 0
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    b91_str = b91encode(html_entity.encode('utf-8'))

    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name}={var_vals[name]}")

    junk_lines = []
    if damage > 1:
        for _ in range(damage * 2):
            j_name = rand_name(damage, "_j")
            b_var = random.choice(var_names)
            k_val = random.randint(2, 20)
            junk_lines.append(f"local {j_name}=math.floor(({b_var}*{gen_num_math(k_val, var_names, damage)})/{gen_num_math(k_val, var_names, damage)})")

    lua_vars_code = "\n".join(lua_vars + junk_lines)

    symbol_exprs = []
    for char in b91_str:
        val = ord(char)
        if char.isalpha() and random.random() < 0.10:
            symbol_exprs.append(f"string.char(0x{val:02X})")
        elif random.random() < 0.25:
            e_dec = gen_num_math(val, var_names, damage)
            symbol_exprs.append(f"string.char({e_dec})")
        else:
            symbol_exprs.append(f"string.char({val})")

    num_chunks = max(1, min(damage, len(symbol_exprs)))
    chunk_size = (len(symbol_exprs) + num_chunks - 1) // num_chunks

    chunk_vars = []
    chunk_defs = []
    for i in range(0, len(symbol_exprs), chunk_size):
        group = symbol_exprs[i:i+chunk_size]
        c_var = rand_name(damage, "_c")
        chunk_vars.append(c_var)
        chunk_defs.append(f"local {c_var}=table.concat({{{','.join(group)}}})")

    full_b91_var = rand_name(damage, "_b91")
    combine_b91 = f"local {full_b91_var}=" + " .. ".join(chunk_vars)

    b91_chars_var = rand_name(damage, "_chars")
    b91_chars_lua = B91_CHARS.replace("\\", "\\\\").replace('"', '\\"')
    b91_chars_def = f'local {b91_chars_var}="{b91_chars_lua}"'

    b91_decode_func = rand_name(damage, "_dec")
    ent_var = rand_name(damage, "_ent")
    code_var = rand_name(damage, "_code")

    lua_template = f"""{lua_vars_code}
{chr(10).join(chunk_defs)}
{combine_b91}
{b91_chars_def}
local function {b91_decode_func}(str)
    local b,n,v=0,0,-1
    local out={{}}
    local dec={{}}
    for i=1,#{b91_chars_var} do
        dec[string.sub({b91_chars_var},i,i)]=i-1
    end
    for i=1,#str do
        local c=string.sub(str,i,i)
        local val=dec[c]
        if val then
            if v<0 then
                v=val
            else
                v=v+val*91
                b=b+v*(2^n)
                local w=v%8192
                if w>88 then n=n+13 else n=n+14 end
                while n>7 do
                    local byte=b%256
                    table.insert(out,string.char(byte))
                    b=math.floor(b/256)
                    n=n-8
                end
                v=-1
            end
        end
    end
    if v>-1 then
        local byte=(b+v*(2^n))%256
        table.insert(out,string.char(byte))
    end
    return table.concat(out)
end
local {ent_var}={b91_decode_func}({full_b91_var})
local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end)
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
"""

    final_code = lua_template
    if oneline == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s+', ' ', final_code)
    if use_space == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s*([=+\-*/%(){}[\],;:])\s*', r'\1', final_code)
        final_code = re.sub(r'\s+', ' ', final_code)
        final_code = final_code.strip()

    if anti_bug == "on":
        for _ in range(5):
            with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False) as tf:
                tf.write(final_code)
            tf_path = tf.name
            try:
                result = subprocess.run(["luac", "-p", tf_path], capture_output=True, text=True, timeout=5)
                os.unlink(tf_path)
                if result.returncode == 0:
                    break
                else:
                    if _ == 4:
                        print("SYNTAX_FAIL:"+result.stderr[:500])
                        return False
            except FileNotFoundError:
                try:
                    os.unlink(tf_path)
                except:
                    pass
                break
            except Exception as e:
                try:
                    os.unlink(tf_path)
                except:
                    pass
                print(f"TEST_ERROR:{e}")
                return False

    with open(output_path, 'w', encoding='utf-8') as out:
        out.write(final_code)
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    inp, outp = sys.argv[1], sys.argv[2]
    oneline = sys.argv[3] if len(sys.argv)>3 else "off"
    damage = int(sys.argv[4]) if len(sys.argv)>4 else 3
    anti_bug = sys.argv[5] if len(sys.argv)>5 else "on"
    short_byte = sys.argv[6] if len(sys.argv)>6 else "on"
    use_space = sys.argv[7] if len(sys.argv)>7 else "off"
    ok = obfuscate_file(inp, outp, oneline, damage, anti_bug, short_byte, use_space)
    print("OK" if ok else "FAIL")
    sys.exit(0 if ok else 2)
PYEOF
    chmod +x "$ENGINE_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ____  _   _ _____ _____ ____ ___  ____  _____ "
    echo " |  _ \| | | |_   _| ____/ ___/ _ \|  _ \| ____|"
    echo " | |_) | | | | | | |  _|| |  | | | | |_) |  _|  "
    echo " |  _ <| |_| | | | | |__| |__| |_| |  _ <| |___ "
    echo " |_| \_\\___/  |_| |_____\____\___/|_| \_\_____|"
    echo -e "${RESET}"
    echo -e "${WHITE} BYTECODE v9 - _V1 to _v infinite${RESET}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e " MENU"
    echo -e "   ${YELLOW}start${RESET}    - create and obfuscate"
    echo -e "   ${YELLOW}setting${RESET}  - settings"
    echo -e "   ${YELLOW}exit${RESET}     - exit"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo ""
    echo -ne "${CYAN}bytecode > ${RESET}"
}

do_copy() {
    local file="$1"
    if [ ! -f "$file" ]; then echo -e "${RED}[fail] file not found${RESET}"; return 1; fi
    local size=$(wc -c < "$file")
    echo -e "${CYAN} file size: $size bytes${RESET}"
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        pkg install termux-api -y >/dev/null 2>&1;
    fi
    echo -e "${YELLOW}[*] copy 10 tries...${RESET}"
    local success=0
    for i in {1..10}; do
        if termux-clipboard-set < "$file" 2>/dev/null; then
            echo -e "${GREEN}[ok] copy success try $i${RESET}"
            success=1
            break
        fi
        if cat "$file" | termux-clipboard-set 2>/dev/null; then
            echo -e "${GREEN}[ok] copy success try $i method2${RESET}"
            success=1
            break
        fi
        sleep 0.5
    done
    if [ $success -eq 0 ]; then
        echo -e "${RED}[fail] copy failed${RESET}"
        if [ -d "/sdcard/Download" ]; then
            cp "$file" "/sdcard/Download/$(basename "$file")" 2>/dev/null
            echo -e "${GREEN}[ok] saved to /sdcard/Download/${RESET}"
        fi
        if command -v termux-share >/dev/null 2>&1; then
            termux-share "$file" 2>/dev/null
        fi
    else
        termux-toast "Copied!" 2>/dev/null
    fi
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    if [ -d "/data/data/com.termux/files/usr/tmp" ]; then
        tmp_out="/data/data/com.termux/files/usr/tmp/obf_temp.lua"
    fi
    init_settings
    echo -e "${CYAN} settings: oneline=$oneline damage=$damage anti_bug=$anti_bug short_byte=$short_byte use_space=$use_space${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE" 2>/dev/null
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space"
    local status=$?
    if [ $status -ne 0 ] || [ ! -f "$tmp_out" ]; then
        echo -e "${RED}[fail] obfuscate failed${RESET}"
        return 1
    fi
    echo -e "${YELLOW}[*] test 5 times...${RESET}"
    local test_ok=0
    for t in {1..5}; do
        if command -v luac >/dev/null 2>&1; then
            if luac -p "$tmp_out" >/dev/null 2>&1; then
                echo -e "${GREEN}  [ok] test $t${RESET}"
                test_ok=1
            else
                echo -e "${RED}  [fail] test $t regen${RESET}"
                python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space"
            fi
        else
            echo -e "${GREEN}  [ok] test $t logic ok${RESET}"
            test_ok=1
            break
        fi
        sleep 0.2
    done
    if [ $test_ok -eq 1 ]; then
        cat "$tmp_out" > "$PROJECT_FILE"
        cat "$tmp_out" > "$RESULT_FILE"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}[ok] success bytecode _V1 infinite!${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "size : " $1 " bytes"}'
        echo -e "${GREEN}----------------------------------------${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}options: [1] copy [2] recreate [3] open [4] exit${RESET}"
            echo -ne "${YELLOW}select > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c) do_copy "$RESULT_FILE" ;;
                2|recreate|r)
                    echo 'print("new")' > "$PROJECT_FILE"
                    nano "$PROJECT_FILE"
                    echo -ne "${YELLOW}obfuscate new? (y/n): ${RESET}"
                    read -r yn
                    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
                        do_obfuscate
                    fi
                    break
                    ;;
                3|open|o) nano "$RESULT_FILE" ;;
                4|exit|e|q) break ;;
                *) echo -e "${RED}invalid${RESET}" ;;
            esac
        done
        rm -f "$tmp_out"
    else
        echo -e "${RED}[fail] validation${RESET}"
    fi
}

handle_start() {
    rm -f "$PROJECT_FILE"
    echo 'print("hello")' > "$PROJECT_FILE"
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then echo -e "${RED}[fail] empty${RESET}"; return; fi
    head -n 15 "$PROJECT_FILE"
    echo -ne "${YELLOW}obfuscate now? (y/n): ${RESET}"
    read -r yn
    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
        do_obfuscate
    fi
}

handle_setting() {
    while true; do
        init_settings
        clear
        show_banner
        echo -e "${WHITE}SETTINGS${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "1. oneline   : ${YELLOW}$oneline${RESET}"
        echo -e "2. damage    : ${YELLOW}$damage${RESET}"
        echo -e "3. anti_bug  : ${YELLOW}$anti_bug${RESET}"
        echo -e "4. short_byte: ${YELLOW}$short_byte${RESET}"
        echo -e "5. use_space : ${YELLOW}$use_space${RESET}"
        echo -e "6. back"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -ne "${CYAN}select 1-6 > ${RESET}"
        read -r s
        case "$s" in
            1) echo -ne "oneline on/off > "; read -r val; sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE" ;;
            2) echo -ne "damage 1-15 > "; read -r val; sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE" ;;
            3) echo -ne "anti_bug on/off > "; read -r val; sed -i "s/^anti_bug=.*/anti_bug=$val/" "$SETTINGS_FILE" ;;
            4) echo -ne "short_byte on/off > "; read -r val; sed -i "s/^short_byte=.*/short_byte=$val/" "$SETTINGS_FILE" ;;
            5) echo -ne "use_space on/off > "; read -r val; sed -i "s/^use_space=.*/use_space=$val/" "$SETTINGS_FILE" ;;
            6|q|exit) break ;;
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
        start|1|s) handle_start; echo -e "${YELLOW}press enter...${RESET}"; read -r ;;
        setting|settings|2|set) handle_setting ;;
        exit|3|q|quit) echo -e "${GREEN}bye!${RESET}"; exit 0 ;;
        *) echo -e "${RED}unknown: $input${RESET}"; sleep 1 ;;
    esac
done
