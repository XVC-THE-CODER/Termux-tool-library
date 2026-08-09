#!/bin/bash
R='\033[91m'
G='\033[92m'
Y='\033[93m'
B='\033[94m'
M='\033[95m'
C='\033[96m'
W='\033[97m'
D='\033[90m'
BOLD='\033[1m'
END='\033[0m'
declare -A VARS
VARS[ans]=0
HIST=()
LAST_EXPR=""
LANG_SET="id"
MODE="pecahan"
banner(){
clear
echo -e "${C}${BOLD}"
cat <<'EOF'
██╗   ██╗  ██████╗
██║   ██║ ██╔════╝
██║   ██║ ██║     
██║   ██║ ██║     
╚██╗ ██╔╝ ██║     
 ╚████╔╝  ╚██████╗
  ╚═══╝    ╚═════╝
EOF
echo -e "${D}  Ultra Calculator by the creator tool${END}"
echo -e "${D}  v11 | + - * : / % ² √ sin cos tan log | Way | Question | Mode${END}"
echo ""
}
t(){
local key="$1"
if [[ "$LANG_SET" == "en" ]]; then
case "$key" in
prompt) echo "UC> " ;;
help_hint) echo "Type 'help' for help, 'way <expr>' for steps, 'question' quiz, 'mode' fraction/round" ;;
help) echo -e "
${Y}${BOLD}OPERATORS:${END}
  ${G}+${END} add ${G}-${END} sub ${G}*${END} mul ${G}:${END} div ${G}/${END} per ${G}%${END} percent
  ${G}² ³ ^ √ ! sin cos tan log ln exp${END} case insensitive
${Y}${BOLD}MODES:${END}
  ${G}mode${END} -> choose 1 bulatan / 2 pecahan
  ${G}mode pecahan${END} / fraction -> 1/2 stays 1/2
  ${G}mode bulatan${END} / round -> 1/2 = 0.5
${Y}${BOLD}COMMANDS:${END}
  help, vars, history, clear, lang, mode, exit
  ${G}way <expr>${END} -> steps
  ${G}question${END} -> quiz easy/medium/hard/extreme/ultimate
" ;;
bye) echo "Bye!" ;;
invalid) echo "Invalid expression" ;;
var_title) echo "-- VARIABLES --" ;;
hist_title) echo "-- HISTORY --" ;;
saved) echo "[saved]" ;;
way_usage) echo "Usage: way <expression>" ;;
orig) echo "Original" ;;
norm) echo "Normalized" ;;
subst) echo "Substitution" ;;
step) echo "Step" ;;
final) echo "Final result" ;;
eq_orig) echo "Original equation" ;;
eq_group) echo "Group terms" ;;
eq_div) echo "Divide" ;;
eq_res) echo "Result" ;;
way_title) echo "WAY" ;;
no_solution) echo "No solution" ;;
bagi_label) echo "[divide]" ;;
per_label) echo "[per]" ;;
need_bc) echo "Need bc: pkg install bc" ;;
mode_title) echo "Current mode" ;;
mode_changed) echo "Mode changed to" ;;
mode_choose) echo "Choose mode:" ;;
var_multi) echo "Error: only 1 algebra variable allowed" ;;
q_choose) echo "Choose difficulty:" ;;
q_easy) echo "Easy" ;;
q_med) echo "Medium" ;;
q_hard) echo "Hard" ;;
q_ext) echo "Extreme" ;;
q_ult) echo "Ultimate" ;;
q_ask) echo "Question" ;;
q_correct) echo "Correct!" ;;
q_wrong) echo "Wrong! Answer is" ;;
esac
else
case "$key" in
prompt) echo "UC> " ;;
help_hint) echo "Ketik 'help' bantuan, 'way <rumus>' cara, 'question' kuis, 'mode' pilih 1 bulatan 2 pecahan" ;;
help) echo -e "
${Y}${BOLD}OPERATOR:${END}
  ${G}+${END} tambah ${G}-${END} kurang ${G}*${END} kali ${G}:${END} bagi ${G}/${END} per ${G}%${END} persen
  ${G}² ³ ^ √ ! sin cos tan${END} case insensitive: Sin tetap sin
