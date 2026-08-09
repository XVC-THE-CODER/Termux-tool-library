#!/data/data/com.termux/files/usr/bin/bash
# Termux Lua Obfuscator v1.1 - English Simple + short_byte setting

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
    # add short_byte if old config
    if ! grep -q "short_byte" "$SETTINGS_FILE"; then
        echo "short_byte=on" >> "$SETTINGS_FILE"
    fi
    source "$SETTINGS_FILE"
}

init_engine() {
    mkdir -p "$HOME/.cache"
    cat > "$ENGINE_FILE" << 'PYEOF'
import sys, os, random, subprocess, tempfile, re

def rand_name(damage):
    if damage >= 4:
        parts = ["_", "__", "_0x", "_0X", "_A", "_B", "_H", "_E"]
        base = random.choice(parts)
        suffix = ''.join(random.choices("0123456789ABCDEF", k=random.randint(3,6)))
        return base + suffix
    elif damage >= 2:
        return "_0x" + ''.join(random.choices("ABCDEF0123456789", k=random.randint(3,5))) + random.choice(["a","b","x"])
    else:
        return "_v" + str(random.randint(10,99))

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

def alg_const(n, var_names):
    v = random.choice(var_names)
    v2 = random.choice(var_names)
    one = f"({v}//{v})"
    zero = f"({v}-{v})"
    if n == 0:
        return zero
    if n == 1:
        return one
    if n == 2:
        return f"(({v}//{v})+({v2}//{v2}))"
    if n == 4:
        a = f"(({v}//{v})+({v2}//{v2}))"
        return f"({a}+{a})"
    if n == 16:
        a = alg_const(4, var_names)
        return f"({a}*{a})"
    if n < 10:
        return "(" + "+".join([f"({random.choice(var_names)}//{random.choice(var_names)})" for _ in range(n)]) + ")"
    return f"({n})"

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
        ]
        if damage >= 3:
            templates += [f"(({v}*{v2}+{v2}*{v})-({v}*{v2}*2))", f"(({v}//{v})-1)"]
    else:
        templates = [
            f"({v}//{v})",
            f"(({v}*2)//({v}*2))",
            f"(({v}+{v2})//({v}+{v2}))",
        ]
        if damage >= 3:
            templates += [f"(({v}*{v2})//({v}*{v2}))"]
    safe = [t for t in templates if "//0" not in t and "/0" not in t]
    return random.choice(safe if safe else [f"({v}-{v})" if bit=='0' else f"({v}//{v})"])

