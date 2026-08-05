#!/usr/bin/env python3
# ULTRA CALCULATOR - Tool kalkulator canggih untuk Termux
# Fitur: : untuk bagi, / untuk per/pecahan, ² ³ √ π, variabel, history
import math
import re
import os
import sys
from fractions import Fraction

# Warna Termux
class C:
    R = '\033[91m'; G = '\033[92m'; Y = '\033[93m'
    B = '\033[94m'; M = '\033[95m'; C = '\033[96m'
    W = '\033[97m'; D = '\033[90m'; BOLD = '\033[1m'
    END = '\033[0m'

SUPER = {'⁰':'0','¹':'1','²':'2','³':'3','⁴':'4','⁵':'5','⁶':'6','⁷':'7','⁸':'8','⁹':'9'}

variables = {'ans': 0, 'pi': math.pi, 'e': math.e}
history = []

BANNER = f"""
{C.C}{C.BOLD}
██╗   ██╗██╗  ████████╗██████╗  █████╗ 
██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗
██║   ██║██║     ██║   ██████╔╝███████║
██║   ██║██║     ██║   ██╔══██╗██╔══██║
╚██████╔╝███████╗██║   ██║  ██║██║  ██║
 ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
{C.Y}   CALCULATOR v2.0 - Termux Edition{C.END}
{C.D}   [: = bagi] [/ = per/pecahan] [²³√ = pangkat/akar]{C.END}
"""

HELP_TEXT = f"""
{C.Y}{C.BOLD}PERINTAH:{C.END}
  {C.G}help{C.END}      : tampilkan bantuan ini
  {C.G}vars{C.END}      : lihat semua variabel
  {C.G}history{C.END}   : lihat riwayat hitungan
  {C.G}clear{C.END}     : bersihkan layar
  {C.G}exit{C.END}      : keluar

{C.Y}{C.BOLD}ATURAN ULTRA:{C.END}
  {C.W}1. Bagi pakai :  ->  {C.G}10:2 = 5{C.END}
  {C.W}2. Per/pecahan pakai / -> {C.G}1/2 = 0.5 (1/2){C.END}
  {C.W}3. Pangkat pakai ² ³ atau ^  -> {C.G}5² = 25, 2^3 = 8{C.END}
  {C.W}4. Akar pakai √  -> {C.G}√9 = 3, √16 = 4{C.END}
  {C.W}5. Kali bisa pakai x atau ×  -> {C.G}5 x 5 = 25{C.END}
  {C.W}6. Variabel -> {C.G}a=10  lalu  a:2 + 5²{C.END}
  {C.W}7. Fungsi math -> {C.G}sin(30), cos(0), log(10), sqrt(9){C.END}
  {C.W}8. Jawaban terakhir pakai ans{C.END}
"""

def convert_superscript(expr):
    """Convert ²³ dll jadi **2 **3"""
    res = ""
    i = 0
    while i < len(expr):
        ch = expr[i]
        if ch in SUPER:
            num = ""
            while i < len(expr) and expr[i] in SUPER:
                num += SUPER[expr[i]]
                i += 1
            res += "**" + num
            continue
        else:
            res += ch
            i += 1
    return res

def convert_sqrt(expr):
    """Convert √9 atau √(4+5) jadi sqrt(9)"""
    # √ diikuti angka, variabel, atau (....)
    pattern = r'√\s*(\([^\)]+\)|[a-zA-Z_]\w*|\d+\.?\d*)'
    def repl(m):
        inside = m.group(1)
        return f'sqrt({inside})'
    return re.sub(pattern, repl, expr)

def normalize(expr):
    """Normalisasi input user ke Python valid"""
    original = expr
    expr = expr.strip()
    
    # Simpan dulu info apakah ada / asli (per)
    has_per = '/' in original
    has_bagi = ':' in original

    # 1. superscript
    expr = convert_superscript(expr)
    # 2. akar
    expr = convert_sqrt(expr)
    # 3. simbol
    expr = expr.replace('×', '*').replace('÷', ':')
    expr = expr.replace('π', 'pi')
    # x kecil sebagai kali kalau diapit angka/spasi: 5 x 2 -> 5*2 tapi jangan rusak variabel x
    expr = re.sub(r'(\d)\s*[xX]\s*(\d)', r'\1*\2', expr)
    expr = re.sub(r'(\d)\s*[xX]\s*\(', r'\1*(', expr)
    
    # 4. : jadi / (python division)
    expr = expr.replace(':', '/')
    # 5. ^ jadi **
    expr = expr.replace('^', '**')
    
    # 6. implicit multiplication: 2(3) -> 2*(3), ) ( -> )*(
    expr = re.sub(r'(\d|\))\s*(\()', r'\1*\2', expr)
    expr = re.sub(r'(\))\s*(\d)', r'\1*\2', expr)

    return expr, has_per, has_bagi

