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

module_settings() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        mkdir -p "$(dirname "$SETTINGS_FILE")"
        echo "oneline=off" > "$SETTINGS_FILE"
        echo "damage=2" >> "$SETTINGS_FILE"
        echo "anti_bug=on" >> "$SETTINGS_FILE"
        echo "short_byte=on" >> "$SETTINGS_FILE"
        echo "use_space=on" >> "$SETTINGS_FILE"
    fi
    if ! grep -q "short_byte" "$SETTINGS_FILE"; then echo "short_byte=on" >> "$SETTINGS_FILE"; fi
    if ! grep -q "use_space" "$SETTINGS_FILE"; then echo "use_space=on" >> "$SETTINGS_FILE"; fi
    source "$SETTINGS_FILE"
}

module_py_imports() {
    cat << 'PY_IMPORTS'
import sys, os, random, subprocess, tempfile, re

B91_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""
_counter = 0
PY_IMPORTS
}

module_py_naming() {
    cat << 'PY_NAMING'
def rand_name(damage=2, prefix=""):
    global _counter
    _counter += 1
    return f"_V{_counter}{prefix}"

def gen_base_vars(damage):
    count = max(2, damage + 1)
    names, vals = [], {}
    for _ in range(count):
        n = rand_name(damage)
        while n in names:
            n = rand_name(damage)
        names.append(n)
        vals[n] = random.randint(11, 99)
    return names, vals
PY_NAMING
}

module_py_math() {
    cat << 'PY_MATH'
def gen_num_math(n, var_names):
    v = random.choice(var_names)
    if n == 0: return f"({v}-{v})"
    if n == 1: return f"({v}-{v}+1)"
    return f"({v}-{v}+{n})"
PY_MATH
}

module_py_encoder() {
    cat << 'PY_ENCODER'
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
PY_ENCODER
}

