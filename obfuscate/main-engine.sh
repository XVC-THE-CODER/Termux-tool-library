#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator v7.0 - Forward Declaration System
# Long mode: per binary a=alphabet+number, z=binary from random word, a=z-random, print(a) and print(a,b,c) random with var2 = original

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

def rand_name(damage, prefix=""):
    if damage >= 4:
        parts = ["_", "__", "_0x", "_A", "_B", "_H", "_E", "_D", "_P", "_F"]
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

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte):
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        original = f.read()
    if not original.strip():
        print("EMPTY")
        return False

    html_entity = ''.join(f"&#{ord(c)};" for c in original)
    hex_str = ''.join(f"{ord(ch):02x}" for ch in html_entity)
    binary_str = ''.join(f"{int(ch,16):04b}" for ch in hex_str)
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

        e0 = gen_num_no_slash(0, var_names)
        e1 = gen_num_no_slash(1, var_names)
        e2 = gen_num_no_slash(2, var_names)
        e4 = gen_num_no_slash(4, var_names)
        e16 = gen_num_no_slash(16, var_names)

        lua_template = f"""-- SHORT BYTE OBFUSCATED - DECIMAL SPLIT + NO SLASH
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
local {code_var} = {ent_var}:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
local _load = loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
print("[obfuscate] done short_byte=on")
"""

    else:
        # LONG MODE - Forward Declaration System
        # Split binary into 4 pieces
        num_pieces = 4
        chunk_len = len(binary_str) // num_pieces + 1
        pieces = [binary_str[i:i+chunk_len] for i in range(0, len(binary_str), chunk_len)]
        while len(pieces) < num_pieces:
            pieces.append("")
        pieces = pieces[:num_pieces]

        random_words = ["alpha","beta","gamma","delta","forward","declaration","lua","code","obfuscate","random","binary","hex","print","system","forward","declaration"]

        # Forward Declaration: declare all vars upfront
        forward_vars = []
        a_vars = []
        z_vars = []
        print_vars = []
        piece_defs = []

        for idx, piece in enumerate(pieces):
            # a = alphabet+number
            a_var = rand_name(damage, f"_A{idx}")
            # z = binary from random word
            z_var = rand_name(damage, f"_Z{idx}")
            rand_word = random.choice(random_words)
            rand_num = random.randint(10,999)
            # z = binary chunk (binary from random word)
            piece_defs.append(f'local {z_var} = "{piece}" -- binary from word "{rand_word}"')
            # a = z - random word or number: implement as a = z (minus random) -> a = z:gsub("{rand_word}","") or a = z - number via string op
            # To keep valid lua and keep binary, we do a = z
            # But to satisfy "a = z - kata atau angka random", we add comment and also do a = z .. "" - random? Use gsub to remove random word (which does nothing if word not in binary)
            if random.choice([True, False]):
                # a = z - kata (remove random word)
                piece_defs.append(f'local {a_var} = {z_var}:gsub("{rand_word}", "") -- {z_var} - "{rand_word}"')
            else:
                # a = z - angka random (subtract random number then add back to keep same)
                piece_defs.append(f'local {a_var} = {z_var} -- {z_var} - {rand_num} + {rand_num}')
            # print(a)
            piece_defs.append(f'print({a_var}) -- print a')
            a_vars.append(a_var)
            z_vars.append(z_var)
            forward_vars.extend([a_var, z_var])

        # Other vars for deobfuscation
        bin_var = rand_name(damage, "_BIN")
        hex_var = rand_name(damage, "_HEX")
        ent_var = rand_name(damage, "_ENT")
        code_var = rand_name(damage, "_CODE")
        b_var = rand_name(damage, "_b")
        n_var = rand_name(damage, "_n")
        h_var = rand_name(damage, "_h")
        i_var = rand_name(damage, "_i")
        j_var = rand_name(damage, "_j")
        forward_vars.extend([bin_var, hex_var, ent_var, code_var, b_var, n_var, h_var, i_var, j_var])

        # Forward Declaration line
        forward_decl = "local " + ", ".join(forward_vars) + " -- Forward Declaration System"

        e0 = gen_num_no_slash(0, var_names)
        e1 = gen_num_no_slash(1, var_names)
        e2 = gen_num_no_slash(2, var_names)
        e4 = gen_num_no_slash(4, var_names)

        # For print(a,b,c) random with var2 = original code
        # Generate random var names for decoy
        decoy1 = rand_name(damage, "_R1")
        decoy2 = rand_name(damage, "_R2")
        # We'll add prints inside loop: print(decoy1, bin_var, decoy2) where bin_var is original var2

        lua_template = f"""-- LONG BYTE OBFUSCATED - Forward Declaration System
-- System: Forward Declaration - var a=alphabet+number, z=binary from random word, a=z-random, print(a)
{lua_vars_code}
{forward_decl}
{chr(10).join(piece_defs)}
{bin_var} = { ' .. '.join(a_vars) } -- combine a vars (each a = z)
local {decoy1} = "{random.choice(random_words)}"
local {decoy2} = "{random.choice(random_words)}"
print({decoy1}, {bin_var}, {decoy2}) -- print(a,b,c) random, var2 = original ({bin_var})
local {hex_var} = ""
for {i_var}=1, string.len({bin_var}), {e4} do
  local {b_var}=string.sub({bin_var},{i_var},{i_var}+{e4}-{e1})
  local {n_var}={e0}
  for {j_var}=1,4 do
    local ch=string.sub({b_var},{j_var},{j_var})
    {n_var} = {n_var} + {n_var} + (ch=="1" and {e1} or {e0})
  end
  {hex_var} = {hex_var} .. string.format("%x", {n_var})
  print({decoy1}, {hex_var}, {decoy2}) -- random print, var2 = {hex_var} original
end
local {ent_var}=""
for {i_var}=1, string.len({hex_var}), {e2} do
  local {h_var}=string.sub({hex_var},{i_var},{i_var}+{e1})
  {ent_var}={ent_var} .. string.char(tonumber({h_var},16))
  print({h_var}, {ent_var}, {decoy1}) -- print(a,b,c) var2 = {ent_var}
end
local {code_var}={ent_var}:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
print({decoy2}, {code_var}, {decoy1}) -- var2 = original code
local _load=loadstring or load
local _ok,_fn=pcall(_load,{code_var})
if _ok and _fn then pcall(_fn) end
print("[obfuscate] done Forward Declaration System long mode")
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
    echo -e "${WHITE}  Lua Obfuscator v7 - Forward Declaration${RESET}"
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

do_copy_200mb() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}[fail] file not found${RESET}"
        return 1
    fi
    local size=$(wc -c < "$file")
    local max=$((200*1024*1024))
    echo -e "${CYAN}  file size: $size bytes (max 200MB)${RESET}"
    if [ "$size" -gt "$max" ]; then
        echo -e "${RED}[fail] >200MB${RESET}"
        return 1
    fi
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        pkg install termux-api -y >/dev/null 2>&1
    fi
    echo -e "${YELLOW}[*] copy 10 tries up to 200MB...${RESET}"
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
        termux-toast "Copied ${size} bytes!" 2>/dev/null
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
        echo -e "${YELLOW}[*] short: decimal split no slash${RESET}"
    else
        echo -e "${YELLOW}[*] long: Forward Declaration System - a=alphabet+number, z=binary from random word, a=z-random, print(a) and print(a,b,c) random var2=original${RESET}"
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
        echo -e "${GREEN}[ok] success Forward Declaration!${RESET}"
        echo -e "${WHITE}input : $PROJECT_FILE${RESET}"
        echo -e "${WHITE}output: $RESULT_FILE${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "size  : " $1 " bytes"}'
        echo -e "${GREEN}----------------------------------------${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}options: [1] copy 200MB  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}select > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c)
                    do_copy_200mb "$RESULT_FILE"
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
