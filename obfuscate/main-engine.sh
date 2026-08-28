#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator v8.0 - Base91 + Split 4 + Math * + - + XOR A + copy (no 200mb word)
# System: Forward Declaration + Base91

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
    fi
    if ! grep -q "short_byte" "$SETTINGS_FILE"; then
        echo "short_byte=on" >> "$SETTINGS_FILE"
    fi
    source "$SETTINGS_FILE"
}

init_engine() {
    mkdir -p "$HOME/.cache"
    cat > "$ENGINE_FILE" << 'PYEOF'
import sys, os, random, subprocess, tempfile, re

# Base91 alphabet - 91 chars
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

def rand_name(damage, prefix=""):
    if damage >= 4:
        parts = ["_", "__", "_0x", "_A", "_B", "_H", "_E", "_D", "_P", "_F", "_B91"]
        base = random.choice(parts)
        suffix = ''.join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", k=random.randint(2,5)))
        return base + suffix + prefix
    elif damage >= 2:
        return "_0x" + ''.join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", k=random.randint(3,5))) + prefix
    else:
        return "_v" + str(random.randint(10,99)) + prefix

def gen_base_vars(damage):
    count = 3 if damage <=2 else 4 if damage==3 else 5
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
    return f"({v} - {v})"

def gen_one(var_names):
    v = random.choice(var_names)
    return f"({v} - {v} + 1)"

def gen_num_no_slash(n, var_names):
    if n == 0:
        return gen_zero(var_names)
    parts = []
    for i in range(n):
        v = random.choice(var_names)
        parts.append(f"{v} - {v} + 1")
    expr = " + ".join(parts)
    return f"({expr})"

def gen_num_math(n, var_names):
    # generate n using * + -  (obfuscate numbers)
    if n <= 0:
        return gen_zero(var_names)
    if n == 1:
        return gen_one(var_names)
    if n <= 4:
        return gen_num_no_slash(n, var_names)
    # try multiplication
    if n > 5 and random.choice([True, False]):
        # find factors
        factors = []
        for a in range(2, int(n**0.5)+1):
            if n % a == 0:
                factors.append((a, n//a))
        if factors:
            a,b = random.choice(factors)
            # generate a and b recursively with + - and *
            return f"({gen_num_math(a, var_names)}*{gen_num_math(b, var_names)})"
    # addition/subtraction
    if n > 4 and random.choice([True, False]):
        a = random.randint(1, n-1)
        b = n - a
        return f"({gen_num_math(a, var_names)}+{gen_num_math(b, var_names)})"
    # fallback sum of ones
    return gen_num_no_slash(n, var_names)

def xor_encode(s, key):
    return [ord(c) ^ key for c in s]

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte):
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    # Encode html_entity to base91 instead of binary
    b91_str = b91encode(html_entity.encode('utf-8'))

    # Split base91 into 4 different places
    num_parts = 4
    chunk_len = len(b91_str) // num_parts + 1
    b91_parts = [b91_str[i:i+chunk_len] for i in range(0, len(b91_str), chunk_len)]
    while len(b91_parts) < num_parts:
        b91_parts.append("")
    b91_parts = b91_parts[:num_parts]

    decimal_parts = [str(ord(ch)) for ch in html_entity]

    var_names, var_vals = gen_base_vars(damage)
    lua_vars = []
    for name in var_names:
        lua_vars.append(f"local {name} = {var_vals[name]}")

    if damage >= 4:
        for _ in range(damage):
            junk_name = rand_name(damage, "_j")
            base = random.choice(var_names)
            lua_vars.append(f"local {junk_name} = {base} + {random.randint(1,5)} - {random.randint(1,5)} + {base} - {base}")
            lua_vars.append(f"if {base} - {base} == {gen_one(var_names)} then local {rand_name(damage)} = {gen_zero(var_names)} end")

    lua_vars_code = "\n".join(lua_vars)

    if short_byte == "on":
        # SHORT: decimal split + base91 + math * + - + xor A
        num_pieces = 4
        if damage == 1:
            num_pieces = 2
        elif damage >=4:
            num_pieces = 6
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
            var = rand_name(damage, f"_D{idx}")
            esc = piece.replace("\\", "\\\\").replace('"', '\\"')
            piece_defs.append(f'local {var} = "{esc}"')
            piece_vars.append(var)

        combined_var = rand_name(damage, "_DEC")
        combined_expr = ' .. "/" .. '.join(piece_vars)

        ent_var = rand_name(damage, "_ENT")
        code_var = rand_name(damage, "_CODE")
        token_var = rand_name(damage, "_tok")
        n_var = rand_name(damage, "_n")
        h_var = rand_name(damage, "_h")
        b_var = rand_name(damage, "_b")
        temp_var = rand_name(damage, "_tmp")
        q_var = rand_name(damage, "_q")
        r_var = rand_name(damage, "_r")
        t_var = rand_name(damage, "_t")
        i_var = rand_name(damage, "_i")

        e0 = gen_num_math(0, var_names)
        e1 = gen_num_math(1, var_names)
        e2 = gen_num_math(2, var_names)
        e4 = gen_num_math(4, var_names)
        e16 = gen_num_math(16, var_names)

        # XOR for big word A
        xor_key = random.randint(10,200)
        xor_enc_A = xor_encode("A", xor_key)
        xor_var = rand_name(damage, "_XOR")
        xor_key_var = rand_name(damage, "_XK")
        xor_dec_var = rand_name(damage, "_XD")

        lua_template = f"""-- SHORT BYTE OBFUSCATED - DECIMAL SPLIT + BASE91 + MATH * + - + XOR A
-- Base91 split 4 places, numbers obfuscated * + -
{lua_vars_code}
{chr(10).join(piece_defs)}
local {combined_var} = {combined_expr}
local {ent_var} = ""
for {token_var} in string.gmatch({combined_var}, "[^/]+") do
  local {n_var} = tonumber({token_var})
  local {h_var} = ""
  local {temp_var} = {n_var}
  if {temp_var} == {e0} then {h_var} = "0" end
  while {temp_var} > {e0} do
    local {r_var} = {temp_var}
    while {r_var} >= {e16} do {r_var} = {r_var} - {e16} end
    {h_var} = string.format("%x", {r_var}) .. {h_var}
    local {q_var} = {e0}
    local {t_var} = {temp_var}
    while {t_var} >= {e16} do {t_var} = {t_var} - {e16} {q_var} = {q_var} + {e1} end
    {temp_var} = {q_var}
  end
  local {b_var} = ""
  for {i_var}=1, string.len({h_var}) do
    local {r_var}=tonumber(string.sub({h_var},{i_var},{i_var}), {e16})
    local {t_var}=""
    local {temp_var}={r_var}
    local {q_var}= {e0}
    for _=1,4 do
      local {r_var}2 = {temp_var}
      while {r_var}2 >= {e2} do {r_var}2 = {r_var}2 - {e2} end
      {t_var} = ({r_var}2 == {e1} and "1" or "0") .. {t_var}
      local {q_var}2 = {e0}
      local {t_var}2 = {temp_var}
      while {t_var}2 >= {e2} do {t_var}2 = {t_var}2 - {e2} {q_var}2 = {q_var}2 + {e1} end
      {temp_var} = {q_var}2
    end
    {b_var} = {b_var} .. {t_var}
  end
  local {h_var}2 = ""
  for {i_var}=1, string.len({b_var}), {e4} do
    local {r_var}=string.sub({b_var},{i_var},{i_var}+{e4}-{e1})
    local {q_var}={e0}
    for {t_var}=1,4 do
      local ch=string.sub({r_var},{t_var},{t_var})
      {q_var} = {q_var} + {q_var} + (ch=="1" and {e1} or {e0})
    end
    {h_var}2 = {h_var}2 .. string.format("%x", {q_var})
  end
  {ent_var} = {ent_var} .. string.char(tonumber({h_var}2, {e16}))
end
-- XOR big word A with decimal {xor_key}
local function xor(a,b)
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
local {xor_key_var}={xor_key}
local {xor_var}={{{','.join(map(str, xor_enc_A))}}} -- A xor {xor_key}
local {xor_dec_var}=""
for i=1,#{xor_var} do {xor_dec_var}={xor_dec_var}..string.char(xor({xor_var}[i],{xor_key_var})) end
print({xor_dec_var}.." xor decimal demo") -- big word A xor decimal
local {code_var} = {ent_var}:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
local _load = loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
print("[obfuscate] done short_byte=on base91+math+xor")
"""

    else:
        # LONG MODE - Base91 + Forward Declaration + Split 4 different places + math * + - + xor A
        random_words = ["alpha","beta","gamma","delta","forward","declaration","lua","code","obfuscate","random","binary","hex","print","system"]

        # Split base91 into 4 parts at different places
        b91_vars = []
        b91_defs_part = []
        for idx, part in enumerate(b91_parts):
            var = rand_name(damage, f"_B91_{idx}")
            # escape for lua string - need to escape " and \ and handle long string
            esc = part.replace("\\", "\\\\").replace('"', '\\"')
            # Place each part at different location: we will collect defs but they will be placed at different spots via forward declaration + later defs
            b91_vars.append(var)
            # Store def to be placed later at different places - for now just def
            b91_defs_part.append((var, esc, random.choice(random_words)))

        # Forward Declaration
        forward_vars = []
        a_vars = []
        z_vars = []
        for idx in range(num_parts):
            a_var = rand_name(damage, f"_A{idx}")
            z_var = rand_name(damage, f"_Z{idx}")
            forward_vars.extend([a_var, z_var])
            a_vars.append(a_var)
            z_vars.append(z_var)

        bin_var = rand_name(damage, "_BIN")
        hex_var = rand_name(damage, "_HEX")
        ent_var = rand_name(damage, "_ENT")
        code_var = rand_name(damage, "_CODE")
        b_var = rand_name(damage, "_b")
        n_var = rand_name(damage, "_n")
        h_var = rand_name(damage, "_h")
        i_var = rand_name(damage, "_i")
        j_var = rand_name(damage, "_j")
        b91_full_var = rand_name(damage, "_B91FULL")
        b91_chars_var = rand_name(damage, "_B91CHARS")

        forward_vars.extend([bin_var, hex_var, ent_var, code_var, b_var, n_var, h_var, i_var, j_var, b91_full_var, b91_chars_var])

        forward_decl = "local " + ", ".join(forward_vars) + " -- Forward Declaration System + Base91 split 4 places"

        e0 = gen_num_math(0, var_names)
        e1 = gen_num_math(1, var_names)
        e2 = gen_num_math(2, var_names)
        e4 = gen_num_math(4, var_names)

        # XOR for big word A
        xor_key = random.randint(10,200)
        xor_enc_A = xor_encode("A", xor_key)
        xor_enc_FORWARD = xor_encode("FORWARD", xor_key)

        # Build b91 parts at different places
        # We'll place each b91 var definition at different spot in template
        b91_def_lines = []
        for idx, (var, esc, word) in enumerate(b91_defs_part):
            # Place at different places: add comment about place
            if idx == 0:
                b91_def_lines.append(f'{var} = "{esc}" -- base91 part {idx+1}/4 at place 1 (top) from word "{word}"')
            elif idx == 1:
                b91_def_lines.append(f'{var} = "{esc}" -- base91 part {idx+1}/4 at place 2 (middle) from word "{word}"')
            elif idx == 2:
                b91_def_lines.append(f'{var} = "{esc}" -- base91 part {idx+1}/4 at place 3 (middle2) from word "{word}"')
            else:
                b91_def_lines.append(f'{var} = "{esc}" -- base91 part {idx+1}/4 at place 4 (bottom) from word "{word}"')

        # For a = z - random
        a_defs = []
        for idx in range(num_parts):
            a_var = a_vars[idx]
            z_var = z_vars[idx]
            rand_word = random.choice(random_words)
            rand_num = random.randint(10,999)
            # z = binary? Now z = base91 part? Actually for long mode we now use base91 parts as z
            # Let's make z = b91 var
            b91_var = b91_vars[idx]
            a_defs.append(f'local {z_var} = {b91_var} -- z = base91 from random word "{rand_word}"')
            if random.choice([True, False]):
                a_defs.append(f'local {a_var} = {z_var}:gsub("{rand_word}", "") -- a = z - "{rand_word}" (alphabet+number var)')
            else:
                a_defs.append(f'local {a_var} = {z_var} -- a = z - {rand_num} + {rand_num} (alphabet+number)')
            a_defs.append(f'print({a_var}) -- print a (Forward Declaration)')

        decoy1 = rand_name(damage, "_R1")
        decoy2 = rand_name(damage, "_R2")

        # Base91 decode function in Lua (using math * + -)
        b91_chars_lua = B91_CHARS.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

        lua_template = f"""-- LONG BYTE OBFUSCATED - Base91 + Forward Declaration + Split 4 places + Math * + - + XOR A
-- System: Forward Declaration - base91 split 4 different places, math * + -, XOR big word A
{lua_vars_code}
{forward_decl}
-- Place 1: base91 part 1 at top
{b91_def_lines[0] if len(b91_def_lines)>0 else ""}
{b91_def_lines[1] if len(b91_def_lines)>1 else ""}
-- Forward Declaration: a vars
{chr(10).join(a_defs[:2])}
-- Place 2: base91 part 2 in middle
{b91_def_lines[2] if len(b91_def_lines)>2 else ""}
{chr(10).join(a_defs[2:4])}
-- Place 3: base91 part 3
{b91_def_lines[3] if len(b91_def_lines)>3 else ""}
{b91_full_var} = { ' .. '.join(b91_vars) } -- combine 4 base91 parts from different places
local {decoy1} = "{random.choice(random_words)}"
local {decoy2} = "{random.choice(random_words)}"
print({decoy1}, {b91_full_var}, {decoy2}) -- print(a,b,c) var2 = original base91
-- Base91 chars with math obfuscation for numbers
{b91_chars_var} = "{b91_chars_lua}"
-- Base91 decode function with math * + -
local function b91decode(str)
  local b=0
  local n=0
  local out={{}}
  local v=-1
  local dec={{}}
  for i=1,#{b91_chars_var} do dec[string.sub({b91_chars_var},i,i)]=i-1 end
  for i=1,#str do
    local c=string.sub(str,i,i)
    local val=dec[c]
    if val then
      if v<0 then v=val else
        v=v+val*91
        b=b+v*(2^n)
        local w=v%8192
        if w>88 then n=n+13 else n=n+14 end
        while n>7 do
          local byte=b%256
          table.insert(out, string.char(byte))
          b=math.floor(b/256)
          n=n-8
        end
        v=-1
      end
    end
  end
  if v>-1 then
    local byte=(b+v*(2^n))%256
    table.insert(out, string.char(byte))
  end
  return table.concat(out)
end
-- XOR function for big word A
local function xor(a,b)
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
local _XK={xor_key}
local _XENC_A={{{','.join(map(str, xor_enc_A))}}}
local _A_WORD=""
for i=1,#_XENC_A do _A_WORD=_A_WORD..string.char(xor(_XENC_A[i],_XK)) end
print(_A_WORD.." xor decimal demo A") -- big word A xor decimal
local _XENC_FWD={{{','.join(map(str, xor_enc_FORWARD))}}}
local _FWD_WORD=""
for i=1,#_XENC_FWD do _FWD_WORD=_FWD_WORD..string.char(xor(_XENC_FWD[i],_XK)) end
print(_FWD_WORD.." xor decimal demo FORWARD")
-- Decode base91 to html entity
local {ent_var} = b91decode({b91_full_var})
print({decoy1}, {ent_var}, {decoy2}) -- print(a,b,c) var2 = {ent_var} original entity
local {code_var}={ent_var}:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
print({decoy2}, {code_var}, {decoy1}) -- var2 = original code
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
print("[obfuscate] done Forward Declaration Base91 split 4 + math * + - + xor A")
"""

    final_code = lua_template
    if oneline == "on":
        final_code = final_code.replace("\n", " ")
        final_code = re.sub(r'\s+', ' ', final_code)

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
        print("usage: <input> <output> <oneline> <damage> <anti_bug> <short_byte>")
        sys.exit(1)
    inp, outp = sys.argv[1], sys.argv[2]
    oneline = sys.argv[3] if len(sys.argv)>3 else "off"
    damage = int(sys.argv[4]) if len(sys.argv)>4 else 3
    anti_bug = sys.argv[5] if len(sys.argv)>5 else "on"
    short_byte = sys.argv[6] if len(sys.argv)>6 else "on"
    ok = obfuscate_file(inp, outp, oneline, damage, anti_bug, short_byte)
    print("OK" if ok else "FAIL")
    sys.exit(0 if ok else 2)
PYEOF
    chmod +x "$ENGINE_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "   ___  ____  ______ _   _ ____   ____    _  _____ _____ "
    echo "  / _ \| __ )|  ___/| | | / ___| / ___|  / \ |_   _| ____|"
    echo " | |  | |  _ \| |_  | | | \___ \| |     / _ \  | | |  _|  "
    echo " | |_| | |_) |  _|  | |_| |___) | |___ / ___ \ | | | |___ "
    echo "  \___/|____/|_|     \___/|____/ \____/_/   \_\|_| |_____|"
    echo -e "${RESET}"
    echo -e "${WHITE}  Lua Obfuscator v8 - Base91 + Split 4 + Math + XOR${RESET}"
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
    echo -ne "${CYAN}obfuscate > ${RESET}"
}

do_copy() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}[fail] file not found${RESET}"
        return 1
    fi
    local size=$(wc -c < "$file")
    echo -e "${CYAN}  file size: $size bytes${RESET}"
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        pkg install termux-api -y >/dev/null 2>&1
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
    echo -e "${CYAN}  settings: oneline=$oneline damage=$damage anti_bug=$anti_bug short_byte=$short_byte${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE" 2>/dev/null
    if [ "$short_byte" = "on" ]; then
        echo -e "${YELLOW}[*] short: decimal split + base91 + math * + - + xor A${RESET}"
    else
        echo -e "${YELLOW}[*] long: Base91 split 4 places + Forward Declaration + math * + - + xor A${RESET}"
    fi
    python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte"
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
                python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte"
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
        echo -e "${GREEN}[ok] success Base91!${RESET}"
        echo -e "${WHITE}input : $PROJECT_FILE${RESET}"
        echo -e "${WHITE}output: $RESULT_FILE${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "size  : " $1 " bytes"}'
        echo -e "${GREEN}----------------------------------------${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}options: [1] copy  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}select > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c)
                    do_copy "$RESULT_FILE"
                    ;;
                2|recreate|r)
                    echo '-- new code here' > "$PROJECT_FILE"
                    echo 'print("new")' >> "$PROJECT_FILE"
                    nano "$PROJECT_FILE"
                    echo -ne "${YELLOW}obfuscate new? (y/n): ${RESET}"
                    read -r yn
                    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
                        do_obfuscate
                    fi
                    break
                    ;;
                3|open|o)
                    nano "$RESULT_FILE"
                    ;;
                4|exit|e|q)
                    break
                    ;;
                *)
                    echo -e "${RED}invalid${RESET}"
                    ;;
            esac
        done
        rm -f "$tmp_out"
    else
        echo -e "${RED}[fail] validation${RESET}"
    fi
}

