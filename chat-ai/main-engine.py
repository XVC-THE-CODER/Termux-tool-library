#!/data/data/com.termux/files/usr/bin/python3
# -*- coding: utf-8 -*-
import os, re, sys, sqlite3, time, base64, json
from datetime import datetime

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Install dulu: pip install requests beautifulsoup4")
    sys.exit()

# === [1] SYSTEM PENYIMPANAN TERSEMBUNYI ===
HIDDEN_DIR = os.path.join(os.path.expanduser("~"), ".kamus_ai")
DB_PATH = os.path.join(HIDDEN_DIR, ".core.db") # file titik = hidden di linux

def encode(t):
    try: return base64.b64encode(t.encode('utf-8')).decode()
    except: return t
def decode(t):
    try: return base64.b64decode(t.encode('utf-8')).decode()
    except: return t

def clear(): os.system("clear")

def init_storage():
    os.makedirs(HIDDEN_DIR, exist_ok=True)
    # bikin file.nomedia biar gak ke-scan
    open(os.path.join(HIDDEN_DIR, ".nomedia"), 'a').close()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS kamus (
        kata TEXT PRIMARY KEY, bahasa TEXT, jenis TEXT,
        arti TEXT, kapan TEXT, contoh TEXT, sumber TEXT, tgl TEXT
    )''')
    c.execute('''CREATE TABLE IF NOT EXISTS pengetahuan (
        kunci TEXT PRIMARY KEY, jawaban TEXT, tgl TEXT
    )''')
    conn.commit()
    conn.close()
    seed_builtin()

# === [2] DATABASE BAWAAN BIAR TETEP BISA JAWAB OFFLINE ===
BUILTIN_KAMUS = [
    ("saya","Indonesia","pronomina","kata ganti orang pertama","dipakai untuk diri sendiri","Saya belajar coding"),
    ("belajar","Indonesia","verba","berusaha memperoleh ilmu","dipakai saat aktivitas menuntut ilmu","Dia belajar AI"),
    ("komputer","Indonesia","nomina","alat elektronik pengolah data","dipakai di konteks teknologi","Komputer itu cepat"),
    ("fotosintesis","Indonesia","nomina","proses tumbuhan membuat makanan dengan cahaya","dipakai di biologi","Fotosintesis terjadi di daun"),
]

BUILTIN_QA = {
    "siapa kamu": "Aku adalah Kamus AI Core. Aku hidup di Termux kamu, database ku tersembunyi dan aku belajar dari setiap kata yang kamu ketik.",
    "apa fungsi kamu": "Fungsiku adalah mengambil semua kata dari prompt kamu, mencari arti, fungsi kata (nomina/verba/adjektiva), dan kapan dipakai dari KBBI & kamus luar negeri, lalu simpan di database hidden.",
    "halo": "Halo juga! Tanya aja apa aja, contoh: 'apa itu epistemologi' atau 'jelaskan resilience'",
    "kamu bisa apa": "Aku bisa jawab arti kata, jelaskan konsep, dan aku ingat semua yang kamu ajarkan. Semakin banyak kamu chat, semakin pintar aku.",
}

def seed_builtin():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM kamus")
    if c.fetchone()[0] == 0:
        for k in BUILTIN_KAMUS:
            c.execute("INSERT OR IGNORE INTO kamus VALUES (?,?,?,?,?,?,?,?)",
                      (k[0], k[1], k[2], encode(k[3]), encode(k[4]), encode(k[5]), "builtin", datetime.now().strftime("%Y-%m-%d")))
        for kunci, jawab in BUILTIN_QA.items():
            c.execute("INSERT OR IGNORE INTO pengetahuan VALUES (?,?,?)",
                      (kunci, encode(jawab), datetime.now().strftime("%Y-%m-%d")))
        conn.commit()
    conn.close()

# === [3] MESIN PENCARI ===
def cari_kbbi(kata):
    try:
        headers={"User-Agent":"Mozilla/5.0"}
        r=requests.get(f"https://kbbi.kemdikbud.go.id/entri/{kata}", headers=headers, timeout=8)
        if r.status_code==200 and "tidak ditemukan" not in r.text.lower():
            soup=BeautifulSoup(r.text,'html.parser')
            ol=soup.find('ol')
            if ol and ol.find('li'):
                arti=ol.find('li').get_text(" ", strip=True)[:500]
                return {"bahasa":"Indonesia","jenis":"nomina/verba","arti":arti,"kapan":f"Kata baku, dipakai formal untuk makna '{kata}'","contoh":f"Penggunaan kata {kata} dalam kalimat baku","sumber":"kbbi.kemdikbud.go.id"}
        r2=requests.get(f"https://kbbi.web.id/{kata}", headers=headers, timeout=8)
        if r2.status_code==200:
            soup2=BeautifulSoup(r2.text,'html.parser')
            d=soup2.find('div', id='d1')
            if d: return {"bahasa":"Indonesia","jenis":"kata baku","arti":d.get_text(" ", strip=True)[:500],"kapan":"Dipakai di tulisan resmi","contoh":"-","sumber":"kbbi.web.id"}
    except: pass
    return None

def cari_english(kata):
    try:
        r=requests.get(f"https://api.dictionaryapi.dev/api/v2/entries/en/{kata}", timeout=8)
        if r.status_code==200:
            data=r.json()[0]; meaning=data['meanings'][0]; defi=meaning['definitions'][0]
            return {"bahasa":"Inggris","jenis":meaning.get('partOfSpeech',''),"arti":defi.get('definition','-'),"kapan":f"Sebagai {meaning.get('partOfSpeech')} dalam bahasa Inggris","contoh":defi.get('example','-'),"sumber":"dictionaryapi"}
    except: pass
    return None

def cari_wikipedia(kata):
    try:
        r=requests.get(f"https://id.wikipedia.org/api/rest_v1/page/summary/{kata}", headers={"User-Agent":"Mozilla/5.0"}, timeout=8)
        if r.status_code==200:
            j=r.json()
            if j.get('extract'): return j['extract'][:600]
    except: pass
    return None

def simpan_kata(kata, data):
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("INSERT OR REPLACE INTO kamus VALUES (?,?,?,?,?,?,?,?)",
              (kata, data['bahasa'], data['jenis'], encode(data['arti']), encode(data['kapan']), encode(data['contoh']), data['sumber'], datetime.now().strftime("%Y-%m-%d")))
    conn.commit(); conn.close()

def cek_kamus(kata):
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("SELECT * FROM kamus WHERE kata=?", (kata,)); row=c.fetchone(); conn.close()
    if row: return (row[0], row[1], row[2], decode(row[3]), decode(row[4]), decode(row[5]), row[6])
    return None

def cek_pengetahuan(q):
    conn=sqlite3.connect(DB_PATH); c=conn.cursor()
    c.execute("SELECT jawaban FROM pengetahuan WHERE kunci=?", (q.lower().strip(),))
    row=c.fetchone()
    if row:
        conn.close()
        return decode(row[0])
    # cari mirip
    for kunci in BUILTIN_QA.keys():
        if kunci in q.lower():
            conn.close()
            return cek_pengetahuan(kunci)
    conn.close()
    return None

# === [4] OTAK AI YANG JAWAB PERTANYAAN ===
STOPWORDS={'yang','dan','itu','ini','apa','bagaimana','kapan','untuk','dengan','adalah','saya','kamu','di','ke','dari','apa','aja','sih','bro','bang'}

def extract_keyword(prompt):
    p=prompt.lower()
    for pat in ["apa arti","arti kata","apa itu","apa maksud","jelaskan","what is","definisi"]:
        if pat in p:
            sisa=p.split(pat)[-1].strip()
            sisa=re.sub(r'[^a-zA-Z ]','',sisa).strip()
            if sisa: return sisa.split()[0]
    words=re.findall(r'\b[a-z]{3,}\b', p)
    words=[w for w in words if w not in STOPWORDS]
    return max(words, key=len) if words else None

def proses_belajar_semua_kata(prompt):
    kata_kata=re.findall(r'\b[a-zA-Z]{3,}\b', prompt.lower())
    baru=0
    for k in set(kata_kata):
        if k in STOPWORDS or len(k)<3: continue
        if cek_kamus(k): continue
        data=cari_kbbi(k)
        if not data: data=cari_english(k)
        if data:
            simpan_kata(k,data)
            baru+=1
            time.sleep(0.2)
    return baru

def ai_jawab(prompt):
    # 1. cek pengetahuan bawaan dulu
    jwb=cek_pengetahuan(prompt)
    if jwb: return jwb

    # 2. kalo nanya arti kata
    keyword=extract_keyword(prompt)
    if not keyword: return "Menarik, aku catat itu. Coba tanya lebih spesifik kayak 'apa itu "+prompt.split()[-1]+"'?"

    # cek di kamus hidden
    row=cek_kamus(keyword)
    if row:
        return f"Kata **{row[0]}** [{row[1]} | fungsi: {row[2]}]\nArti: {row[3]}\nKapan dipakai: {row[4]}\nContoh: {row[5]}"

    # 3. kalo gak ada, cari online terus simpen
    print(f"\033[90m [AI lagi mikir, nyari '{keyword}' di KBBI & Wikipedia...]\033[0m")
    data=cari_kbbi(keyword)
    if not data: data=cari_english(keyword)
    wiki=cari_wikipedia(keyword)

    if data:
        simpan_kata(keyword, data)
        jawaban=f"Menurut database ku (baru aku pelajari):\n**{keyword}** adalah {data['arti']}\nFungsi katanya sebagai {data['jenis']}. {data['kapan']}"
        if wiki: jawaban+=f"\n\nPenjelasan tambahan: {wiki}"
        return jawaban
    elif wiki:
        # simpen wiki sebagai pengetahuan
        conn=sqlite3.connect(DB_PATH); c=conn.cursor()
        c.execute("INSERT OR REPLACE INTO pengetahuan VALUES (?,?,?)",(keyword, encode(wiki), datetime.now().strftime("%Y-%m-%d")))
        conn.commit(); conn.close()
        return f"{keyword.capitalize()}: {wiki}"
    else:
        return f"Aku belum nemu arti '{keyword}' di database hidden ku maupun online. Coba pakai kata lain? Tapi kata itu sudah aku tandai dan akan aku pelajari nanti."

def main():
    init_storage()
    clear()
    print("\033[92m╔══════════════════════════════╗\n║ KAMUS AI - HIDDEN CORE ║\n║ DB: Hidden & Encrypted ║\n╚══════════════════════════════╝\033[0m")
    print("Ketik pertanyaan bebas. Contoh: 'apa itu fotosintesis' | '/exit' untuk keluar & auto-clear\n")
    while True:
        try:
            prompt=input("\033[93mKamu:\033[0m ").strip()
            if not prompt: continue
            if prompt.lower() in ["/exit","exit","keluar"]:
                print("Clearing..."); time.sleep(0.5); clear(); break

            # belajar diam-diam semua kata
            proses_belajar_semua_kata(prompt)
            # jawab
            jawaban=ai_jawab(prompt)
            print(f"\n\033[96mAI:\033[0m {jawaban}\n")
        except KeyboardInterrupt:
            clear(); break

if __name__=="__main__":
    main()
