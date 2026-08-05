#!/bin/bash
# =============================================================================
# UC - Ultra Calculator by the creator tool
# v7 - English language chooser, number or name, auto clear after choose
# =============================================================================

R='\033[91m'; G='\033[92m'; Y='\033[93m'; B='\033[94m'; M='\033[95m'; C='\033[96m'; W='\033[97m'; D='\033[90m'; BOLD='\033[1m'; END='\033[0m'

declare -A VARS
VARS[ans]=0
HIST=()
LAST_EXPR=""
LANG_SET="id"

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
echo -e "${D}  v7 | [+ add] [- sub] [* mul] [: div] [/ per] [Way]${END}"
echo ""
}

t(){
  local key="$1"
  if [[ "$LANG_SET" == "en" ]]; then
    case "$key" in
      prompt) echo "ultra> " ;;
      help_hint) echo "Type 'help' for help, 'way <expr>' for steps, 'lang' to change language" ;;
      help) echo -e "
${Y}${BOLD}OPERATORS:${END}
  ${G}+${END} = add      -> 2+3=5
  ${G}-${END} = subtract -> 5-2=3
  ${G}*${END} = multiply -> 5*5=25
  ${G}:${END} = divide   -> 10:2=5
  ${G}/${END} = per/fraction -> 1/2=0.5
  ${G}² ³ ^ √${END} = power/root
${Y}${BOLD}COMMANDS:${END}
  help, vars, history, clear, lang, exit
  ${G}way <expr>${END} -> ex: way 10:2+5*2 | way 2x+3=11
" ;;
      bye) echo "Bye! Thanks for using UC!" ;;
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
      eq_calc) echo "Calculate" ;;
      eq_div) echo "Divide" ;;
      eq_res) echo "Result" ;;
      way_title) echo "WAY - Step by Step" ;;
      no_solution) echo "No solution" ;;
      bagi_label) echo "[divide]" ;;
      per_label) echo "[per]" ;;
    esac
  else
    case "$key" in
      prompt) echo "ultra> " ;;
      help_hint) echo "Ketik 'help' untuk bantuan, 'way <rumus>' untuk cara, 'lang' ganti bahasa" ;;
      help) echo -e "
${Y}${BOLD}OPERATOR:${END}
  ${G}+${END} = tambah   -> 2+3=5
  ${G}-${END} = kurang   -> 5-2=3
  ${G}*${END} = kali     -> 5*5=25
  ${G}:${END} = bagi     -> 10:2=5
  ${G}/${END} = per      -> 1/2=0.5
  ${G}² ³ ^ √${END} = pangkat/akar
${Y}${BOLD}PERINTAH:${END}
  help, vars, history, clear, lang, exit
  ${G}way <rumus>${END} -> ex: way 10:2+5*2 | way 2x+3=11
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
      eq_calc) echo "Hitung" ;;
      eq_div) echo "Bagi" ;;
      eq_res) echo "Hasil" ;;
      way_title) echo "WAY - Cara" ;;
      no_solution) echo "Tidak ada solusi" ;;
      bagi_label) echo "[bagi]" ;;
      per_label) echo "[per]" ;;
    esac
  fi
}

