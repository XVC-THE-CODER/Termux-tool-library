#!/bin/bash
# ULTRA CALCULATOR - Bash Edition
# Fitur: : = bagi, / = per/pecahan, ²³√, variabel aljabar x,y
# Author: for Termux

# Warna
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
echo -e "${Y}  CALCULATOR v3.0 - BASH + ALJABAR${END}"
echo -e "${D}  [: = bagi] [/ = per] [²³√] [x,y aljabar]${END}\n"
}

help_text(){
echo -e "
${Y}${BOLD}PERINTAH:${END}
  ${G}help${END}      : bantuan
  ${G}vars${END}      : lihat variabel
  ${G}history${END}   : riwayat
  ${G}clear${END}     : bersihkan layar
  ${G}exit${END}      : keluar

${Y}${BOLD}ATURAN ULTRA BASH:${END}
  ${W}1. Bagi pakai :  ->${END} ${G}10:2 = 5${END}
  ${W}2. Per pakai / ->${END} ${G}1/2 = 0.5 (1/2)${END}
  ${W}3. Pangkat ${END}${G}5² = 25, 2³ = 8, 2^3 = 8${END}
  ${W}4. Akar ${END}${G}√16 = 4, √9 = 3${END}
  ${W}5. Aljabar:${END}
     ${G}2x+3x${END}      -> ${C}5x${END} (belum ada nilai x)
     ${G}x=5${END}        -> simpan variabel
     ${G}2x+3${END}       -> ${C}13${END} (kalau x=5)
     ${G}2x+3=11${END}    -> ${C}x = 4${END} (solver linear)
     ${G}3y+2=14${END}    -> ${C}y = 4${END}
"
}

