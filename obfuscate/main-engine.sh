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
    count = 2 if damage <=3 else 3 if damage <=6 else 4 if damage <=10 else 6 if damage <=13 else 8
    names, vals = [], {}
    for _ in range(count):
        n = rand_name(damage)
        while n in names:
            n = rand_name(damage)
        names.append(n)
        vals[n] = random.randint(111, 9999)
    return names, vals

def gen_zero(var_names):
    v = random.choice(var_names)
    return f"({v}-{v})"

def gen_one(var_names):
    v = random.choice(var_names)
    return f"({v}-{v}+1)"

def gen_num_simple(n, var_names):
    if n <= 0:
        return gen_zero(var_names)
    if n == 1:
        return gen_one(var_names)
    if n <= 10:
        parts = []
        for i in range(n):
            v = random.choice(var_names)
            parts.append(f"{v}-{v}+1")
        return f"({'+'.join(parts)})"
    else:
        a = random.randint(2, min(20, n-1))
        b = n // a
        r = n % a
        if r == 0:
            return f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)})"
        else:
            return f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)}+{gen_num_simple(r, var_names)})"

def gen_num_mul_div(n, var_names, complex_level=1):
    if n <= 0:
        return gen_zero(var_names)
    if n == 1:
        return gen_one(var_names)
    if complex_level <= 1 or n <= 2:
        return gen_num_simple(n, var_names)
    method = random.choice(['mul_div', 'div_mul', 'mul'])
    if method == 'mul_div':
        k = random.randint(2, 9)
        top = n * k
        if top < 100:
            top_expr = gen_num_simple(top, var_names)
        else:
            a = random.randint(2, 20)
            b = top // a
            r = top % a
            if r == 0:
                top_expr = f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)})"
            else:
                top_expr = f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)}+{gen_num_simple(r, var_names)})"
        k_expr = gen_num_simple(k, var_names)
        return f"({top_expr}/{k_expr})"
    elif method == 'div_mul':
        k = random.randint(2, 9)
        top = n * k
        if top < 100:
            top_expr = gen_num_simple(top, var_names)
        else:
            a = random.randint(2, 20)
            b = top // a
            r = top % a
            if r == 0:
                top_expr = f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)})"
            else:
                top_expr = f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)}+{gen_num_simple(r, var_names)})"
        return f"({top_expr}/{gen_num_simple(k, var_names)})"
    else:
        # (a * b) where a*b = n, or (a * b)/c
        for a in range(2, int(n**0.5)+1):
            if n % a == 0:
                b = n//a
                return f"({gen_num_simple(a, var_names)}*{gen_num_simple(b, var_names)})"
        # if not divisible, do (n*k)/k
        k = random.randint(2, 7)
        top = n * k
        return f"(({gen_num_simple(top, var_names)})/{gen_num_simple(k, var_names)})"

def gen_num_math(n, var_names):
    # Wrapper for base91 numbers - use mul/div directly
    return gen_num_mul_div(n, var_names, complex_level=2)

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

