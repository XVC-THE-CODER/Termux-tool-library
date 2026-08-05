#!/bin/bash
# ULTRA CALCULATOR v3.1 - FIXED FOR TERMUX
# Fix: sed \2 error, + tambah, - kurang, * kali, : bagi, / per, aljabar x,y

R='\033[91m'; G='\033[92m'; Y='\033[93m'; B='\033[94m'; M='\033[95m'; C='\033[96m'; W='\033[97m'; D='\033[90m'; BOLD='\033[1m'; END='\033[0m'

declare -A VARS
VARS[ans]=0
HIST=()

banner(){
clear
echo -e "${C}${BOLD}"
cat <<'EOF'
██╗   ██╗██╗  ████████╗██████╗  █████╗ 
██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗
██║   ██║██║     ██║   ██████╔╝███████║
██║   ██║██║     ██║   ██╔══██╗██╔══██║
╚██████╔╝███████╗██║   ██║  ██║██║  ██║
 ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
EOF
echo -e "${Y}  CALCULATOR BASH FIX - ALJABAR${END}"
echo -e "${D}  [+ tambah] [- kurang] [* kali] [: bagi] [/ per] [²³√]${END}\n"
}

help_text(){
echo -e "
${Y}${BOLD}OPERATOR RESMI:${END}
  ${G}+${END} = tambah   -> 2+3 = 5
  ${G}-${END} = kurang   -> 5-2 = 3
  ${G}*${END} = kali     -> 5*5 = 25  (bukan x, x itu variabel)
  ${G}:${END} = bagi     -> 10:2 = 5
  ${G}/${END} = per      -> 1/2 = 0.5 (1/2)
  ${G}² ³ √${END} = pangkat/akar -> 5²=25, √16=4

${Y}${BOLD}ALJABAR:${END}
  ${G}2x+3x${END}     -> 5x
  ${G}x=5${END}       -> simpan
  ${G}2*x+3${END}     -> 13 (pakai * untuk kali)
  ${G}2x+3=11${END}   -> x = 4 (solver)

${Y}${BOLD}PERINTAH:${END}
  help, vars, history, clear, exit
"
}

# konversi aman tanpa \2 error
normalize_expr(){
  local e="$1"
  e=$(echo "$e" | sed -e 's/²/^2/g' -e 's/³/^3/g' -e 's/⁴/^4/g' -e 's/⁵/^5/g' -e 's/⁶/^6/g' -e 's/⁷/^7/g' -e 's/⁸/^8/g' -e 's/⁹/^9/g' -e 's/⁰/^0/g' -e 's/¹/^1/g')
  e=$(echo "$e" | sed -e 's/×/*/g' -e 's/π/3.1415926535/g' -e 's/÷/:/g')
  # akar: √16 -> sqrt(16), √(16) -> sqrt(16)
  e=$(echo "$e" | sed 's/√/sqrt/g')
  e=$(echo "$e" | sed -E 's/sqrt\(([0-9\.]+)\)/sqrt(\1)/g')
  e=$(echo "$e" | sed -E 's/sqrt([0-9]+)/sqrt(\1)/g')
  e=$(echo "$e" | sed -E 's/sqrt([a-zA-Z_][a-zA-Z0-9_]*)/sqrt(\1)/g')
  # : jadi /
  e=$(echo "$e" | sed 's/:/\//g')
  echo "$e"
}

# FIXED: tidak ada \2 invalid
add_implicit_mul(){
  local e="$1"
  # 2x -> 2*x (aljabar)
  e=$(echo "$e" | sed -E 's/([0-9])([a-zA-Z_])/\1*\2/g')
  # 2( -> 2*(
  e=$(echo "$e" | sed -E 's/([0-9])\(/\1*\(/g')
  # )( -> )*(
  e=$(echo "$e" | sed -E 's/\)\(/\)*\(/g')
  # )angka / )huruf -> )*angka
  e=$(echo "$e" | sed -E 's/\)([a-zA-Z0-9_])/\)*\1/g')
  echo "$e"
}