normalize_expr(){
  local e="$1"
  e=$(echo "$e" | sed -e 's/²/^2/g' -e 's/³/^3/g' -e 's/⁴/^4/g' -e 's/⁵/^5/g' -e 's/⁶/^6/g' -e 's/⁷/^7/g' -e 's/⁸/^8/g' -e 's/⁹/^9/g' -e 's/⁰/^0/g' -e 's/¹/^1/g')
  e=$(echo "$e" | sed -e 's/×/*/g' -e 's/÷/:/g' -e 's/π/3.1415926535/g')
  e=$(echo "$e" | sed 's/√/sqrt/g')
  e=$(echo "$e" | sed -E 's/sqrt([0-9]+)/sqrt(\1)/g')
  e=$(echo "$e" | sed 's/:/\//g')
  echo "$e"
}
add_implicit_mul(){
  local e="$1"
  e=$(echo "$e" | sed -E 's/([0-9])([a-zA-Z_])/\1*\2/g')
  e=$(echo "$e" | sed -E 's/([0-9])\(/\1*\(/g')
  e=$(echo "$e" | sed -E 's/\)\(/\)*\(/g')
  e=$(echo "$e" | sed -E 's/\)([a-zA-Z0-9_])/\)*\1/g')
  echo "$e"
}
replace_vars(){
  local e="$1"
  for k in "${!VARS[@]}"; do e=$(echo "$e" | sed "s/\\<$k\\>/(${VARS[$k]})/g"); done
  echo "$e"
}
eval_numeric_full(){
  local raw="$1"; local e=$(normalize_expr "$raw"); e=$(add_implicit_mul "$e"); e=$(replace_vars "$e")
  local res=$(echo "scale=10; $e" | bc -l 2>/dev/null); echo "$res|$e"
}
eval_at(){
  local expr="$1"; local var="$2"; local val="$3"
  local e=$(normalize_expr "$expr"); e=$(add_implicit_mul "$e")
  e=$(echo "$e" | sed "s/\\<$var\\>/($val)/g")
  for k in "${!VARS[@]}"; do [[ "$k" != "$var" ]] && e=$(echo "$e" | sed "s/\\<$k\\>/(${VARS[$k]})/g"); done
  echo "$e" | bc -l 2>/dev/null
}
to_frac(){
  awk -v d="$1" 'function gcd(a,b){a=int(a<0?-a:a); b=int(b<0?-b:b); while(b){t=b; b=a%b; a=t} return a}
  BEGIN{sign=""; if(d<0){sign="-"; d=-d} best_num=0; best_den=1; best_err=1e9; for(den=1; den<=1000; den++){num=int(d*den+0.5); err=num/den-d; if(err<0) err=-err; if(err<best_err){best_err=err; best_num=num; best_den=den; if(err<1e-9) break}} g=gcd(best_num,best_den); best_num/=g; best_den/=g; if(best_den==1) printf "%s%d", sign, best_num; else printf "%s%d/%d", sign, best_num, best_den}'
}
simplify_algebra(){
  local expr="$1"; local var="$2"
  echo "$expr" | awk -v v="$var" '{gsub(/ /,"",$0); gsub("\\*"v, v); gsub(v"\\*", v); gsub(/-/, "+-", $0); n=split($0, t, "+"); coeff=0; const=0; for(i=1;i<=n;i++){term=t[i]; if(term=="") continue; if(index(term, v)>0){c=term; sub(v,"",c); sub(/\*$/,"",c); if(c==""||c=="+") c=1; else if(c=="-") c=-1; coeff+=c} else if(term!="") const+=term} out=""; if(coeff!=0){if(coeff==1) out=v; else if(coeff==-1) out="-"v; else {if(coeff==int(coeff)) out=int(coeff) v; else out=coeff v}} if(const!=0){if(const>0){if(out!="") out=out"+"const; else out=const} else out=out const} if(out=="") out="0"; print out}'
}
way_numeric(){
  local raw="$1"; local cur_norm=$(normalize_expr "$raw"); local cur_imp=$(add_implicit_mul "$cur_norm"); local cur_vars=$(replace_vars "$cur_imp")
  echo -e "${Y}--- $(t way_title): $raw ---${END}"; echo -e "${W}$(t orig):${END} $raw"
  [[ "$cur_norm" != "$raw" ]] && echo -e "${D}$(t norm): $cur_norm${END}"
  [[ "$cur_vars" != "$cur_imp" ]] && echo -e "${D}$(t subst): $cur_imp -> $cur_vars${END}"
  local cur="$cur_vars"; local step=1
  for _ in $(seq 1 40); do
    [[ "$cur" =~ ^-?[0-9.]+$ ]] && break
    if [[ "$cur" =~ sqrt\([^()]+\) ]]; then match=$(echo "$cur" | grep -oE 'sqrt\([^()]+\)' | head -n1); inner=$(echo "$match" | sed -E 's/sqrt\((.*)\)/\1/'); val=$(echo "scale=10; sqrt($inner)" | bc -l 2>/dev/null); [[ -z "$val" ]] && break; val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $match = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
    if [[ "$cur" =~ \([^()]+\) ]]; then match=$(echo "$cur" | grep -oE '\([^()]+\)' | head -n1); inner=$(echo "$match" | tr -d '()'); val=$(echo "scale=10; $inner" | bc -l 2>/dev/null); [[ -z "$val" ]] && break; val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $match = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
    if echo "$cur" | grep -qE '[0-9.]+\^[0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\^[0-9.]+' | head -n1); l=$(echo "$match" | cut -d'^' -f1); r=$(echo "$match" | cut -d'^' -f2); val=$(echo "scale=10; $l ^ $r" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $l ^ $r = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
    if echo "$cur" | grep -qE '[0-9.]+[*\/][0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\s*[*\/]\s*[0-9.]+' | head -n1); clean=$(echo "$match" | tr -d ' '); op=$(echo "$clean" | grep -oE '[*\/]'); l=$(echo "$clean" | awk -F'[*\/]' '{print $1}'); r=$(echo "$clean" | awk -F'[*\/]' '{print $2}'); val=$(echo "scale=10; $l $op $r" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $clean = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
    if echo "$cur" | grep -qE '[0-9.]+[+\-][0-9.]+'; then match=$(echo "$cur" | grep -oE '[0-9.]+\s*[+\-]\s*[0-9.]+' | head -n1); clean=$(echo "$match" | tr -d ' '); val=$(echo "scale=10; $clean" | bc -l); val_f=$(echo "$val" | awk '{printf "%g", $1}'); echo -e "${G}$(t step) $step:${END} $clean = $val_f"; cur=$(awk -v c="$cur" -v o="$match" -v n="$val_f" 'BEGIN{pos=index(c,o); print substr(c,1,pos-1) n substr(c,pos+length(o))}'); echo -e "  -> $cur"; step=$((step+1)); continue; fi
    break
  done
  final=$(echo "$cur" | awk '{printf "%g", $1}'); echo -e "${Y}${BOLD}$(t final): $final${END}"
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

# ---- FUNGSI PILIH BAHASA (ENGLISH ONLY PROMPT, BISA NOMOR ATAU NAMA) ----
choose_language(){
  echo -e "${W}Choose language:${END}"
  echo "1. Indonesia"
  echo "2. English"
  echo -ne "> "
  read -r lc
  # lower + trim
  lc_trim=$(echo "$lc" | xargs | tr '[:upper:]' '[:lower:]')
  # bisa nomor atau nama
  if [[ "$lc_trim" == "2" || "$lc_trim" == "english" || "$lc_trim" == "en" || "$lc_trim" == "inggris" ]]; then
    LANG_SET="en"
  else
    # default 1 / indonesia
    LANG_SET="id"
  fi
  # langsung clear setelah pilih
  clear
  banner
  echo -e "${D}$(t help_hint)${END}\n"
}

# ===================== START =====================
banner
choose_language

while true; do
  echo -ne "${G}$(t prompt)${END}"
  read -r raw
  input=$(echo "$raw" | xargs); [[ -z "$input" ]] && continue
  low=$(echo "$input" | tr '[:upper:]' '[:lower:]')

  if [[ "$low" == way* ]]; then
    expr=$(echo "$raw" | cut -c4- | xargs)
    if [[ -z "$expr" ]]; then [[ -n "$LAST_EXPR" ]] && expr="$LAST_EXPR" || { echo -e "${R}$(t way_usage)${END}"; continue; }; fi
    LAST_EXPR="$expr"
    if [[ "$expr" == *"="* ]]; then way_equation "$expr"; else way_numeric "$expr"; fi
    continue
  fi

  case "$low" in
    exit|keluar|q|quit) echo -e "${Y}$(t bye)${END}"; break ;;
    help) t help; continue ;;
    clear) banner; echo -e "${D}$(t help_hint)${END}\n"; continue ;;
    lang|language|bahasa) choose_language; continue ;;
    vars) echo -e "\n${M}${BOLD}$(t var_title)${END}"; for k in "${!VARS[@]}"; do echo -e "  ${C}$k${END} = ${VARS[$k]}"; done; echo; continue ;;
    history) echo -e "\n${M}${BOLD}$(t hist_title)${END}"; i=1; for h in "${HIST[@]}"; do echo -e "  ${D}$i.${END} $h"; i=$((i+1)); done; echo; continue ;;
  esac

  has_bagi=0; has_per=0; [[ "$raw" == *":"* ]] && has_bagi=1; [[ "$raw" == *"/"* ]] && has_per=1

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
  res_f=$(echo "$res" | awk '{printf "%g", $1}'); VARS[ans]=$res_f
  out="  ${Y}➜ ${W}${BOLD}$res_f${END}"; if [[ $has_per -eq 1 ]]; then frac=$(to_frac "$res"); [[ "$frac" != "$res_f" ]] && out="$out ${D}= $frac $(t per_label)${END}" || out="$out ${D}$(t per_label)${END}"; elif [[ $has_bagi -eq 1 ]]; then out="$out ${D}$(t bagi_label)${END}"; fi
  echo -e "$out"; HIST+=("$input = $res_f"); LAST_EXPR="$input"
done
