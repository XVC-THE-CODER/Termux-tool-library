#!/data/data/com.termux/files/usr/bin/bash
# RENUX HUB v10 - SINGLE FILE tapi ENGINE PY DIPISAH
# Semua generator py dipisah tapi tetap di 1 file .sh ini

PROJECT_FILE="./code-to-obfuscate.lua"
RESULT_FILE="./code-obfuscate.lua"
BACKUP_FILE="$HOME/.obfuscate_original.lua"
SETTINGS_FILE="$HOME/.obfuscate_settings"
ENGINE_DIR="$HOME/.obfuscator_engine"
ENGINE_FILE="$ENGINE_DIR/engine.py"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

init_settings() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        mkdir -p "$(dirname "$SETTINGS_FILE")"
        cat > "$SETTINGS_FILE" << SETEOF
oneline=off
damage=5
anti_bug=on
short_byte=on
use_space=off
use_cff=on
use_key=on
salt=XyZ_88_SecretSalt
SETEOF
    fi
    source "$SETTINGS_FILE"
}

init_engine() {
    mkdir -p "$ENGINE_DIR"
    mkdir -p "$HOME/.cache"

    # === 1. encoder.py ===
    cat > "$ENGINE_DIR/encoder.py" << 'PYEOF'

B91_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""

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

def html_entity_encode(s: str):
    return ''.join(f"&#{ord(c)};" for c in s)

PYEOF

    # === 2. math_obf.py ===
    cat > "$ENGINE_DIR/math_obf.py" << 'PYEOF'

import random
_counter = 0

def reset():
    global _counter
    _counter = 0

def rand_name(prefix="_V"):
    global _counter
    _counter += 1
    # acak suffix biar infinite _V1 _v dll
    if random.random() < 0.5:
        return f"{prefix}{_counter}"
    else:
        return f"{prefix.lower()}{_counter}"

def gen_base_vars(damage):
    count = max(3, damage + 2)
    names, vals = [], {}
    for _ in range(count):
        n = rand_name()
        while n in names:
            n = rand_name()
        names.append(n)
        vals[n] = random.randint(111, 9999)
    return names, vals

def gen_num_math(n, var_names, damage=3, depth=0):
    import random
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

def unicode_math_obf(n, var_names, damage):
    # string.byte("\u{61}") - 97 style
    hex_val = format(n + 97, 'x')
    base = f'string.byte("\\u{{{hex_val}}}")-97'
    if random.random() < 0.4:
        # tambahin math obf
        obf = gen_num_math(n, var_names, damage)
        return f"({base}+{obf}-{gen_num_math(n, var_names, damage)})"
    return base

PYEOF

    # === 3. key_system.py ===
    cat > "$ENGINE_DIR/key_system.py" << 'PYEOF'

import random

def generate_key_system_lua(rand_name_func, salt="XyZ_88_SecretSalt", charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"):
    v_charset = rand_name_func("_charset")
    v_salt = rand_name_func("_salt")
    v_k = rand_name_func("_k")
    v_hash = rand_name_func("_hashSalt")
    v_gen = rand_name_func("_genKey")
    v_verify = rand_name_func("_verify")
    v_seed = rand_name_func("_seed")

    lua = f"""
local {v_charset} = "{charset}"
local {v_salt} = "{salt}"
local {v_k} = 211
local function {v_hash}(s)
    local h=0
    for i=1,#s do
        h=(h*31+string.byte(s,i))%1000000
    end
    return h
end
local function {v_gen}(minute)
    local {v_seed}=minute+{v_hash}({v_salt})
    math.randomseed({v_seed})
    local key=""
    for i=1,12 do
        local idx=math.random(1,#{v_charset})
        key=key..string.sub({v_charset},idx,idx)
    end
    return key
end
local function {v_verify}(input)
    local currentMinute=math.floor(os.time()/60)
    local keyNow={v_gen}(currentMinute)
    local keyPrev={v_gen}(currentMinute-1)
    if input==keyNow or input==keyPrev then
        return true
    end
    return false
end
"""
    return lua, v_verify, v_gen, v_hash

def get_key_for_current_minute(salt="XyZ_88_SecretSalt", charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"):
    import math, random
    def hashSalt(s):
        h=0
        for c in s:
            h=(h*31+ord(c))%1000000
        return h
    def genKey(minute):
        seed=minute+hashSalt(salt)
        random.seed(seed)
        key=""
        for _ in range(12):
            idx=random.randint(0,len(charset)-1)
            key+=charset[idx]
        return key
    import time
    cur = int(time.time()//60)
    return genKey(cur), genKey(cur-1)

PYEOF

    # === 4. trap.py ===
    cat > "$ENGINE_DIR/trap.py" << 'PYEOF'

import random

def generate_trap_lua(rand_name_func, var_names, damage):
    v_lab = rand_name_func("_labyrinth")
    v_x = rand_name_func("_x")
    v_proxy = rand_name_func("_trapMT")
    
    # labyrinth 500k iter - bisa diatur damage biar makin berat
    iter_count = 500000 if damage < 8 else 1000000
    lua = f"""
local function {v_lab}()
    local {v_x}=0
    for i=1,{iter_count} do
        {v_x}=({v_x}+i*31)%1000000
    end
    return {v_x}
end
"""
    return lua, v_lab

def generate_anti_bypass_mt(rand_name_func):
    v_mt = rand_name_func("_mt")
    lua = f"""
local {v_mt}={{
    __index=function(t,k)
        if k=="bypass" or k=="hook" or k=="cheat" then
            error("Anti-bypass trap! Renux Hub Protected")
        end
        return rawget(t,k)
    end
}}
"""
    return lua, v_mt

PYEOF

    # === 5. cff.py ===
    cat > "$ENGINE_DIR/cff.py" << 'PYEOF'

def build_cff_template(blocks_code, state_var, blocks_var, mt_var):
    # blocks_code = dict int -> lua string code (return next_state)
    # returns final CFF loop
    cff = f"""
local {state_var}=1
local {blocks_var}={{}}
"""
    for idx, code in blocks_code.items():
        cff += f"{blocks_var}[{idx}] = function()\n{code}\nend\n"
    
    cff += f"""
setmetatable({blocks_var}, {mt_var})
while true do
    if {state_var}==nil then break end
    local f={blocks_var}[{state_var}]
    if not f then break end
    {state_var}=f()
end
"""
    return cff

PYEOF

    # === 6. builder.py ===
    cat > "$ENGINE_DIR/builder.py" << 'PYEOF'

import sys, os, random, subprocess, tempfile, re
from .encoder import b91encode, html_entity_encode, B91_CHARS
from .math_obf import rand_name, gen_base_vars, gen_num_math, unicode_math_obf, reset
from .key_system import generate_key_system_lua, get_key_for_current_minute
from .trap import generate_trap_lua, generate_anti_bypass_mt
from .cff import build_cff_template

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte, use_space, 
                   use_cff="on", use_key="on", use_labyrinth="on", salt="XyZ_88_SecretSalt"):
    reset()
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    # 1. Encode payload
    html_entity = html_entity_encode(original)
    b91_str = b91encode(html_entity.encode('utf-8'))

    # 2. Base vars
    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name}={var_vals[name]}")

    junk_lines = []
    if damage > 1:
        for _ in range(damage * 2):
            j_name = rand_name("_j")
            b_var = random.choice(var_names)
            k_val = random.randint(2, 20)
            junk_lines.append(f"local {j_name}=math.floor(({b_var}*{gen_num_math(k_val, var_names, damage)})/{gen_num_math(k_val, var_names, damage)})")

    lua_vars_code = "\n".join(lua_vars + junk_lines)

    # 3. B91 chunks dengan obf char
    symbol_exprs = []
    for char in b91_str:
        val = ord(char)
        if char.isalpha() and random.random() < 0.15:
            symbol_exprs.append(f"string.char(0x{val:02X})")
        elif random.random() < 0.35:
            e_dec = gen_num_math(val, var_names, damage)
            symbol_exprs.append(f"string.char({e_dec})")
        else:
            # unicode style
            if random.random() < 0.2:
                symbol_exprs.append(f"string.char({unicode_math_obf(val, var_names, damage)})")
            else:
                symbol_exprs.append(f"string.char({val})")

    num_chunks = max(1, min(damage, len(symbol_exprs)))
    chunk_size = (len(symbol_exprs) + num_chunks - 1) // num_chunks
    chunk_vars = []
    chunk_defs = []
    for i in range(0, len(symbol_exprs), chunk_size):
        group = symbol_exprs[i:i+chunk_size]
        c_var = rand_name("_c")
        chunk_vars.append(c_var)
        chunk_defs.append(f"local {c_var}=table.concat({{{','.join(group)}}})")

    full_b91_var = rand_name("_b91")
    combine_b91 = f"local {full_b91_var}=" + " .. ".join(chunk_vars)

    b91_chars_var = rand_name("_chars")
    b91_chars_lua = B91_CHARS.replace("\\", "\\\\").replace('"', '\\"')
    b91_chars_def = f'local {b91_chars_var}="{b91_chars_lua}"'

    b91_decode_func = rand_name("_dec")
    ent_var = rand_name("_ent")
    code_var = rand_name("_code")

    # 4. Key system + trap
    key_lua, v_verify, v_gen, v_hash = generate_key_system_lua(rand_name, salt)
    trap_lua, v_lab = generate_trap_lua(rand_name, var_names, damage)
    mt_lua, v_mt = generate_anti_bypass_mt(rand_name)

    # 5. B91 decode func
    b91_decode_lua = f"""
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
"""

    # 6. CFF Blocks
    v_state = rand_name("_state")
    v_blocks = rand_name("_blocks")
    v_tries = rand_name("_tries")
    v_max = rand_name("_maxTries")
    v_input = rand_name("_input")

    # Pre-calc current valid keys for builder info
    key_now, key_prev = get_key_for_current_minute(salt)

    block1 = f"""
    -- check executor + labyrinth init
    local execName="Unknown"
    if identifyexecutor then execName=identifyexecutor()
    elseif getexecutorname then execName=getexecutorname() end
    print("Executor: "..tostring(execName).." | Renux Hub Protected")
    {v_lab}()
    return 2
"""

    # unicode math obf check
    block2 = f"""
    local a=string.byte("\\u{{61}}")-97
    local b=string.byte("\\u{{62}}")-97
    local c=string.byte("\\u{{63}}")-97
    local calc=math.floor(math.sqrt((a+b+c+211)*100))
    if calc < 0 then return 5 end
    return 3
"""

    if use_key == "on":
        block3 = f"""
    print("Enter 12-digit timed key (valid 1 min):")
    local {v_input}=_G.RenuxKey or ""
    if {v_input}=="" then
        print("No key provided, set _G.RenuxKey - Current valid: {key_now}")
        return 6
    end
    if {v_verify}({v_input}) then
        print("Key valid!")
        return 4
    else
        {v_tries}={v_tries}+1
        print("Invalid key! Try: "..{v_tries}.."/"..{v_max})
        if {v_tries}>={v_max} then
            return 5
        end
        return 3
    end
"""
    else:
        block3 = "return 4\n"

    block4 = f"""
    -- success, decode and run payload
    {b91_decode_lua}
    {chr(10).join(chunk_defs)}
    {combine_b91}
    local {ent_var}={b91_decode_func}({full_b91_var})
    local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end)
    local _load=loadstring or load
    local _ok,_fn=pcall(_load,{code_var})
    if _ok and _fn then pcall(_fn) end
    return 6
"""

    block5 = f"""
    error("Brute-force detected, Renux trap activated! Labyrinth: "..{v_lab}())
    return 6
"""

    block6 = f"""
    print("Exit - Renux Hub")
    return nil
"""

    # Build CFF if enabled
    if use_cff == "on":
        blocks = {
            1: block1,
            2: block2,
            3: block3,
            4: block4,
            5: block5,
            6: block6
        }
        final_cff = build_cff_template(blocks, v_state, v_blocks, v_mt)
        final_code = f"""
{lua_vars_code}
{key_lua}
{trap_lua}
{mt_lua}
local {v_tries}=0
local {v_max}=3
{final_cff}
"""
    else:
        # tanpa CFF, langsung jalan
        final_code = f"""
{lua_vars_code}
{key_lua}
{trap_lua}
local {v_tries}=0
local {v_max}=3
{chr(10).join(chunk_defs)}
{combine_b91}
{b91_decode_lua}
local {ent_var}={b91_decode_func}({full_b91_var})
local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end)
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
"""

    if oneline == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s+', ' ', final_code)
    if use_space == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s*([=+\-*/%(){}[\],;:])\s*', r'\1', final_code)
        final_code = re.sub(r'\s+', ' ', final_code)
        final_code = final_code.strip()

    if anti_bug == "on":
        for _ in range(3):
            with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False) as tf:
                tf.write(final_code)
            tf_path = tf.name
            try:
                result = subprocess.run(["luac", "-p", tf_path], capture_output=True, text=True, timeout=5)
                os.unlink(tf_path)
                if result.returncode == 0:
                    break
                else:
                    if _ == 2:
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
    
    print(f"KEY_NOW:{key_now}")
    print(f"KEY_PREV:{key_prev}")
    return True

PYEOF

    # === 7. __init__.py ===
    cat > "$ENGINE_DIR/__init__.py" << 'PYEOF'
from .builder import obfuscate_file
PYEOF

    # === 8. engine.py wrapper ===
    cat > "$ENGINE_FILE" << 'PYEOF'
import sys
sys.path.insert(0, "/home/code-interpreter/.obfuscator_engine")
from builder import obfuscate_file
if __name__ == "__main__":
    inp, outp = sys.argv[1], sys.argv[2]
    oneline = sys.argv[3] if len(sys.argv)>3 else "off"
    damage = int(sys.argv[4]) if len(sys.argv)>4 else 5
    anti_bug = sys.argv[5] if len(sys.argv)>5 else "on"
    short_byte = sys.argv[6] if len(sys.argv)>6 else "on"
    use_space = sys.argv[7] if len(sys.argv)>7 else "off"
    use_cff = sys.argv[8] if len(sys.argv)>8 else "on"
    use_key = sys.argv[9] if len(sys.argv)>9 else "on"
    salt = sys.argv[10] if len(sys.argv)>10 else "XyZ_88_SecretSalt"
    ok = obfuscate_file(inp, outp, oneline, damage, anti_bug, short_byte, use_space, use_cff, use_key, "on", salt)
    print("OK" if ok else "FAIL")
    sys.exit(0 if ok else 2)
PYEOF
    chmod +x "$ENGINE_DIR"/*.py "$ENGINE_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ____  _____ _   _ _   ___  __  _   _ _   _ ____    "
    echo " |  _ \| ____| \ | | | | \ \/ / | | | | | | | __ )   "
    echo " | |_) |  _| |  \| | | | |\  /  | |_| | | | |  _ \   "
    echo " |  _ <| |___| |\  | |_| |/  \  |  _  | |_| | |_) |  "
    echo " |_| \_\_____|_| \_|\___//_/\_\ |_| |_|\___/|____/   "
    echo -e "${RESET}"
    echo -e "${WHITE} v10 SINGLE FILE - 6 PY GENERATOR TERPISAH${RESET}"
    echo -e "${YELLOW} encoder | math_obf | key_system | trap | cff | builder${RESET}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "   ${YELLOW}start${RESET}    - create and obfuscate"
    echo -e "   ${YELLOW}setting${RESET}  - settings cff/key/salt"
    echo -e "   ${YELLOW}exit${RESET}     - exit"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -ne "${CYAN}renux > ${RESET}"
}

do_copy() {
    local file="$1"
    [ ! -f "$file" ] && echo -e "${RED}[fail] file not found${RESET}" && return 1
    wc -c < "$file" | awk '{print "size : " $1 " bytes"}'
    if command -v termux-clipboard-set >/dev/null 2>&1; then
        termux-clipboard-set < "$file" && echo -e "${GREEN}[ok] copied${RESET}"
    else
        cp "$file" "/sdcard/Download/" 2>/dev/null && echo -e "${GREEN}[ok] saved Download${RESET}"
    fi
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    init_settings
    init_engine
    echo -e "${CYAN} oneline=$oneline damage=$damage cff=$use_cff key=$use_key salt=$salt${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE" 2>/dev/null
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space" "$use_cff" "$use_key" "$salt"
    [ $? -ne 0 ] || [ ! -f "$tmp_out" ] && echo -e "${RED}[fail] obfuscate failed${RESET}" && return 1
    echo -e "${YELLOW}[*] test syntax...${RESET}"
    if command -v luac >/dev/null 2>&1; then
        luac -p "$tmp_out" && echo -e "${GREEN}[ok] syntax valid${RESET}" || echo -e "${RED}[warn] syntax check fail${RESET}"
    fi
    cat "$tmp_out" > "$RESULT_FILE"
    echo -e "${GREEN}[ok] Renux CFF + Key + Trap done!${RESET}"
    wc -c "$RESULT_FILE"
    while true; do
        echo -e "${CYAN}[1] copy [2] open [3] gen key [4] exit${RESET}"
        echo -ne "${YELLOW}select > ${RESET}"
        read -r choice
        case "$choice" in
            1) do_copy "$RESULT_FILE" ;;
            2) nano "$RESULT_FILE" ;;
            3) python3 -c "
import sys
sys.path.insert(0, '$HOME/.obfuscator_engine')
from key_system import get_key_for_current_minute
k1,k2=get_key_for_current_minute('$salt')
print(f'KEY NOW : {k1}')
print(f'KEY PREV: {k2}')
" ;;
            4|q) break ;;
        esac
    done
    rm -f "$tmp_out"
}

handle_start() {
    rm -f "$PROJECT_FILE"
    echo 'print("hello renux")' > "$PROJECT_FILE"
    nano "$PROJECT_FILE"
    [ ! -s "$PROJECT_FILE" ] && echo -e "${RED}empty${RESET}" && return
    head -n 20 "$PROJECT_FILE"
    echo -ne "${YELLOW}obfuscate now? (y/n): ${RESET}"
    read -r yn
    [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]] && do_obfuscate
}

handle_setting() {
    while true; do
        init_settings
        clear
        show_banner
        echo -e "1. oneline $oneline"
        echo -e "2. damage $damage"
        echo -e "3. use_cff $use_cff"
        echo -e "4. use_key $use_key"
        echo -e "5. salt $salt"
        echo -e "6. back"
        echo -ne "select > "; read -r s
        case "$s" in
            1) echo -ne "oneline on/off > "; read -r v; sed -i "s/^oneline=.*/oneline=$v/" "$SETTINGS_FILE" ;;
            2) echo -ne "damage 1-15 > "; read -r v; sed -i "s/^damage=.*/damage=$v/" "$SETTINGS_FILE" ;;
            3) echo -ne "use_cff on/off > "; read -r v; sed -i "s/^use_cff=.*/use_cff=$v/" "$SETTINGS_FILE" ;;
            4) echo -ne "use_key on/off > "; read -r v; sed -i "s/^use_key=.*/use_key=$v/" "$SETTINGS_FILE" ;;
            5) echo -ne "salt > "; read -r v; sed -i "s/^salt=.*/salt=$v/" "$SETTINGS_FILE" ;;
            6|q) break ;;
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
        start|1) handle_start; echo "press enter..."; read -r ;;
        setting|2) handle_setting ;;
        exit|3|q) echo "bye!"; exit 0 ;;
        *) echo "unknown: $input"; sleep 1 ;;
    esac
done