replace_vars(){
  local e="$1"
  for k in "${!VARS[@]}"; do
    # pakai \< \> tanpa -E biar aman di Termux
    e=$(echo "$e" | sed "s/\\<$k\\>/(${VARS[$k]})/g")
  done
  echo "$e"
}

eval_numeric_full(){
  local raw="$1"
  local e=$(normalize_expr "$raw")
  e=$(add_implicit_mul "$e")
  e=$(replace_vars "$e")
  local res=$(echo "scale=10; $e" | bc -l 2>/dev/null)
  echo "$res|$e"
}

eval_at(){
  local expr="$1"; local var="$2"; local val="$3"
  local e=$(normalize_expr "$expr")
  e=$(add_implicit_mul "$e")
  e=$(echo "$e" | sed "s/\\<$var\\>/($val)/g")
  for k in "${!VARS[@]}"; do
    if [[ "$k" != "$var" ]]; then
      e=$(echo "$e" | sed "s/\\<$k\\>/(${VARS[$k]})/g")
    fi
  done
  echo "$e" | bc -l 2>/dev/null
}

to_frac(){
  awk -v d="$1" '
  function gcd(a,b){a=int(a<0?-a:a); b=int(b<0?-b:b); while(b){t=b; b=a%b; a=t} return a}
  BEGIN{
    sign=""; if(d<0){sign="-"; d=-d}
    best_num=0; best_den=1; best_err=1e9
    for(den=1; den<=1000; den++){
      num=int(d*den+0.5); err=num/den-d; if(err<0) err=-err
      if(err<best_err){best_err=err; best_num=num; best_den=den; if(err<1e-9) break}
    }
    g=gcd(best_num,best_den); best_num/=g; best_den/=g
    if(best_den==1) printf "%s%d", sign, best_num
    else printf "%s%d/%d", sign, best_num, best_den
  }'
}

simplify_algebra(){
  local expr="$1"; local var="$2"
  echo "$expr" | awk -v v="$var" '
  {
    gsub(/ /,"",$0); gsub("\\*"v, v); gsub(v"\\*", v)
    gsub(/-/, "+-", $0)
    n=split($0, t, "+")
    coeff=0; const=0
    for(i=1;i<=n;i++){
      term=t[i]; if(term=="") continue
      if(index(term, v)>0){
        c=term; sub(v,"",c); sub(/\*$/,"",c)
        if(c==""||c=="+") c=1; else if(c=="-") c=-1
        coeff+=c
      } else { if(term!="") const+=term }
    }
    out=""
    if(coeff!=0){
      if(coeff==1) out=v; else if(coeff==-1) out="-"v
      else { if(coeff==int(coeff)) out=int(coeff) v; else out=coeff v }
    }
    if(const!=0){
      if(const>0){ if(out!="") out=out"+"const; else out=const }
      else out=out const
    }
    if(out=="") out="0"; print out
  }'
}

banner
echo -e "${D}Ketik 'help' untuk bantuan${END}\n"