module_py_transformer() {
    cat << 'PY_TRANSFORMER'
def obfuscate_user_code(user_code, damage):
    global _counter
    if not user_code.strip():
        return ""

    html_parts = []
    for c in user_code:
        if random.random() < 0.50:
            html_parts.append(f"\\u{{{ord(c):X}}}")
        else:
            html_parts.append(f"&#{ord(c)};")
    html_entity = "".join(html_parts)

    b91_str = b91encode(html_entity.encode('utf-8'))

    var_names, var_vals = gen_base_vars(damage)
    lua_vars = [f"local {name}={var_vals[name]}" for name in var_names]
    lua_vars_code = "\n".join(lua_vars)

    symbol_exprs = []
    for char in b91_str:
        val = ord(char)
        if random.random() < 0.15:
            symbol_exprs.append(f"string.char({gen_num_math(val, var_names)})")
        else:
            symbol_exprs.append(f"string.char({val})")

    num_chunks = max(1, min(damage, len(symbol_exprs)))
    chunk_size = (len(symbol_exprs) + num_chunks - 1) // num_chunks

    chunk_vars, chunk_defs = [], []
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

    obf_snippet = f\"\"\"{lua_vars_code}
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
local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end):gsub("\\\\u{{(%x+)}}",function(n) return string.char(tonumber(n,16)) end)
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end\"\"\"
    return obf_snippet

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte, use_space):
    global _counter
    _counter = 0
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        user_code = f.read()
    if not user_code.strip():
        print("EMPTY")
        return False

    obfuscated_user_code = obfuscate_user_code(user_code, damage)

    cff_raw_wrapper = f'''
local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
local salt = "XyZ_88_SecretSalt"
local k = 211

local function hashSalt(s)
    local h = 0
    for i=1,#s do
        h = (h * 31 + string.byte(s, i)) % 1000000
    end
    return h
end

local function genKey(minute)
    local seed = minute + hashSalt(salt)
    math.randomseed(seed)
    local key = ""
    for i=1,12 do
        local idx = math.random(1, #charset)
        key = key .. string.sub(charset, idx, idx)
    end
    return key
end

local function verifyKey(input)
    local currentMinute = math.floor(os.time() / 60)
    local keyNow = genKey(currentMinute)
    local keyPrev = genKey(currentMinute - 1)
    if input == keyNow or input == keyPrev then
        return true
    end
    return false
end

local function getClues(key)
    local front = string.sub(key, 1, 4)
    local middle = string.sub(key, 5, 8)
    local back = string.sub(key, 9, 12)
    local countUpper, countLower, countDigit, countSymbol = 0,0,0,0
    local posUpper, posLower = {{}},{{}}
    for i=1,#key do
        local c = string.sub(key, i, i)
        if c:match("%u") then countUpper = countUpper + 1 table.insert(posUpper, i)
        elseif c:match("%l") then countLower = countLower + 1 table.insert(posLower, i)
        elseif c:match("%d") then countDigit = countDigit + 1
        else countSymbol = countSymbol + 1 end
    end
    return {{
        frontType = "mixed",
        middleType = "mixed", 
        backType = "mixed",
        countUpper = countUpper,
        countLower = countLower,
        countDigit = countDigit,
        countSymbol = countSymbol,
        posUpper = posUpper,
        posLower = posLower
    }}
end

local tries = 0
local maxTries = 3

local function labyrinth()
    local x = 0
    for i=1,500000 do
        x = (x + i * 31) % 1000000
    end
    return x
end

local _state = 101
local _blocks = {{}}

local function decodeState(s)
    return (s - 100)
end

_blocks[1] = function()
    local execName = "Unknown"
    if identifyexecutor then
        execName = identifyexecutor()
    elseif getexecutorname then
        execName = getexecutorname()
    end
    print("[CFF] Executor: " .. tostring(execName))
    return 102
end

_blocks[2] = function()
    local a = string.byte("\\u{{61}}") - 97
    local b = string.byte("\\u{{62}}") - 97
    local c = string.byte("\\u{{63}}") - 97
    local calc = math.floor(math.sqrt((a + b + c + k) * 100))
    print("[CFF] Math check: " .. calc)
    return 103
end

_blocks[3] = function()
    print("[CFF] Enter 12-digit timed key (valid 1 min)")
    print("[CFF] Set _G.RenuxKey = 'key' dulu")
    local input = _G.RenuxKey or ""
    if input == "" then
        print("[CFF] No key! clue current key:")
        local cm = math.floor(os.time()/60)
        local ck = genKey(cm)
        local clues = getClues(ck)
        print("Count Upper: " .. clues.countUpper .. " Lower: " .. clues.countLower .. " Digit: " .. clues.countDigit .. " Symbol: " .. clues.countSymbol)
        print("Pos Upper: " .. table.concat(clues.posUpper, ",") .. " Pos Lower: " .. table.concat(clues.posLower, ","))
        return 106
    end
    if verifyKey(input) then
        print("[CFF] Key valid!")
        return 104
    else
        tries = tries + 1
        print("[CFF] Invalid! Try " .. tries .. "/" .. maxTries)
        if tries >= maxTries then
            return 105
        end
        return 103
    end
end

_blocks[4] = function()
    print("[CFF] Running protected main code...")
    labyrinth()
    {obfuscated_user_code}
    print("[CFF] Main executed successfully!")
    return 106
end

_blocks[5] = function()
    error("[CFF TRAP] Brute-force detected! Script locked.")
    return 106
end

_blocks[6] = function()
    print("[CFF] Exit")
    return nil
end

local mt = {{
    __index = function(t, k)
        if k == "bypass" or type(k) == "string" then
            error("[ANTI-BYPASS] Trap activated!")
        end
        return rawget(t, k)
    end,
    __newindex = function(t, k, v)
        error("[ANTI-TAMPER] Modification locked!")
    end
}}

setmetatable(_blocks, mt)

while true do
    if _state == nil then break end
    local realState = decodeState(_state)
    local f = rawget(_blocks, realState)
    if not f then break end
    _state = f()
end
'''

    final_code = cff_raw_wrapper
    if oneline == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s+', ' ', final_code)
    if use_space == "on":
        lines = [line.strip() for line in final_code.splitlines() if line.strip() and not line.strip().startswith("--")]
        final_code = " ".join(lines)

    if anti_bug == "on":
        while True:
            with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False) as tf:
                tf.write(final_code)
            tf_path = tf.name
            try:
                res_syntax = subprocess.run(["luac", "-p", tf_path], capture_output=True, text=True, timeout=5)
                if res_syntax.returncode == 0:
                    res_runtime = subprocess.run(["lua", tf_path], capture_output=True, text=True, timeout=5)
                    os.unlink(tf_path)
                    if res_runtime.returncode == 0:
                        break
                    else:
                        return False
                else:
                    os.unlink(tf_path)
                    return False
            except Exception:
                try: os.unlink(tf_path)
                except: pass
                return False

    with open(output_path, 'w', encoding='utf-8') as out:
        out.write(final_code)
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    inp, outp = sys.argv[1], sys.argv[2]
    oneline = sys.argv[3] if len(sys.argv)>3 else "off"
    damage = int(sys.argv[4]) if len(sys.argv)>4 else 2
    anti_bug = sys.argv[5] if len(sys.argv)>5 else "on"
    short_byte = sys.argv[6] if len(sys.argv)>6 else "on"
    use_space = sys.argv[7] if len(sys.argv)>7 else "on"
    ok = obfuscate_file(inp, outp, oneline, damage, anti_bug, short_byte, use_space)
    print("OK" if ok else "FAIL")
    sys.exit(0 if ok else 2)
PY_TRANSFORMER
}

init_engine() {
    mkdir -p "$HOME/.cache"
    module_py_imports > "$ENGINE_FILE"
    module_py_naming >> "$ENGINE_FILE"
    module_py_math >> "$ENGINE_FILE"
    module_py_encoder >> "$ENGINE_FILE"
    module_py_transformer >> "$ENGINE_FILE"
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
    echo -e "${WHITE} BYTECODE v9 - CFF RAW WRAPPER${RESET}"
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
    termux-clipboard-set < "$file" 2>/dev/null && echo -e "${GREEN}[ok] copied${RESET}" || echo -e "${RED}[fail] copy failed${RESET}"
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    module_settings
    cp "$PROJECT_FILE" "$BACKUP_FILE" 2>/dev/null
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space"
    local status=$?
    if [ $status -ne 0 ] || [ ! -f "$tmp_out" ]; then
        echo -e "${RED}[fail] obfuscate failed${RESET}"
        return 1
    fi
    cat "$tmp_out" > "$PROJECT_FILE"
    cat "$tmp_out" > "$RESULT_FILE"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "${GREEN}[ok] success obfuscated & runtime tested!${RESET}"
    wc -c "$RESULT_FILE" | awk '{print "size : " $1 " bytes"}'
    echo -e "${GREEN}----------------------------------------${RESET}"
    rm -f "$tmp_out"
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
}

handle_start() {
    rm -f "$PROJECT_FILE"
    echo 'print("Hello from custom script!")' > "$PROJECT_FILE"
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then echo -e "${RED}[fail] empty${RESET}"; return; fi
    do_obfuscate
}

handle_setting() {
    while true; do
        module_settings
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

module_settings
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