gcd(){
  local a=${1#-}; local b=${2#-}
  a=${a%.*}; b=${b%.*}
  [[ $a -eq 0 ]] && echo $b && return
  while (( b != 0 )); do local t=$b; b=$((a % b)); a=$t; done
  echo $a
}

to_frac(){
  local dec=$1
  awk -v d="$dec" '
  function gcd(a,b){a=int(a<0?-a:a); b=int(b<0?-b:b); while(b){t=b; b=a%b; a=t} return a}
  BEGIN{
    sign=""; if(d<0){sign="-"; d=-d}
    best_num=0; best_den=1; best_err=1e9
    for(den=1; den<=1000; den++){
      num=int(d*den+0.5)
      err=(num/den - d); if(err<0) err=-err
      if(err<best_err){best_err=err; best_num=num; best_den=den; if(err<1e-9) break}
    }
    g=gcd(best_num,best_den); best_num/=g; best_den/=g
    if(best_den==1) printf "%s%d", sign, best_num
    else printf "%s%d/%d", sign, best_num, best_den
  }'
}

normalize_expr(){
  local expr="$1"
  echo "$expr" | sed \
    -e 's/²/^2/g' -e 's/³/^3/g' -e 's/⁴/^4/g' -e 's/⁵/^5/g' \
    -e 's/⁶/^6/g' -e 's/⁷/^7/g' -e 's/⁸/^8/g' -e 's/⁹/^9/g' -e 's/⁰/^0/g' -e 's/¹/^1/g' \
    -e 's/×/*/g' -e 's/π/3.1415926535/g' \
    | sed -E 's/√\s*\(?([A-Za-z0-9._^+\*\/-]+)\)?/sqrt(\1)/g' \
    | sed 's/:/\//g'
}

add_implicit_mul(){
  local e="$1"
  # 2x -> 2*x , 2( -> 2*( , ) ( -> )*(
  e=$(echo "$e" | sed -E 's/([0-9])([a-zA-Z_])/\1*\2/g')
  e=$(echo "$e" | sed -E 's/([0-9\)])\(/\1*\(/g')
  e=$(echo "$e" | sed -E 's/\)([0-9a-zA-Z_])/\1*\2/g')
  echo "$e"
}

eval_numeric_full(){
  local raw="$1"
  local e=$(normalize_expr "$raw")
  e=$(add_implicit_mul "$e")
  # ganti variabel yang sudah ada
  for k in "${!VARS[@]}"; do
    e=$(echo "$e" | sed -E "s/\\<$k\\>/(${VARS[$k]})/g")
  done
  # evaluasi bc -l
  local res=$(echo "scale=10; $e" | bc -l 2>/dev/null)
  echo "$res|$e"
}

eval_at(){
  local expr="$1"; local var="$2"; local val="$3"
  local e=$(normalize_expr "$expr")
  e=$(add_implicit_mul "$e")
  # ganti var target dengan val
  e=$(echo "$e" | sed -E "s/\\<$var\\>/($val)/g")
  # ganti variabel lain
  for k in "${!VARS[@]}"; do
    if [[ "$k" != "$var" ]]; then
      e=$(echo "$e" | sed -E "s/\\<$k\\>/(${VARS[$k]})/g")
    fi
  done
  echo "$e" | bc -l 2>/dev/null
}

simplify_algebra(){
  local expr="$1"; local var="$2"
  echo "$expr" | awk -v v="$var" '
  function abs(x){return x<0?-x:x}
  BEGIN{coeff=0; const=0}
  {
    orig=$0
    gsub(/ /,"",$0)
    gsub("\\*"v, v, $0)
    gsub(v"\\*", v, $0)
    gsub(/-/, "+-", $0)
    n=split($0, t, "+")
    for(i=1;i<=n;i++){
      term=t[i]; if(term=="") continue
      if(index(term, v)>0){
        c=term; sub(v,"",c); sub(/\*$/,"",c)
        if(c=="" || c=="+") c=1
        else if(c=="-") c=-1
        coeff+=c
      } else {
        if(term!="") const+=term
      }
    }
    # format output
    out=""
    if(coeff!=0){
      if(coeff==1) out=v
      else if(coeff==-1) out="-"v
      else {
        # hilangkan .0 kalau integer
        if(coeff==int(coeff)) out=int(coeff) v
        else out=coeff v
      }
    }
    if(const!=0){
      if(const>0){
        if(out!="") out=out"+"const
        else out=const
      } else {
        out=out const
      }
    }
    if(out=="") out="0"
    print out
  }'
}

# === MAIN LOOP ===
banner
echo -e "${D}Ketik 'help' untuk bantuan. Variabel aljabar: x,y,z dll${END}\n"

while true; do
  echo -ne "${G}${BOLD}ultra>${END} "
  read -r input
  raw="$input"
  input=$(echo "$input" | xargs) # trim
  [[ -z "$input" ]] && continue

  low=$(echo "$input" | tr '[:upper:]' '[:lower:]')
  case "$low" in
    exit|keluar|q|quit) echo -e "${Y}Bye!${END}"; break ;;
    help) help_text; continue ;;
    clear) banner; continue ;;
    vars)
      echo -e "\n${M}${BOLD}-- VARIABEL --${END}"
      for k in "${!VARS[@]}"; do echo -e "  ${C}$k${END} = ${VARS[$k]}"; done
      echo; continue ;;
    history)
      echo -e "\n${M}${BOLD}-- RIWAYAT --${END}"
      i=1; for h in "${HIST[@]}"; do echo -e "  ${D}$i.${END} $h"; i=$((i+1)); done
      echo; continue ;;
  esac

  has_bagi=0; has_per=0
  [[ "$raw" == *":"* ]] && has_bagi=1
  [[ "$raw" == *"/"* ]] && has_per=1

  # === DETEKSI PERSAMAAN / ASSIGNMENT ===
  if [[ "$input" == *"="* ]]; then
    # cek assignment sederhana: huruf = angka/expr  (contoh x=5, a=10:2)
    if [[ "$input" =~ ^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*[^=]+$ ]]; then
      left=$(echo "$input" | cut -d'=' -f1 | xargs)
      right=$(echo "$input" | cut -d'=' -f2- | xargs)
      # kalau kanan masih ada huruf yang bukan variabel terdefinisi, anggap itu persamaan, bukan assignment
      # tapi kalau kiri single huruf dan kanan tidak mengandung huruf yang sama? kita perlakukan assignment dulu
      # cek apakah kiri cuma 1 variabel dan kanan tidak mengandung = lagi
      if [[ "$left" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        # coba evaluasi kanan
        eval_result=$(eval_numeric_full "$right")
        res=$(echo "$eval_result" | cut -d'|' -f1)
        if [[ -n "$res" ]]; then
          # sukses
          VARS[$left]=$(echo "$res" | awk '{printf "%g", $1}')
          VARS[ans]=${VARS[$left]}
          echo -e "  ${C}$left${END} = ${BOLD}${VARS[$left]}${END} ${D}[disimpan]${END}"
          HIST+=("$input = ${VARS[$left]}")
          continue
        fi
      fi
    fi

    # === SOLVER PERSAMAAN LINEAR: 2x+3=11 ===
    if [[ "$input" == *"="* ]]; then
      left=$(echo "$input" | cut -d'=' -f1)
      right=$(echo "$input" | cut -d'=' -f2-)
      # cari variabel pertama (huruf)
      var=$(echo "$input" | grep -o -E '[a-zA-Z]' | head -n1)
      if [[ -n "$var" ]]; then
        expr="($left)-($right)"
        b=$(eval_at "$expr" "$var" 0)
        ab=$(eval_at "$expr" "$var" 1)
        if [[ -n "$b" && -n "$ab" ]]; then
          a=$(echo "$ab - $b" | bc -l)
          # cek linear
          if (( $(echo "$a == 0" | bc -l) )); then
            if (( $(echo "$b == 0" | bc -l) )); then
              echo -e "${Y}  ➜ Tak hingga solusi (identitas)${END}"
            else
              echo -e "${R}  ➜ Tidak ada solusi${END}"
            fi
          else
            xval=$(echo "scale=10; -($b)/($a)" | bc -l)
            xval_f=$(echo "$xval" | awk '{printf "%g", $1}')
            echo -e "${Y}  ➜ ${W}${BOLD}$var = $xval_f${END} ${D}[aljabar]${END}"
            # simpan juga
            VARS[$var]=$xval_f
            VARS[ans]=$xval_f
            HIST+=("$input => $var=$xval_f")
          fi
          continue
        fi
      fi
    fi
  fi

  # === EVALUASI BIASA ===
  # cek apakah ada huruf yang belum terdefinisi (aljabar murni)
  tmp_check=$(normalize_expr "$input")
  tmp_check=$(add_implicit_mul "$tmp_check")
  # hapus fungsi sqrt
  tmp_check2=$(echo "$tmp_check" | sed -E 's/sqrt//g')
  if echo "$tmp_check2" | grep -q -E '[a-zA-Z]'; then
    # ada variabel aljabar yang belum ada nilainya
    # cari var pertama
    var=$(echo "$tmp_check2" | grep -o -E '[a-zA-Z_][a-zA-Z0-9_]*' | head -n1)
    # coba apakah semua variabel lain sudah ada kecuali var ini? kalau ya, kita anggap aljabar
    # kalau ada lebih dari 1 var beda, tetap simplify untuk var pertama
    simplified=$(simplify_algebra "$input" "$var")
    # kalau simplified beda dari input, tampilkan penyederhanaan
    if [[ "$simplified" != "$input" && -n "$simplified" ]]; then
      echo -e "  ${Y}➜ ${W}${BOLD}$simplified${END} ${D}[aljabar $var]${END}"
      HIST+=("$input = $simplified")
      continue
    else
      # coba evaluasi kalau ada var yang sudah terdefinisi sebagian
      eval_res=$(eval_numeric_full "$input")
      res=$(echo "$eval_res" | cut -d'|' -f1)
      if [[ -n "$res" ]]; then
        res_f=$(echo "$res" | awk '{printf "%g", $1}')
        echo -e "  ${Y}➜ ${W}${BOLD}$res_f${END}"
        VARS[ans]=$res_f
        HIST+=("$input = $res_f")
        continue
      fi
      echo -e "${R}  Error: variabel '$var' belum ada nilai. Pakai $var=angka dulu atau ini bentuk aljabar.${END}"
      continue
    fi
  fi

  # murni numerik
  eval_res=$(eval_numeric_full "$input")
  res=$(echo "$eval_res" | cut -d'|' -f1)
  if [[ -z "$res" ]]; then
    echo -e "${R}  Error: ekspresi tidak valid${END}"
    continue
  fi
  res_f=$(echo "$res" | awk '{printf "%g", $1}')
  VARS[ans]=$res_f
  out="  ${Y}➜ ${W}${BOLD}$res_f${END}"

  if [[ $has_per -eq 1 ]]; then
    frac=$(to_frac "$res")
    # kalau frac beda dari desimal, tampilkan
    if [[ "$frac" != "$res_f" ]]; then
      out="$out ${D}= $frac [per]${END}"
    else
      out="$out ${D}[per]${END}"
    fi
  elif [[ $has_bagi -eq 1 ]]; then
    out="$out ${D}[bagi]${END}"
  fi

  # handle kuadrat/akar info
  if [[ "$raw" == *"²"* || "$raw" == *"³"* || "$raw" == *"√"* ]]; then
    out="$out ${D}[pangkat/akar]${END}"
  fi

  echo -e "$out"
  HIST+=("$input = $res_f")
done