while true; do
  echo -ne "${G}${BOLD}ultra>${END} "
  read -r raw
  input=$(echo "$raw" | xargs)
  [[ -z "$input" ]] && continue
  low=$(echo "$input" | tr '[:upper:]' '[:lower:]')
  case "$low" in
    exit|keluar|q|quit) echo -e "${Y}Bye!${END}"; break ;;
    help) help_text; continue ;;
    clear) banner; continue ;;
    vars) echo -e "\n${M}${BOLD}-- VARIABEL --${END}"; for k in "${!VARS[@]}"; do echo -e "  ${C}$k${END} = ${VARS[$k]}"; done; echo; continue ;;
    history) echo -e "\n${M}${BOLD}-- RIWAYAT --${END}"; i=1; for h in "${HIST[@]}"; do echo -e "  ${D}$i.${END} $h"; i=$((i+1)); done; echo; continue ;;
  esac

  has_bagi=0; has_per=0
  [[ "$raw" == *":"* ]] && has_bagi=1
  [[ "$raw" == *"/"* ]] && has_per=1

  # assignment & solver
  if [[ "$input" == *"="* ]]; then
    if [[ "$input" =~ ^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*[^=]+$ ]]; then
      left=$(echo "$input" | cut -d'=' -f1 | xargs)
      right=$(echo "$input" | cut -d'=' -f2- | xargs)
      eval_res=$(eval_numeric_full "$right")
      res=$(echo "$eval_res" | cut -d'|' -f1)
      if [[ -n "$res" ]]; then
        VARS[$left]=$(echo "$res" | awk '{printf "%g", $1}')
        VARS[ans]=${VARS[$left]}
        echo -e "  ${C}$left${END} = ${BOLD}${VARS[$left]}${END} ${D}[disimpan]${END}"
        HIST+=("$input = ${VARS[$left]}")
        continue
      fi
    fi
    # solver linear
    left=$(echo "$input" | cut -d'=' -f1)
    right=$(echo "$input" | cut -d'=' -f2-)
    var=$(echo "$input" | grep -o -E '[a-zA-Z]' | head -n1)
    if [[ -n "$var" ]]; then
      expr="($left)-($right)"
      b=$(eval_at "$expr" "$var" 0)
      ab=$(eval_at "$expr" "$var" 1)
      if [[ -n "$b" && -n "$ab" ]]; then
        a=$(echo "$ab - $b" | bc -l)
        if (( $(echo "$a == 0" | bc -l) )); then
          if (( $(echo "$b == 0" | bc -l) )); then echo -e "${Y}  ➜ Tak hingga solusi${END}"; else echo -e "${R}  ➜ Tidak ada solusi${END}"; fi
        else
          xval=$(echo "scale=10; -($b)/($a)" | bc -l)
          xval_f=$(echo "$xval" | awk '{printf "%g", $1}')
          echo -e "${Y}  ➜ ${W}${BOLD}$var = $xval_f${END} ${D}[aljabar]${END}"
          VARS[$var]=$xval_f; VARS[ans]=$xval_f; HIST+=("$input => $var=$xval_f")
        fi
        continue
      fi
    fi
  fi

  # cek aljabar murni
  tmp=$(normalize_expr "$input")
  tmp=$(add_implicit_mul "$tmp")
  tmp2=$(echo "$tmp" | sed -E 's/sqrt//g')
  if echo "$tmp2" | grep -q -E '[a-zA-Z]'; then
    var=$(echo "$tmp2" | grep -o -E '[a-zA-Z_][a-zA-Z0-9_]*' | head -n1)
    simplified=$(simplify_algebra "$input" "$var")
    if [[ "$simplified" != "$input" && -n "$simplified" ]]; then
      echo -e "  ${Y}➜ ${W}${BOLD}$simplified${END} ${D}[aljabar $var]${END}"
      HIST+=("$input = $simplified")
      continue
    fi
  fi

  eval_res=$(eval_numeric_full "$input")
  res=$(echo "$eval_res" | cut -d'|' -f1)
  if [[ -z "$res" ]]; then echo -e "${R}  Error: ekspresi tidak valid${END}"; continue; fi
  res_f=$(echo "$res" | awk '{printf "%g", $1}')
  VARS[ans]=$res_f
  out="  ${Y}➜ ${W}${BOLD}$res_f${END}"

  if [[ $has_per -eq 1 ]]; then
    frac=$(to_frac "$res"); [[ "$frac" != "$res_f" ]] && out="$out ${D}= $frac [per]${END}" || out="$out ${D}[per]${END}"
  elif [[ $has_bagi -eq 1 ]]; then out="$out ${D}[bagi]${END}"; fi
  [[ "$raw" == *"²"* || "$raw" == *"³"* || "$raw" == *"√"* ]] && out="$out ${D}[pangkat/akar]${END}"

  echo -e "$out"
  HIST+=("$input = $res_f")
done