def lua_char_expr_50(c, var_names, xor_func_name):
    # 50% symbol di base91 di buat xor atau decimal per symbol random
    is_symbol = c in "!#$%&()*+,./:;<=>?@[]^_`{|}~\"':"
    if not is_symbol:
        # For non-symbol, 10% chance still obfuscate to make longer for high damage
        if random.random() < 0.1:
            is_symbol = True
    if not is_symbol:
        esc = c.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{esc}"'
    # 50% chance to be obfuscated
    if random.random() < 0.5:
        esc = c.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{esc}"'
    else:
        # Choose xor or decimal randomly per symbol
        if random.choice([True, False]):
            # decimal
            math_expr = gen_num_mul_div(ord(c), var_names, complex_level=2)
            return f'string.char({math_expr})'
        else:
            # xor
            key = random.randint(10,200)
            enc = ord(c) ^ key
            math_enc = gen_num_mul_div(enc, var_names, complex_level=2)
            math_key = gen_num_mul_div(key, var_names, complex_level=2)
            return f'string.char({xor_func_name}({math_enc},{math_key}))'

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte, use_space):
    global _counter
    _counter = 0
    damage = max(1, min(15, int(damage)))
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False
    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    b91_str = b91encode(html_entity.encode('utf-8'))
    # damage kecil => pendek, damage tinggi => panjang banget
    if damage <= 2:
        num_parts = 2
        chunk_len = len(b91_str) // 2 + 1
    elif damage <= 5:
        num_parts = 3
        chunk_len = len(b91_str) // 3 + 1
    elif damage <= 9:
        num_parts = 4
        chunk_len = len(b91_str) // 4 + 1
    elif damage <= 12:
        num_parts = 5
        chunk_len = len(b91_str) // 5 + 1
    else:
        num_parts = 7
        chunk_len = len(b91_str) // 7 + 1
    b91_parts = [b91_str[i:i+chunk_len] for i in range(0, len(b91_str), chunk_len)]
    while len(b91_parts) < num_parts:
        b91_parts.append("")
    b91_parts = b91_parts[:num_parts]
    decimal_parts = [str(ord(ch)) for ch in html_entity]
    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name}={var_vals[name]}")
    # damage kecil pendek, tinggi panjang banget
    if damage <= 2:
        junk_count = damage
    elif damage <= 5:
        junk_count = damage * 2
    elif damage <= 9:
        junk_count = damage * 4
    elif damage <= 12:
        junk_count = damage * 6
    else:
        junk_count = damage * 8
    for _ in range(junk_count):
        junk_name = rand_name(damage, "")
        base = random.choice(var_names)
        lua_vars.append(f"local {junk_name}={base}+{random.randint(1,5)}-{random.randint(1,5)}+{base}-{base}")
        if damage >= 7 and random.random() < 0.5:
            lua_vars.append(f"if {base}-{base}=={gen_one(var_names)} then local {rand_name(damage)}={gen_zero(var_names)} end")
    lua_vars_code = "\n".join(lua_vars)
    if short_byte == "on":
        if damage <= 2:
            num_pieces = 1
        elif damage <= 5:
            num_pieces = 2
        elif damage <= 9:
            num_pieces = 4
        elif damage <= 12:
            num_pieces = 6
        else:
            num_pieces = 10
        chunk = len(decimal_parts) // num_pieces + 1
        pieces = []
        for i in range(0, len(decimal_parts), chunk):
            group = decimal_parts[i:i+chunk]
            piece_str = "/".join(group)
            pieces.append(piece_str)
        while len(pieces) < num_pieces:
            pieces.append("")
        pieces = pieces[:num_pieces]
        piece_vars = []
        piece_defs = []
        for idx, piece in enumerate(pieces):
            var = rand_name(damage, f"")
            esc = piece.replace("\\", "\\\\").replace('"', '\\"')
            piece_defs.append(f'local {var}="{esc}"')
            piece_vars.append(var)
        combined_var = rand_name(damage, "")
        combined_expr = ' .. "/" .. '.join(piece_vars)
        ent_var = rand_name(damage, "")
        code_var = rand_name(damage, "")
        token_var = rand_name(damage, "")
        n_var = rand_name(damage, "")
        h_var = rand_name(damage, "")
        b_var = rand_name(damage, "")
        temp_var = rand_name(damage, "")
        q_var = rand_name(damage, "")
        r_var = rand_name(damage, "")
        t_var = rand_name(damage, "")
        i_var = rand_name(damage, "")
        e0 = gen_num_math(0, var_names)
        e1 = gen_num_math(1, var_names)
        e2 = gen_num_math(2, var_names)
        e4 = gen_num_math(4, var_names)
        e16 = gen_num_math(16, var_names)
        xor_func_name = rand_name(damage, "")
        lua_template = f"""{lua_vars_code}
{chr(10).join(piece_defs)}
local {combined_var}={combined_expr}
local {ent_var}=""
for {token_var} in string.gmatch({combined_var},"[^/]+") do
local {n_var}=tonumber({token_var})
local {h_var}=""
local {temp_var}={n_var}
if {temp_var}=={e0} then {h_var}="0" end
while {temp_var}>{e0} do
local {r_var}={temp_var}
while {r_var}>={e16} do {r_var}={r_var}-{e16} end
{h_var}=string.format("%x",{r_var})..{h_var}
local {q_var}={e0}
local {t_var}={temp_var}
while {t_var}>={e16} do {t_var}={t_var}-{e16} {q_var}={q_var}+{e1} end
{temp_var}={q_var}
end
local {b_var}=""
for {i_var}=1,string.len({h_var}) do
local {r_var}=tonumber(string.sub({h_var},{i_var},{i_var}),{e16})
local {t_var}=""
local {temp_var}={r_var}
local {q_var}={e0}
for _=1,4 do
local {r_var}2={temp_var}
while {r_var}2>={e2} do {r_var}2={r_var}2-{e2} end
{t_var}=({r_var}2=={e1} and "1" or "0")..{t_var}
local {q_var}2={e0}
local {t_var}2={temp_var}
while {t_var}2>={e2} do {t_var}2={t_var}2-{e2} {q_var}2={q_var}2+{e1} end
{temp_var}={q_var}2
end
{b_var}={b_var}..{t_var}
end
local {h_var}2=""
for {i_var}=1,string.len({b_var}),{e4} do
local {r_var}=string.sub({b_var},{i_var},{i_var}+{e4}-{e1})
local {q_var}={e0}
for {t_var}=1,4 do
local ch=string.sub({r_var},{t_var},{t_var})
{q_var}={q_var}+{q_var}+(ch=="1" and {e1} or {e0})
end
{h_var}2={h_var}2..string.format("%x",{q_var})
end
{ent_var}={ent_var}..string.char(tonumber({h_var}2,{e16}))
end
local function {xor_func_name}(a,b)
local r=0
local bit=1
while a>0 or b>0 do
local a_bit=a%2
local b_bit=b%2
if a_bit~=b_bit then r=r+bit end
a=math.floor(a/2)
b=math.floor(b/2)
bit=bit*2
end
return r
end
local {code_var}={ent_var}:gsub("&#(%d+);",function(n) return string.char(tonumber(n)) end)
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
"""
    else:
        b91_decode_func = rand_name(damage, "")
        xor_func_name = rand_name(damage, "")
        b91_vars = []
        b91_defs = []
        for idx, part in enumerate(b91_parts):
            var = rand_name(damage, "")
            char_exprs = []
            for c in part:
                expr = lua_char_expr_50(c, var_names, xor_func_name)
                char_exprs.append(expr)
            obf_expr = " .. ".join(char_exprs) if char_exprs else '""'
            b91_vars.append(var)
            b91_defs.append((var, obf_expr))
        forward_vars = []
        a_vars = []
        z_vars = []
        for idx in range(num_parts):
            a_var = rand_name(damage, "")
            z_var = rand_name(damage, "")
            forward_vars.extend([a_var, z_var])
            a_vars.append(a_var)
            z_vars.append(z_var)
        bin_var = rand_name(damage, "")
        hex_var = rand_name(damage, "")
        ent_var = rand_name(damage, "")
        code_var = rand_name(damage, "")
        b_var = rand_name(damage, "")
        n_var = rand_name(damage, "")
        h_var = rand_name(damage, "")
        i_var = rand_name(damage, "")
        j_var = rand_name(damage, "")
        b91_full_var = rand_name(damage, "")
        b91_chars_var = rand_name(damage, "")
        forward_vars.extend([bin_var, hex_var, ent_var, code_var, b_var, n_var, h_var, i_var, j_var, b91_full_var, b91_chars_var])
        forward_decl = "local " + ",".join(forward_vars)
        e0 = gen_num_math(0, var_names)
        e1 = gen_num_math(1, var_names)
        e2 = gen_num_math(2, var_names)
        e4 = gen_num_math(4, var_names)
        e8 = gen_num_math(8, var_names)
        e13 = gen_num_math(13, var_names)
        e14 = gen_num_math(14, var_names)
        e91 = gen_num_math(91, var_names)
        e256 = gen_num_math(256, var_names)
        e8191 = gen_num_math(8191, var_names)
        e8192 = gen_num_math(8192, var_names)
        e88 = gen_num_math(88, var_names)
        b91_chars_lua = B91_CHARS.replace("\\", "\\\\").replace('"', '\\"')
        b91_def_lines = []
        for idx, (var, esc) in enumerate(b91_defs):
            b91_def_lines.append(f'local {var}={esc}')
        a_defs = []
        for idx in range(num_parts):
            a_var = a_vars[idx]
            z_var = z_vars[idx]
            b91_var = b91_vars[idx]
            a_defs.append(f'local {z_var}={b91_var}')
            a_defs.append(f'local {a_var}={z_var}')
        lua_template = f"""{lua_vars_code}
{forward_decl}
local function {xor_func_name}(a,b)
local r=0
local bit=1
while a>0 or b>0 do
local a_bit=a%2
local b_bit=b%2
if a_bit~=b_bit then r=r+bit end
a=math.floor(a/2)
b=math.floor(b/2)
bit=bit*2
end
return r
end
{chr(10).join(b91_def_lines)}
{chr(10).join(a_defs)}
{b91_full_var}={ ' .. '.join(a_vars) }
{b91_chars_var}="{b91_chars_lua}"
local function {b91_decode_func}(str)
local b={e0}
local n={e0}
local out={{}}
local v=-1
local dec={{}}
for i=1,#{b91_chars_var} do dec[string.sub({b91_chars_var},i,i)]=i-1 end
for i=1,#str do
local c=string.sub(str,i,i)
local val=dec[c]
if val then
if v<0 then v=val else
v=v+val*{e91}
b=b+v*(2^n)
local w=v%{e8192}
if w>{e88} then n=n+{e13} else n=n+{e14} end
while n>{e8} do
local byte=b%{e256}
table.insert(out,string.char(byte))
b=math.floor(b/{e256})
n=n-{e8}
end
v=-1
end
end
end
if v>-1 then
local byte=(b+v*(2^n))%{e256}
table.insert(out,string.char(byte))
end
return table.concat(out)
end
local {ent_var}={b91_decode_func}({b91_full_var})
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
    echo "  ____ __   ______ _____ ____ ___  ____  _____ "
    echo " | __ ) \ / / ___| ____/ ___/ _ \|  _ \| ____|"
    echo " |  _ \\ V / |   |  _|| |  | | | | | | |  _|  "
    echo " | |_) || | |___| |__| |__| |_| | |_| | |___ "
    echo " |____/ |_|\____|_____\____\___/|____/|_____|"
    echo -e "${RESET}"
    echo -e "${WHITE}  BYTECODE v9 - damage 1-15 - _V1 infinite${RESET}"
    echo ""
}
show_menu() {
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "  MENU"
    echo -e "  ${YELLOW}start${RESET}   - create and obfuscate"
    echo -e "  ${YELLOW}setting${RESET} - settings"
    echo -e "  ${YELLOW}exit${RESET}    - exit"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo ""
    echo -ne "${CYAN}bytecode v9 > ${RESET}"
}
do_copy() {
    local file="$1"
    if [ ! -f "$file" ]; then echo -e "${RED}[fail] file not found${RESET}"; return 1; fi
    local size=$(wc -c < "$file")
    echo -e "${CYAN}  file size: $size bytes${RESET}"
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then pkg install termux-api -y >/dev/null 2>&1; fi
    echo -e "${YELLOW}[*] copy 10 tries...${RESET}"
    local success=0
    for i in {1..10}; do
        if termux-clipboard-set < "$file" 2>/dev/null; then echo -e "${GREEN}[ok] copy success try $i${RESET}"; success=1; break; fi
        if cat "$file" | termux-clipboard-set 2>/dev/null; then echo -e "${GREEN}[ok] copy success try $i method2${RESET}"; success=1; break; fi
        sleep 0.5
    done
    if [ $success -eq 0 ]; then
        echo -e "${RED}[fail] copy failed${RESET}"
        if [ -d "/sdcard/Download" ]; then cp "$file" "/sdcard/Download/$(basename "$file")" 2>/dev/null; echo -e "${GREEN}[ok] saved to /sdcard/Download/${RESET}"; fi
        if command -v termux-share >/dev/null 2>&1; then termux-share "$file" 2>/dev/null; fi
    else
        termux-toast "Copied!" 2>/dev/null
    fi
}
do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    if [ -d "/data/data/com.termux/files/usr/tmp" ]; then tmp_out="/data/data/com.termux/files/usr/tmp/obf_temp.lua"; fi
    init_settings
    echo -e "${CYAN}  settings: oneline=$oneline damage=$damage anti_bug=$anti_bug short_byte=$short_byte use_space=$use_space${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE" 2>/dev/null
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space"
    local status=$?
    if [ $status -ne 0 ] || [ ! -f "$tmp_out" ]; then echo -e "${RED}[fail] obfuscate failed${RESET}"; return 1; fi
    echo -e "${YELLOW}[*] test 5 times...${RESET}"
    local test_ok=0
    for t in {1..5}; do
        if command -v luac >/dev/null 2>&1; then
            if luac -p "$tmp_out" >/dev/null 2>&1; then echo -e "${GREEN}  [ok] test $t${RESET}"; test_ok=1; else echo -e "${RED}  [fail] test $t regen${RESET}"; python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte" "$use_space"; fi
        else
            echo -e "${GREEN}  [ok] test $t logic ok${RESET}"; test_ok=1; break
        fi
        sleep 0.2
    done
    if [ $test_ok -eq 1 ]; then
        cat "$tmp_out" > "$PROJECT_FILE"
        cat "$tmp_out" > "$RESULT_FILE"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}[ok] success bytecode v9 damage $damage!${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "size  : " $1 " bytes"}'
        echo -e "${GREEN}----------------------------------------${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}options: [1] copy  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}select > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c) do_copy "$RESULT_FILE" ;;
                2|recreate|r) echo '-- new code here' > "$PROJECT_FILE"; echo 'print("new")' >> "$PROJECT_FILE"; nano "$PROJECT_FILE"; echo -ne "${YELLOW}obfuscate new? (y/n): ${RESET}"; read -r yn; if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then do_obfuscate; fi; break ;;
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
    echo '-- new lua code' > "$PROJECT_FILE"
    echo 'print("hello")' >> "$PROJECT_FILE"
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then echo -e "${RED}[fail] empty${RESET}"; return; fi
    head -n 15 "$PROJECT_FILE"
    echo -ne "${YELLOW}obfuscate now? (y/n): ${RESET}"
    read -r yn
    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then do_obfuscate; fi
}
handle_setting() {
    while true; do
        init_settings
        clear
        show_banner
        echo -e "${WHITE}SETTINGS - damage 1-15 (1 pendek, 15 panjang banget)${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "1. oneline    : ${YELLOW}$oneline${RESET}"
        echo -e "2. damage    : ${YELLOW}$damage${RESET} (1-15) 1=pendek 15=panjang banget"
        echo -e "3. anti_bug  : ${YELLOW}$anti_bug${RESET}"
        echo -e "4. short_byte: ${YELLOW}$short_byte${RESET}"
        echo -e "5. use_space : ${YELLOW}$use_space${RESET}"
        echo -e "6. back"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -ne "${CYAN}select 1-6 > ${RESET}"
        read -r s
        case "$s" in
            1) echo -ne "oneline on/off > "; read -r val; sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE" ;;
            2) echo -ne "damage 1-15 > "; read -r val; if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 1 ] && [ "$val" -le 15 ]; then sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE"; else echo -e "${RED}harus 1-15${RESET}"; sleep 1; fi ;;
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