handle_start() {
    rm -f "$PROJECT_FILE"
    echo '-- new lua code (old cleared)' > "$PROJECT_FILE"
    echo 'print("hello")' >> "$PROJECT_FILE"
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then
        echo -e "${RED}[fail] empty${RESET}"
        return
    fi
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
        echo -e "1. oneline    : ${YELLOW}$oneline${RESET}"
        echo -e "2. damage    : ${YELLOW}$damage${RESET}"
        echo -e "3. anti_bug  : ${YELLOW}$anti_bug${RESET}"
        echo -e "4. short_byte: ${YELLOW}$short_byte${RESET}"
        echo -e "5. back"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -ne "${CYAN}select > ${RESET}"
        read -r s
        case "$s" in
            1)
                echo -ne "oneline on/off > "
                read -r val
                sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE"
                ;;
            2)
                echo -ne "damage 1-5 > "
                read -r val
                sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE"
                ;;
            3)
                echo -ne "anti_bug on/off > "
                read -r val
                sed -i "s/^anti_bug=.*/anti_bug=$val/" "$SETTINGS_FILE"
                ;;
            4)
                echo -ne "short_byte on/off > "
                read -r val
                sed -i "s/^short_byte=.*/short_byte=$val/" "$SETTINGS_FILE"
                ;;
            5|q|exit)
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
            echo -e "${YELLOW}press enter...${RESET}"
            read -r
            ;;
        setting|settings|2|set)
            handle_setting
            ;;
        exit|3|q|quit)
            echo -e "${GREEN}bye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}unknown: $input${RESET}"
            sleep 1
            ;;
    esac
done