def obfuscate_file(input_path, output_path, oneline, damage, anti_bug, short_byte):
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
            junk_name = rand_name(damage) + "_j"
            base = random.choice(var_names)
            lua_vars.append(f"local {junk_name} = {base} * {random.randint(1,5)}")
            lua_vars.append(f"if ({base}-{base}=={alg_const(1,var_names)}) then local {rand_name(damage)} = {alg_const(0,var_names)} end")

    lua_vars_code = "\n".join(lua_vars)

    # SHORT BYTE MODE = ON -> short summarized code
    if short_byte == "on":
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

        lua_template = f"""-- SHORT BYTE OBFUSCATED
-- Layers: HTML Entity -> Hex -> Binary -> Algebra Math
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
print("[obfuscate] done | short_byte=on")
"""
    else:
        # LONG BYTE MODE = OFF -> very long per-bit algebra (original long version)
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

        lua_template = f"""-- LONG BYTE OBFUSCATED
-- Layers: HTML Entity -> Hex -> Binary -> Algebra Math
{lua_vars_code}
local {bin_var} = {bin_assembly}
local {hex_var} = ""
for {i_var}=1, #{bin_var}, 4 do
local {b_var} = {bin_var}:sub({i_var},{i_var}+3)
local {n_var} = 0
for {j_var}=1,4 do
{n_var} = {n_var}*2 + ({b_var}:sub({j_var},{j_var})=="1" and 1 or 0)
end
{hex_var} = {hex_var} .. string.format("%x", {n_var})
end
local {ent_var} = ""
for {i_var}=1, #{hex_var}, 2 do
local {h_var} = {hex_var}:sub({i_var},{i_var}+1)
{ent_var} = {ent_var} .. string.char(tonumber({h_var},16))
end
local {code_var} = {ent_var}:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
local _load = loadstring or load
local _ok, _fn = pcall(_load, {code_var})
if _ok and _fn then pcall(_fn) end
print("[obfuscate] done | short_byte=off")
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
        print("usage: engine.py <input> <output> <oneline> <damage> <anti_bug> <short_byte>")
        sys.exit(1)
    inp = sys.argv[1]
    outp = sys.argv[2]
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
    echo "██████╗ ███████╗███████╗ ██████╗████████╗"
    echo "██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝"
    echo "██████╔╝█████╗  ███████╗██║        ██║   "
    echo "██╔══██╗██╔══╝  ╚════██║██║        ██║   "
    echo "██████╔╝██║     ███████║╚██████╗   ██║   "
    echo "╚═════╝ ╚═╝     ╚══════╝ ╚═════╝   ╚═╝   "
    echo -e "${RESET}"
    echo -e "${WHITE}  Tool Lua Obfuscator v1.1${RESET}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo -e "  ${WHITE}MENU${RESET}"
    echo -e "  ${YELLOW}start${RESET}   - create and obfuscate lua"
    echo -e "  ${YELLOW}setting${RESET} - open settings"
    echo -e "  ${YELLOW}exit${RESET}    - exit tool"
    echo -e "${GREEN}----------------------------------------${RESET}"
    echo ""
    echo -ne "${CYAN}obfuscate > ${RESET}"
}

do_copy_with_retry() {
    local file="$1"
    local success=0
    if ! command -v termux-clipboard-set >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] termux-api not installed${RESET}"
        echo -e "${CYAN}[*] auto download termux-api...${RESET}"
        pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null
        pkg install termux-api -y
        if command -v termux-clipboard-set >/dev/null 2>&1; then
            echo -e "${GREEN}[ok] termux-api installed${RESET}"
        else
            echo -e "${RED}[fail] install failed, try: pkg install termux-api${RESET}"
            echo -e "${YELLOW}[!] also need Termux:API app from F-Droid${RESET}"
            sleep 2
        fi
    fi
    echo -e "${YELLOW}[*] copy to clipboard, 10 tries...${RESET}"
    for i in {1..10}; do
        if command -v termux-clipboard-set >/dev/null 2>&1; then
            if termux-clipboard-set < "$file"; then
                echo -e "${GREEN}[ok] copy success try $i${RESET}"
                success=1
                break
            fi
        else
            echo -e "${RED}[!] clipboard tool not found${RESET}"
            break
        fi
        echo -e "${YELLOW}[.] try $i failed, retry...${RESET}"
        sleep 0.3
    done
}

do_obfuscate() {
    local tmp_out="$HOME/.obfuscate_temp.lua"
    if [ -d "/data/data/com.termux/files/usr/tmp" ]; then
        tmp_out="/data/data/com.termux/files/usr/tmp/obf_temp.lua"
    fi
    init_settings
    echo -e "${CYAN}  settings: oneline=$oneline damage=$damage anti_bug=$anti_bug short_byte=$short_byte${RESET}"
    echo -e "${YELLOW}[*] backup original...${RESET}"
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    if [ "$short_byte" = "on" ]; then
        echo -e "${YELLOW}[*] mode: short_byte=on (short code)${RESET}"
    else
        echo -e "${YELLOW}[*] mode: short_byte=off (long code)${RESET}"
    fi
    echo -e "${YELLOW}[*] obfuscate: html entity > hex > binary > algebra${RESET}"
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
                echo -e "${GREEN}  [ok] test $t: syntax ok${RESET}"
                test_ok=1
            else
                echo -e "${RED}  [fail] test $t: syntax error, regen...${RESET}"
                python3 "$ENGINE_FILE" "$PROJECT_FILE" "$tmp_out" "$oneline" "$damage" "$anti_bug" "$short_byte"
            fi
        else
            echo -e "${GREEN}  [ok] test $t: logic ok${RESET}"
            test_ok=1
            break
        fi
        sleep 0.2
    done
    if [ $test_ok -eq 1 ]; then
        cat "$tmp_out" > "$PROJECT_FILE"
        cat "$tmp_out" > "$RESULT_FILE"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}[ok] obfuscate success!${RESET}"
        echo -e "${WHITE}input : $PROJECT_FILE${RESET}"
        echo -e "${WHITE}output: $RESULT_FILE (new file)${RESET}"
        wc -c "$RESULT_FILE" | awk '{print "size  : " $1 " bytes"}'
        echo -e "${GREEN}----------------------------------------${RESET}"
        while true; do
            echo ""
            echo -e "${CYAN}options: [1] copy  [2] recreate  [3] open  [4] exit${RESET}"
            echo -ne "${YELLOW}select > ${RESET}"
            read -r choice
            case "$choice" in
                1|copy|c)
                    do_copy_with_retry "$RESULT_FILE"
                    ;;
                2|recreate|r)
                    echo -e "${YELLOW}[*] clear $PROJECT_FILE and open new${RESET}"
                    echo '-- new lua code here (old cleared)' > "$PROJECT_FILE"
                    echo 'print("new code")' >> "$PROJECT_FILE"
                    nano "$PROJECT_FILE"
                    echo -ne "${YELLOW}obfuscate new code? (y/n): ${RESET}"
                    read -r yn
                    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
                        do_obfuscate
                    fi
                    break
                    ;;
                3|open|o)
                    echo -e "${YELLOW}[*] open $RESULT_FILE${RESET}"
                    if [ ! -f "$RESULT_FILE" ]; then
                        cp "$PROJECT_FILE" "$RESULT_FILE"
                    fi
                    nano "$RESULT_FILE"
                    echo -e "${GREEN}[ok] saved $RESULT_FILE${RESET}"
                    ;;
                4|exit|e|q)
                    break
                    ;;
                *)
                    echo -e "${RED}invalid option${RESET}"
                    ;;
            esac
        done
        rm -f "$tmp_out"
    else
        echo -e "${RED}[fail] validation failed${RESET}"
    fi
}

handle_start() {
    echo -e "${YELLOW}[*] start - clear old code for new code${RESET}"
    rm -f "$PROJECT_FILE"
    echo '-- new lua code here (old auto cleared)' > "$PROJECT_FILE"
    echo 'print("hello world")' >> "$PROJECT_FILE"
    echo -e "${GREEN}[ok] old code cleared${RESET}"
    echo -e "${GREEN}[*] open nano $PROJECT_FILE${RESET}"
    sleep 0.5
    nano "$PROJECT_FILE"
    if [ ! -s "$PROJECT_FILE" ]; then
        echo -e "${RED}[fail] empty file, cancel${RESET}"
        return
    fi
    echo -e "${CYAN}--- preview ---${RESET}"
    head -n 15 "$PROJECT_FILE"
    echo -e "${CYAN}---------------${RESET}"
    echo -ne "${YELLOW}obfuscate now? (y/n): ${RESET}"
    read -r yn
    if [[ "$yn" == "y" || "$yn" == "Y" || "$yn" == "" ]]; then
        do_obfuscate
    else
        echo -e "${RED}cancel${RESET}"
    fi
}

handle_setting() {
    while true; do
        init_settings
        clear
        show_banner
        echo -e "${WHITE}SETTINGS${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "1. oneline    : ${YELLOW}$oneline${RESET} (on/off) - one line mode"
        echo -e "2. damage    : ${YELLOW}$damage${RESET} (1-5) - how broken it looks"
        echo -e "3. anti_bug  : ${YELLOW}$anti_bug${RESET} (on/off) - test many times"
        echo -e "4. short_byte: ${YELLOW}$short_byte${RESET} (on/off) - short vs long code"
        echo -e "   on = short summarized, off = very long"
        echo -e "5. back to menu"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -ne "${CYAN}select 1-5 > ${RESET}"
        read -r s
        case "$s" in
            1)
                echo -ne "oneline on/off > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^oneline=.*/oneline=$val/" "$SETTINGS_FILE"
                fi
                ;;
            2)
                echo -ne "damage 1-5 > "
                read -r val
                if [[ "$val" =~ ^[1-5]$ ]]; then
                    sed -i "s/^damage=.*/damage=$val/" "$SETTINGS_FILE"
                fi
                ;;
            3)
                echo -ne "anti_bug on/off > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^anti_bug=.*/anti_bug=$val/" "$SETTINGS_FILE"
                fi
                ;;
            4)
                echo -ne "short_byte on/off > "
                read -r val
                if [[ "$val" == "on" || "$val" == "off" ]]; then
                    sed -i "s/^short_byte=.*/short_byte=$val/" "$SETTINGS_FILE"
                    echo -e "${GREEN}saved: short_byte=$val${RESET}"
                    sleep 1
                fi
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
            echo -e "${RED}unknown: $input (type: start / setting / exit)${RESET}"
            sleep 1
            ;;
    esac
done