${Y}${BOLD}MODE:${END}
  Ketik ${G}mode${END} -> nanti pilih 1 bulatan atau 2 pecahan
  Bisa pakai angka atau nama: 1, 2, bulatan, pecahan, round, fraction
  ${G}mode pecahan${END} -> 1/2 tetap 1/2 (2/4=1/2)
  ${G}mode bulatan${END} -> 1/2 = 0.5
${Y}${BOLD}PERINTAH:${END}
  help, vars, history, clear, lang, mode, exit
  ${G}way <rumus>${END} -> cara
  ${G}question${END} -> kuis acak
" ;;
bye) echo "Bye! Makasih!" ;;
invalid) echo "Ekspresi tidak valid" ;;
var_title) echo "-- VARIABEL --" ;;
hist_title) echo "-- RIWAYAT --" ;;
saved) echo "[disimpan]" ;;
way_usage) echo "Pakai: way <rumus>" ;;
orig) echo "Awal" ;;
norm) echo "Normalisasi" ;;
subst) echo "Substitusi" ;;
step) echo "Langkah" ;;
final) echo "Hasil akhir" ;;
eq_orig) echo "Persamaan awal" ;;
eq_group) echo "Kelompokkan" ;;
eq_div) echo "Bagi" ;;
eq_res) echo "Hasil" ;;
way_title) echo "WAY" ;;
no_solution) echo "Tidak ada solusi" ;;
bagi_label) echo "[bagi]" ;;
per_label) echo "[per]" ;;
need_bc) echo "Butuh bc: pkg install bc" ;;
mode_title) echo "Mode saat ini" ;;
mode_changed) echo "Mode diganti ke" ;;
mode_choose) echo "Pilih mode:" ;;
var_multi) echo "Error: hanya 1 variabel aljabar diperbolehkan" ;;
q_choose) echo "Pilih tingkat kesulitan:" ;;
q_easy) echo "Easy" ;;
q_med) echo "Medium" ;;
q_hard) echo "Hard" ;;
q_ext) echo "Extreme" ;;
q_ult) echo "Ultimate" ;;
q_ask) echo "Soal" ;;
q_correct) echo "Benar!" ;;
q_wrong) echo "Salah! Jawabannya" ;;
esac
fi
}
check_bc(){
if ! command -v bc >/dev/null 2>&1; then echo -e "${R}$(t need_bc)${END}"; exit 1; fi
}
count_vars(){
local e="$1"
local lower=$(echo "$e" | tr '[:upper:]' '[:lower:]')
lower=$(echo "$lower" | sed -E 's/sin|cos|tan|log|ln|exp|sqrt|fact//g')
local count=$(echo "$lower" | grep -oE '[a-z]' | sort -u | wc -l)
echo "$count"
}
normalize_expr(){
local e="$1"
e=$(echo "$e" | tr '[:upper:]' '[:lower:]')
e=$(echo "$e" | sed -e 's/²/^2/g' -e 's/³/^3/g' -e 's/⁴/^4/g' -e 's/⁵/^5/g' -e 's/⁶/^6/g' -e 's/⁷/^7/g' -e 's/⁸/^8/g' -e 's/⁹/^9/g' -e 's/⁰/^0/g' -e 's/¹/^1/g')
e=$(echo "$e" | sed -e 's/×/*/g' -e 's/÷/:/g' -e 's/π/3.1415926535/g')
e=$(echo "$e" | sed 's/√/sqrt/g')
e=$(echo "$e" | sed -E 's/sqrt([0-9]+)/sqrt(\1)/g')
e=$(echo "$e" | sed -E 's#([0-9.]+)%#( \1/100 )#g')
e=$(echo "$e" | sed -E 's#sin\(([0-9.]+)\)#s(\1*3.1415926535/180)#g')
e=$(echo "$e" | sed -E 's#cos\(([0-9.]+)\)#c(\1*3.1415926535/180)#g')
e=$(echo "$e" | sed -E 's#tan\(([0-9.]+)\)#s(\1*3.1415926535/180)/c(\1*3.1415926535/180)#g')
e=$(echo "$e" | sed -E 's#sin\(([^)]+)\)#s((\1)*3.1415926535/180)#g')
e=$(echo "$e" | sed -E 's#cos\(([^)]+)\)#c((\1)*3.1415926535/180)#g')
e=$(echo "$e" | sed -E 's#log\(([^)]+)\)#l(\1)/l(10)#g')
e=$(echo "$e" | sed -E 's#ln\(([^)]+)\)#l(\1)#g')
e=$(echo "$e" | sed -E 's#exp\(([^)]+)\)#e(\1)#g')
e=$(echo "$e" | sed -E 's#([0-9]+)!#fact(\1)#g')
e=$(echo "$e" | sed 's#:#/#g')
echo "$e"
}
add_implicit_mul(){
local e="$1"
e=$(echo "$e" | sed -E 's/([0-9])([a-z_])/\1*\2/g')
e=$(echo "$e" | sed -E 's/([0-9])\(/\1*\(/g')
e=$(echo "$e" | sed -E 's/\)\(/\)*\(/g')
e=$(echo "$e" | sed -E 's/\)([a-z0-9_])/\)*\1/g')
echo "$e"
}
replace_vars(){
local e="$1"
for k in "${!VARS[@]}"; do
e=$(echo "$e" | sed "s#\\<$k\\>#(${VARS[$k]})#g")
done
echo "$e"
}
eval_numeric_full(){
local raw="$1"
local e=$(normalize_expr "$raw")
e=$(add_implicit_mul "$e")
e=$(replace_vars "$e")
local bcdef="scale=10; define fact(n){if(n<=1)return(1);return(n*fact(n-1))};"
local res=$(echo "$bcdef $e" | bc -l 2>/dev/null)
echo "$res|$e"
}
eval_at(){
local expr="$1"; local var="$2"; local val="$3"
local e=$(normalize_expr "$expr")
e=$(add_implicit_mul "$e")
e=$(echo "$e" | sed "s#\\<$var\\>#($val)#g")
for k in "${!VARS[@]}"; do
if [[ "$k" != "$var" ]]; then
e=$(echo "$e" | sed "s#\\<$k\\>#(${VARS[$k]})#g")
fi
done
echo "scale=10; define fact(n){if(n<=1)return(1);return(n*fact(n-1))}; $e" | bc -l 2>/dev/null
}
to_frac(){
awk -v d="$1" '
function gcd(a,b){a=int(a<0?-a:a); b=int(b<0?-b:b); while(b){t=b; b=a%b; a=t} return a}
BEGIN{sign=""; if(d<0){sign="-"; d=-d} best_num=0; best_den=1; best_err=1e9; for(den=1; den<=1000; den++){num=int(d*den+0.5); err=num/den-d; if(err<0) err=-err; if(err<best_err){best_err=err; best_num=num; best_den=den; if(err<1e-9) break}} g=gcd(best_num,best_den); best_num/=g; best_den/=g; if(best_den==1) printf "%s%d", sign, best_num; else printf "%s%d/%d", sign, best_num, best_den}'
}
simplify_algebra(){
local expr="$1"; local var="$2"
echo "$expr" | awk -v v="$var" '{gsub(/ /,"",$0); gsub("\\*"v, v); gsub(v"\\*", v); gsub(/-/, "+-", $0); n=split($0, t, "+"); coeff=0; const=0; for(i=1;i<=n;i++){term=t[i]; if(term=="") continue; if(index(term, v)>0){c=term; sub(v,"",c); sub(/\*$/,"",c); if(c==""||c=="+") c=1; else if(c=="-") c=-1; coeff+=c} else if(term!="") const+=term} out=""; if(coeff!=0){if(coeff==1) out=v; else if(coeff==-1) out="-"v; else {if(coeff==int(coeff)) out=int(coeff) v; else out=coeff v}} if(const!=0){if(const>0){if(out!="") out=out"+"const; else out=const} else out=out const} if(out=="") out="0"; print out}'
}
way_numeric(){
local raw="$1"
local cur_norm=$(normalize_expr "$raw")
local cur_imp=$(add_implicit_mul "$cur_norm")
local cur_vars=$(replace_vars "$cur_imp")
echo -e "${Y}--- $(t way_title): $raw ---${END}"
echo -e "${W}$(t orig):${END} $raw"
if [[ "$cur_norm" != "$raw" ]]; then echo -e "${D}$(t norm): $cur_norm${END}"; fi
if [[ "$cur_vars" != "$cur_imp" ]]; then echo -e "${D}$(t subst): $cur_imp -> $cur_vars${END}"; fi
local cur="$cur_vars"
local step=1
for _ in $(seq 1 50); do
if [[ "$cur" =~ ^-?[0-9.]+$ ]]; then break; fi
if [[ "$cur" =~ sqrt\([^()]+\) ]]; then match=$(echo "$cur" | grep -oE 'sqrt\([^()]+\)' | head -n1); inner=$(echo "$match" | sed -E 's/sqrt\((.*)\)/\1/'); val=$(echo "scale=10; sqrt($inner)" | bc -l 2>/dev/null); [[ -z "$val" ]] && break; val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $match = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
if [[ "$cur" =~ \([^()]+\) ]]; then match=$(echo "$cur" | grep -oE '\([^()]+\)' | head -n1); inner=$(echo "$match" | tr -d '()'); val=$(echo "scale=10; define fact(n){if(n<=1)return(1);return(n*fact(n-1))}; $inner" | bc -l 2>/dev/null); [[ -z "$val" ]] && break; val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $match = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
if echo "$cur" | grep -qE '[0-9.]+\^[0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\^[0-9.]+' | head -n1); l=$(echo "$match" | cut -d'^' -f1); r=$(echo "$match" | cut -d'^' -f2); val=$(echo "scale=10; $l ^ $r" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $l ^ $r = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
if echo "$cur" | grep -qE '[0-9.]+[*/][0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\s*[*/]\s*[0-9.]+' | head -n1); clean=$(echo "$match" | tr -d ' '); op=$(echo "$clean" | grep -oE '[*/]'); l=$(echo "$clean" | awk -F'[*/]' '{print $1}'); r=$(echo "$clean" | awk -F'[*/]' '{print $2}'); val=$(echo "scale=10; $l $op $r" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $clean = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
if echo "$cur" | grep -qE '[0-9.]+[+\-][0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\s*[+\-]\s*[0-9.]+' | head -n1); clean=$(echo "$match" | tr -d ' '); val=$(echo "scale=10; $clean" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $clean = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
break
done
final=$(echo "$cur" | awk '{printf "%g", $1}')
echo -e "${Y}${BOLD}$(t final): $final${END}"
}
way_equation(){
local raw="$1"; local left=$(echo "$raw" | cut -d'=' -f1); local right=$(echo "$raw" | cut -d'=' -f2-); local var=$(echo "$raw" | grep -o -E '[a-zA-Z]' | head -n1); [[ -z "$var" ]] && var="x"
echo -e "${Y}--- $(t way_title): $raw ---${END}"; echo -e "${W}$(t eq_orig):${END} $left = $right"
local l_const=$(eval_at "$left" "$var" 0); local l_one=$(eval_at "$left" "$var" 1); local r_const=$(eval_at "$right" "$var" 0); local r_one=$(eval_at "$right" "$var" 1)
local l_coeff=$(echo "$l_one - $l_const" | bc -l); local r_coeff=$(echo "$r_one - $r_const" | bc -l)
local l_coeff_f=$(echo "$l_coeff" | awk '{printf "%g", $1}'); local l_const_f=$(echo "$l_const" | awk '{printf "%g", $1}'); local r_coeff_f=$(echo "$r_coeff" | awk '{printf "%g", $1}'); local r_const_f=$(echo "$r_const" | awk '{printf "%g", $1}')
echo -e "${G}$(t step) 1:${END} ${l_coeff_f}$var + $l_const_f = ${r_coeff_f}$var + $r_const_f"
local a=$(echo "$l_coeff - $r_coeff" | bc -l); local b=$(echo "$r_const - $l_const" | bc -l); local a_f=$(echo "$a" | awk '{printf "%g", $1}'); local b_f=$(echo "$b" | awk '{printf "%g", $1}')
echo -e "${G}$(t step) 2 - $(t eq_group):${END} ${a_f}$var = $b_f"
if (( $(echo "$a == 0" | bc -l) )); then echo -e "${R}$(t no_solution)${END}"; return; fi
local xval=$(echo "scale=10; $b / $a" | bc -l); local xval_f=$(echo "$xval" | awk '{printf "%g", $1}')
echo -e "${G}$(t step) 3 - $(t eq_div):${END} $var = $b_f : $a_f"; echo -e "${Y}${BOLD}$(t eq_res): $var = $xval_f${END}"
VARS[$var]=$xval_f; VARS[ans]=$xval_f
}
choose_language(){
echo -e "${W}Choose language:${END}"
echo "1. Indonesia"
echo "2. English"
echo -ne "> "
read -r lc
lc_trim=$(echo "$lc" | xargs | tr '[:upper:]' '[:lower:]')
if [[ "$lc_trim" == "2" || "$lc_trim" == "english" || "$lc_trim" == "en" || "$lc_trim" == "eng" ]]; then LANG_SET="en"
else LANG_SET="id"
fi
clear
banner
echo -e "${D}$(t help_hint)${END}"
echo -e "${D}$(t mode_title): $MODE${END}\n"
}
choose_mode(){
echo -e "${W}$(t mode_title):${END}"
echo "1. Bulatan / Round - 1/2 = 0.5"
echo "2. Pecahan / Fraction - 1/2 stays 1/2, 2/4=1/2"
echo -ne "> "
read -r mc
mc_trim=$(echo "$mc" | xargs | tr '[:upper:]' '[:lower:]')
if [[ "$mc_trim" == "1" || "$mc_trim" == "bulatan" || "$mc_trim" == "bulat" || "$mc_trim" == "round" ]]; then
MODE="bulatan"
echo -e "${Y}$(t mode_changed): bulatan/round${END}"
elif [[ "$mc_trim" == "2" || "$mc_trim" == "pecahan" || "$mc_trim" == "fraction" || "$mc_trim" == "frac" ]]; then
MODE="pecahan"
echo -e "${Y}$(t mode_changed): pecahan/fraction${END}"
else
echo -e "${D}$(t mode_title): $MODE${END}"
fi
}
do_question(){
local diff_input="$1"
local diff=$(echo "$diff_input" | tr '[:upper:]' '[:lower:]' | xargs)
if [[ -z "$diff" ]]; then
echo -e "${Y}$(t q_choose)${END}"
echo "1. Easy"
echo "2. Medium"
echo "3. Hard"
echo "4. Extreme"
echo "5. Ultimate"
echo -ne "> "
read -r diff
diff=$(echo "$diff" | tr '[:upper:]' '[:lower:]' | xargs)
fi
case "$diff" in
1|easy) diff="easy" ;;
2|medium) diff="medium" ;;
3|hard) diff="hard" ;;
4|extreme) diff="extreme" ;;
5|ultimate) diff="ultimate" ;;
esac
local q=""
local ans=""
if [[ "$diff" == "easy" ]]; then
a=$((RANDOM%50+1)); b=$((RANDOM%50+1)); ops=("+" "-" "*" ":"); op=${ops[$((RANDOM%4))]}
if [[ "$op" == ":" ]]; then b=$((RANDOM%9+2)); a=$((b*(RANDOM%12+1))); fi
q="$a$op$b"
ans=$(eval_numeric_full "$q" | cut -d'|' -f1 | awk '{printf "%g", $1}')
elif [[ "$diff" == "medium" ]]; then
a=$((RANDOM%20+1)); b=$((RANDOM%20+1)); c=$((RANDOM%10+1)); d=$((RANDOM%5+1))
types=$((RANDOM%5))
if [[ $types -eq 0 ]]; then q="($a+$b)*$c"
elif [[ $types -eq 1 ]]; then q="${a}²+$b:$c"
elif [[ $types -eq 2 ]]; then q="√$((b*b))+$a*$c"
elif [[ $types -eq 3 ]]; then q="$a%*$b+$c"
else q="(${a}+${b})*${c}:${d}"
fi
ans=$(eval_numeric_full "$q" | cut -d'|' -f1 | awk '{printf "%g", $1}')
elif [[ "$diff" == "hard" ]]; then
a=$((RANDOM%8+2)); x=$((RANDOM%15+1)); b=$((RANDOM%30+1)); c=$((a*x+b))
q="${a}x+${b}=${c}"
ans="$x"
elif [[ "$diff" == "extreme" ]]; then
types=$((RANDOM%6))
if [[ $types -eq 0 ]]; then q="sin(30)"; ans="0.5"
elif [[ $types -eq 1 ]]; then q="cos(60)"; ans="0.5"
elif [[ $types -eq 2 ]]; then q="sin(90)"; ans="1"
elif [[ $types -eq 3 ]]; then q="cos(0)"; ans="1"
elif [[ $types -eq 4 ]]; then q="log(100)"; ans="2"
else q="√$((25)) + 5! : 20"; ans=$(eval_numeric_full "$q" | cut -d'|' -f1 | awk '{printf "%g", $1}')
fi
else
a=$((RANDOM%7+2)); b=$((RANDOM%12+1)); c=$((RANDOM%9+1)); d=$((RANDOM%6+1)); e=$((RANDOM%4+2))
q="(${a}²+√$((b*b))):$c + sin(30)*$d + $e!"
ans=$(eval_numeric_full "$q" | cut -d'|' -f1 | awk '{printf "%g", $1}')
fi
echo -e "${Y}$(t q_ask) [$diff]: ${W}$q${END}"
echo -ne "> "
read -r user_ans
user_ans=$(echo "$user_ans" | xargs)
if [[ -z "$user_ans" ]]; then return; fi
diff_check=$(echo "$user_ans - $ans" | bc -l 2>/dev/null)
diff_check=${diff_check#-}
is_ok=$(echo "$diff_check < 0.01" | bc -l 2>/dev/null)
if [[ "$is_ok" == "1" ]]; then echo -e "${G}$(t q_correct)${END}"
else echo -e "${R}$(t q_wrong) $ans${END}"; fi
HIST+=("Q:$q A:$ans User:$user_ans")
}
check_bc
banner
choose_language
while true; do
echo -ne "${G}$(t prompt)${END}"
read -r raw
input=$(echo "$raw" | xargs)
[[ -z "$input" ]] && continue
low=$(echo "$input" | tr '[:upper:]' '[:lower:]')
if [[ "$low" == way* ]]; then
expr=$(echo "$raw" | cut -c4- | xargs)
if [[ -z "$expr" ]]; then if [[ -n "$LAST_EXPR" ]]; then expr="$LAST_EXPR"; else echo -e "${R}$(t way_usage)${END}"; continue; fi; fi
LAST_EXPR="$expr"
if [[ "$expr" == *"="* ]]; then way_equation "$expr"; else way_numeric "$expr"; fi
continue
fi
if [[ "$low" == question* ]]; then
qarg=$(echo "$raw" | cut -c9- | xargs)
do_question "$qarg"
continue
fi
if [[ "$low" == mode* ]]; then
marg=$(echo "$raw" | cut -c5- | xargs | tr '[:upper:]' '[:lower:]')
if [[ -z "$marg" ]]; then
choose_mode
else
if [[ "$marg" == "1" || "$marg" == "bulatan" || "$marg" == "bulat" || "$marg" == "round" ]]; then MODE="bulatan"; echo -e "${Y}$(t mode_changed): bulatan/round${END}"
elif [[ "$marg" == "2" || "$marg" == "pecahan" || "$marg" == "fraction" || "$marg" == "frac" ]]; then MODE="pecahan"; echo -e "${Y}$(t mode_changed): pecahan/fraction${END}"
else choose_mode
fi
fi
continue
fi
case "$low" in
exit|keluar|q|quit) echo -e "${Y}$(t bye)${END}"; break ;;
help) t help; continue ;;
clear) banner; echo -e "${D}$(t help_hint)${END}"; echo -e "${D}$(t mode_title): $MODE${END}\n"; continue ;;
lang|language|bahasa) choose_language; continue ;;
vars) echo -e "\n${M}${BOLD}$(t var_title)${END}"; for k in "${!VARS[@]}"; do echo -e "  ${C}$k${END} = ${VARS[$k]}"; done; echo; continue ;;
history) echo -e "\n${M}${BOLD}$(t hist_title)${END}"; i=1; for h in "${HIST[@]}"; do echo -e "  ${D}$i.${END} $h"; i=$((i+1)); done; echo; continue ;;
esac
varcount=$(count_vars "$input")
if [[ "$varcount" -gt 1 ]]; then echo -e "${R}$(t var_multi)${END}"; continue; fi
has_bagi=0; has_per=0
[[ "$raw" == *":"* ]] && has_bagi=1
[[ "$raw" == *"/"* ]] && has_per=1
if [[ "$input" == *"="* ]]; then
if [[ "$input" =~ ^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*[^=]+$ ]]; then
left=$(echo "$input" | cut -d'=' -f1 | xargs); right=$(echo "$input" | cut -d'=' -f2- | xargs)
eval_res=$(eval_numeric_full "$right"); res=$(echo "$eval_res" | cut -d'|' -f1)
if [[ -n "$res" ]]; then VARS[$left]=$(echo "$res" | awk '{printf "%g", $1}'); VARS[ans]=${VARS[$left]}; echo -e "  ${C}$left${END} = ${BOLD}${VARS[$left]}${END} ${D}$(t saved)${END}"; HIST+=("$input = ${VARS[$left]}"); LAST_EXPR="$input"; continue; fi
fi
left=$(echo "$input" | cut -d'=' -f1); right=$(echo "$input" | cut -d'=' -f2-); var=$(echo "$input" | grep -o -E '[a-zA-Z]' | head -n1)
if [[ -n "$var" ]]; then expr="($left)-($right)"; b=$(eval_at "$expr" "$var" 0); ab=$(eval_at "$expr" "$var" 1)
if [[ -n "$b" && -n "$ab" ]]; then a=$(echo "$ab - $b" | bc -l)
if (( $(echo "$a == 0" | bc -l) )); then echo -e "${R}$(t no_solution)${END}"; else xval=$(echo "scale=10; -($b)/($a)" | bc -l); xval_f=$(echo "$xval" | awk '{printf "%g", $1}'); echo -e "${Y}  ➜ ${W}${BOLD}$var = $xval_f${END}"; VARS[$var]=$xval_f; VARS[ans]=$xval_f; HIST+=("$input => $var=$xval_f"); LAST_EXPR="$input"; fi; continue; fi
fi
fi
tmp=$(normalize_expr "$input"); tmp=$(add_implicit_mul "$tmp"); tmp2=$(echo "$tmp" | sed -E 's/sqrt//g')
if echo "$tmp2" | grep -q -E '[a-zA-Z]'; then var=$(echo "$tmp2" | grep -o -E '[a-zA-Z_][a-zA-Z0-9_]*' | head -n1); simplified=$(simplify_algebra "$input" "$var"); if [[ "$simplified" != "$input" && -n "$simplified" ]]; then echo -e "  ${Y}➜ ${W}${BOLD}$simplified${END} ${D}[aljabar $var]${END}"; HIST+=("$input = $simplified"); LAST_EXPR="$input"; continue; fi; fi
eval_res=$(eval_numeric_full "$input"); res=$(echo "$eval_res" | cut -d'|' -f1)
if [[ -z "$res" ]]; then echo -e "${R}$(t invalid)${END}"; continue; fi
res_f=$(echo "$res" | awk '{printf "%g", $1}')
if [[ "$MODE" == "pecahan" && $has_per -eq 1 ]]; then
frac=$(to_frac "$res"); res_f="$frac"
fi
VARS[ans]=$res_f
out="  ${Y}➜ ${W}${BOLD}$res_f${END}"
if [[ "$MODE" == "pecahan" && $has_per -eq 1 ]]; then out="$out ${D}$(t per_label) simplified${END}"
elif [[ $has_bagi -eq 1 ]]; then out="$out ${D}$(t bagi_label)${END}"
elif [[ $has_per -eq 1 ]]; then out="$out ${D}$(t per_label)${END}"
fi
echo -e "$out"
HIST+=("$input = $res_f")
LAST_EXPR="$input"
done