def safe_eval(expr, vars_dict):
    allowed = {}
    # ambil semua fungsi math
    for k in dir(math):
        if not k.startswith('_'):
            allowed[k] = getattr(math, k)
    allowed.update(vars_dict)
    allowed['sqrt'] = math.sqrt
    allowed['Fraction'] = Fraction

    # eval aman tanpa builtins
    return eval(expr, {"__builtins__": {}}, allowed)

def main():
    os.system('clear')
    print(BANNER)
    print(f"{C.D}Ketik 'help' untuk bantuan, 'exit' untuk keluar{C.END}\n")

    while True:
        try:
            raw = input(f"{C.G}{C.BOLD}ultra>{C.END} ").strip()
            if not raw:
                continue

            low = raw.lower()
            if low in ['exit', 'keluar', 'q', 'quit']:
                print(f"{C.Y}Bye! Makasih udah pake Ultra Calculator.{C.END}")
                break
            if low == 'help':
                print(HELP_TEXT)
                continue
            if low == 'clear':
                os.system('clear')
                print(BANNER)
                continue
            if low == 'vars':
                print(f"\n{C.M}{C.BOLD}-- VARIABEL --{C.END}")
                for k,v in variables.items():
                    if k not in ['pi','e']:
                        print(f"  {C.C}{k}{C.END} = {v}")
                print()
                continue
            if low == 'history':
                print(f"\n{C.M}{C.BOLD}-- RIWAYAT --{C.END}")
                for i,h in enumerate(history[-20:],1):
                    print(f"  {C.D}{i}.{C.END} {h}")
                print()
                continue

            # Deteksi assignment variabel: a = 10:2
            # tapi hindari == 
            if '=' in raw and '==' not in raw and '>=' not in raw and '<=' not in raw and '!=' not in raw:
                parts = raw.split('=',1)
                var_name = parts[0].strip()
                expr_part = parts[1].strip()
                if var_name.isidentifier():
                    norm_expr, has_per, has_bagi = normalize(expr_part)
                    result = safe_eval(norm_expr, variables)
                    variables[var_name] = result
                    variables['ans'] = result
                    out = f"{C.C}{var_name}{C.END} = {C.BOLD}{result}{C.END}"
                    # jika pecahan
                    if has_per and isinstance(result, (int,float)):
                        try:
                            frac = Fraction(result).limit_denominator(1000)
                            if frac.denominator != 1:
                                out += f" {C.D}({frac}){C.END}"
                        except: pass
                    print(out)
                    history.append(f"{var_name} = {expr_part} = {result}")
                    continue

            # Kalkulasi biasa
            norm_expr, has_per, has_bagi = normalize(raw)
            result = safe_eval(norm_expr, variables)
            variables['ans'] = result

            # Format output
            if isinstance(result, float):
                if result.is_integer():
                    result_print = int(result)
                else:
                    result_print = result
            else:
                result_print = result

            print(f"{C.Y}  ➜ {C.W}{C.BOLD}{result_print}{C.END}", end="")

            # Jika user pake / (per), tampilkan pecahan juga
            if has_per:
                try:
                    if isinstance(result, (int,float)):
                        frac = Fraction(result).limit_denominator(10000)
                        if frac.denominator != 1 and float(frac) == float(result):
                            print(f" {C.D}= {frac} {C.END}", end="")
                        elif isinstance(result, float):
                            # untuk 1/2 -> tampilkan 1/2 juga
                            frac2 = Fraction(norm_expr).limit_denominator() if False else None
                            pass
                except:
                    pass

            # Jika user pake : kasih tau itu bagi
            if has_bagi and has_per:
                print(f" {C.D}[bagi + per]{C.END}")
            elif has_bagi:
                print(f" {C.D}[bagi]{C.END}")
            elif has_per:
                print(f" {C.D}[per/pecahan]{C.END}")
            else:
                print()

            history.append(f"{raw} = {result_print}")

        except ZeroDivisionError:
            print(f"{C.R}  Error: Pembagian dengan nol!{C.END}")
        except Exception as e:
            print(f"{C.R}  Error: {e}{C.END}")
            print(f"{C.D}  Tips: pakai : untuk bagi, contoh 10:2{C.END}")

if __name__ == "__main__":
    main()
