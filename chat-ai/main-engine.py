#!/data/data/com.termux/files/usr/bin/python3
# -*- coding: utf-8 -*-
import os, re, sys, sqlite3, time, base64
from datetime import datetime
try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Jalanin dulu: pip install requests beautifulsoup4")
    sys.exit()

# === [DATABASE TERSEMBUNYI] ===
HIDDEN_DIR = os.path.join(os.path.expanduser("~"), ".kamus_ai")
DB_PATH = os.path.join(HIDDEN_DIR, ".core.db")

def encode(t):
    try: return base64.b64encode(t.encode()).decode()
    except: return t
def decode(t):
    try: return base64.b64decode(t.encode()).decode()
    except: return t
def clear(): os.system("clear")

def init_storage():
    os.makedirs(HIDDEN_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS kamus (
        kata TEXT PRIMARY KEY, bahasa TEXT, jenis TEXT,
        arti TEXT, kapan TEXT, contoh TEXT, sumber TEXT
    )''')
    c.execute('''CREATE TABLE IF NOT EXISTS qa (
        kunci TEXT PRIMARY KEY, jawaban TEXT
    )''')
    conn.commit()
    # seed bawaan biar tetep bisa jawab offline
    c.execute("SELECT COUNT(*) FROM qa")
    if c.fetchone()[0]==0:
        bawaan = {
            "siapa kamu": "Aku Kamus AI Core. Aku belajar setiap kata dari prompt kamu dan simpan di database hidden.",
            "halo": "Halo! Tanya apa aja, misal 'apa itu fotosintesis'"
        }
        for k,v in bawaan.items():
            c.execute("INSERT OR IGNORE INTO qa VALUES (?,?)", (k, encode(v)))
        conn.commit()
    conn.close()

def cari_kbbi(kata):
    try:
        h={"User-Agent":"Mozilla/5.0"}
        r=requests.get(f"https://kbbi.kemdikbud.go.id/entri/{kata}", headers=h, timeout=7)
        if r.status_code==200 and "tidak ditemukan" not in r.text.lower():
            soup=BeautifulSoup(r.text,'html.parser')
            ol=soup.find('ol')
            if ol and ol.find('li'):
                arti=ol.find('li').get_text(" ", strip=True)[:600]
                return {"bahasa":"Indonesia","jenis":"nomina","arti":arti,"kapan":f"Dipakai formal untuk konteks {kata}","contoh":f"Contoh: penggunaan kata {kata}","sumber":"KBBI"}
        r2=requests.get(f"https://kbbi.web.id/{kata}", headers=h, timeout=7)
        if r2.status_code==200:
            soup2=BeautifulSoup(r2.text,'html.parser')
            d=soup2.find('div', id='d1')
            if d:
                return {"bahasa":"Indonesia","jenis":"baku","arti":d.get_text(" ", strip=True)[:600],"kapan":"Dipakai resmi","contoh":"-","sumber":"kbbi.web.id"}
    except: pass
    return None

def cari_english(kata):
    try:
        r=requests.get(f"https://api.dictionaryapi.dev/api/v2/entries/en/{kata}", timeout=7)
        if r.status_code==200:
            data=r.json()[0]; m=data['meanings'][0]; defi=m['definitions'][0]
            return {"bahasa":"Inggris","jenis":m.get('partOfSpeech',''),"arti":defi.get('definition',''),"kapan":f"Sebagai {m.get('partOfSpeech')}","contoh":defi.get('example','-'),"sumber":"dictionaryapi"}
    except: pass
    return None

def simpan_langsung(kata, data):
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("INSERT OR REPLACE INTO kamus VALUES (?,?,?,?,?,?,?)",
              (kata, data['bahasa'], data['jenis'], encode(data['arti']), encode(data['kapan']), encode(data['contoh']), data['sumber']))
    conn.commit(); conn.close()

def cek_kamus(kata):
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("SELECT * FROM kamus WHERE kata=?", (kata,))
    r=c.fetchone(); conn.close()
    if r: return (r[0], r[1], r[2], decode(r[3]), decode(r[4]), decode(r[5]), r[6])
    return None

# === [OTAK UTAMA - SESUAI REQUEST LU] ===
STOPWORDS={'yang','dan','itu','ini','apa','bagaimana','kapan','untuk','dengan','adalah','saya','kamu','di','ke','dari','sih','bro','apa','the','is','are','apa','itu'}

def ai_jawab(prompt, kata_yang_baru_dipelajari):
    # 1. Cek dulu kalo nanya pengetahuan bawaan
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("SELECT jawaban FROM qa WHERE kunci=?", (prompt.lower().strip(),))
    row=c.fetchone()
    conn.close()
    if row: return decode(row[0])

    # 2. Kalo ada keyword yang tadi baru dipelajari, pakai itu buat jawab
    if kata_yang_baru_dipelajari:
        # ambil kata terpanjang / terpenting dari prompt
        target = max(kata_yang_baru_dipelajari, key=len) if len(kata_yang_baru_dipelajari)>0 else None
        if not target:
            # fallback ambil kata terakhir
            words = re.findall(r'\b[a-z]{3,}\b', prompt.lower())
            target = words[-1] if words else None

        if target:
            data = cek_kamus(target)
            if data:
                return f"Oke, jadi pertanyaanmu '{prompt}'\n\nAku udah pelajari kata '{data[0]}' barusan:\n> Bahasa: {data[1]}\n> Fungsi/Jenis: {data[2]}\n> Arti: {data[3]}\n> Kapan dipakai: {data[4]}\n> Contoh: {data[5]}\n\nJadi intinya: {data[3]}"

    return f"Aku sudah simpan {len(kata_yang_baru_dipelajari)} kata baru dari prompt kamu ke database hidden. Tanya lagi yang lebih spesifik tentang kata itu."

def main():
    init_storage()
    clear()
    print("\033[92m[KAMUS AI - AUTO LEARN MODE]\nDB Hidden: ~/.kamus_ai/.core.db [Encrypted]\033[0m\n")
    print("Ketik bebas, nanti semua kata langsung gw cari di KBBI & simpan, baru gw jawab pertanyaan lu.\nKetik /exit buat keluar + auto clear\n")

    while True:
        try:
            prompt = input("\033[93mKamu:\033[0m ").strip()
            if not prompt: continue
            if prompt.lower() in ["/exit","exit","keluar"]:
                print("Clearing..."); time.sleep(0.5); clear(); break

            # === INI INTI REQUEST LU ===
            # 1. Ambil semua kata di prompt user
            semua_kata = re.findall(r'\b[a-zA-Z]{3,}\b', prompt.lower())
            kata_unik = list(set([k for k in semua_kata if k not in STOPWORDS]))

            kata_baru_dipelajari = []
            print(f"\033[90m>> Terdeteksi {len(kata_unik)} kata, cek database...\033[0m")

            # 2. Kalo ada kata langsung cari di KBBI & simpan
            for k in kata_unik:
                if cek_kamus(k):
                    continue # sudah ada, skip

                print(f"\033[90m>> Kata baru '{k}' belum ada, langsung cari di KBBI...\033[0m", end=" ")
                data = cari_kbbi(k)
                if not data:
                    data = cari_english(k)

                if data:
                    simpan_langsung(k, data)
                    kata_baru_dipelajari.append(k)
                    print(f"\033[92mTersimpan! [{data['bahasa']}|{data['jenis']}]\033[0m")
                else:
                    print(f"\033[91mGak ketemu\033[0m")
                time.sleep(0.2)

            # 3. Lanjut jawab pertanyaan user tadi pake data yang baru disimpan
            jawaban = ai_jawab(prompt, kata_baru_dipelajari if kata_baru_dipelajari else kata_unik)
            print(f"\n\033[96mAI:\033[0m {jawaban}\n")

        except KeyboardInterrupt:
            clear(); break

if __name__ == "__main__":
    main()
