#!/data/data/com.termux/files/usr/bin/python
import os, re, sqlite3, requests, json, time
from datetime import datetime
from bs4 import BeautifulSoup

DB_NAME = "ai_database.db"

def clear():
    os.system("clear")

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS kamus (
        kata TEXT PRIMARY KEY,
        bahasa TEXT,
        jenis_kata TEXT,
        arti TEXT,
        kapan_digunakan TEXT,
        contoh TEXT,
        sumber TEXT,
        tgl TEXT
    )''')
    conn.commit()
    conn.close()

def cari_kbbi(kata):
    try:
        # Coba source 1: kbbi.kemdikbud
        url = f"https://kbbi.kemdikbud.go.id/entri/{kata}"
        headers = {"User-Agent": "Mozilla/5.0"}
        r = requests.get(url, headers=headers, timeout=10)
        if r.status_code == 200 and "tidak ditemukan" not in r.text.lower():
            soup = BeautifulSoup(r.text, 'html.parser')
            # Ambil definisi di dalam <ol><li>
            ol = soup.find('ol')
            if ol:
                li = ol.find('li')
                arti = li.get_text(" ", strip=True)[:500] if li else ""
                # Cari jenis kata biasanya ada di dalam <span> atau teks seperti n, v, a
                full_text = soup.get_text()
                jenis = "nomina" if " n " in full_text.lower() else "verba" if " v " in full_text.lower() else "kata"
                return {
                    "bahasa": "Indonesia",
                    "jenis_kata": jenis,
                    "arti": arti,
                    "kapan": f"Digunakan saat konteks formal / sesuai makna KBBI dari '{kata}'",
                    "contoh": f"Contoh penggunaan kata {kata} dalam kalimat baku.",
                    "sumber": url
                }

        # Coba source 2: kbbi.web.id (lebih ringan)
        url2 = f"https://kbbi.web.id/{kata}"
        r2 = requests.get(url2, headers=headers, timeout=10)
        if r2.status_code == 200:
            soup2 = BeautifulSoup(r2.text, 'html.parser')
            definisi = soup2.find('div', id='d1')
            if definisi:
                arti = definisi.get_text(" ", strip=True)[:500]
                return {
                    "bahasa": "Indonesia",
                    "jenis_kata": "kata baku",
                    "arti": arti,
                    "kapan": f"Kata baku Indonesia, dipakai di tulisan formal/resmi.",
                    "contoh": "-",
                    "sumber": url2
                }
    except Exception as e:
        pass
    return None

def cari_english(kata):
    try:
        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{kata}"
        r = requests.get(url, timeout=10)
        if r.status_code == 200:
            data = r.json()[0]
            meaning = data['meanings'][0]
            definition = meaning['definitions'][0]
            return {
                "bahasa": "Inggris",
                "jenis_kata": meaning.get('partOfSpeech', 'unknown'), # ini fungsi katanya: noun, verb, adjective
                "arti": definition.get('definition', '-'),
                "kapan": f"Digunakan sebagai {meaning.get('partOfSpeech')} dalam kalimat bahasa Inggris.",
                "contoh": definition.get('example', f"Example using {kata}"),
                "sumber": "dictionaryapi.dev"
            }
    except:
        pass
    return None

def simpan_kata(kata, data):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("INSERT OR REPLACE INTO kamus VALUES (?,?,?,?,?,?,?,?)",
              (kata, data['bahasa'], data['jenis_kata'], data['arti'], data['kapan'], data['contoh'], data['sumber'], datetime.now().strftime("%Y-%m-%d")))
    conn.commit()
    conn.close()

def cek_db(kata):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT * FROM kamus WHERE kata=?", (kata,))
    row = c.fetchone()
    conn.close()
    return row

def proses_belajar(prompt):
    # Ambil semua kata, minimal 3 huruf, hilangkan angka/simbol
    kata_kata = re.findall(r'\b[a-zA-Z]{3,}\b', prompt.lower())
    kata_unik = list(set(kata_kata))
    # Filter stopword simple biar gak spam
    stopword = {'yang','dan','itu','ini','apa','bagaimana','kapan','untuk','dengan','adalah','saya','kamu','apa','aja','sih','bang','bro'}
    baru = 0
    for k in kata_unik:
        if k in stopword: continue
        if cek_db(k): continue

        print(f" [>_<] kata baru terdeteksi: '{k}' -> lagi nyari di kamus...")
        data = cari_kbbi(k)
        if not data:
            data = cari_english(k)

        if data:
            simpan_kata(k, data)
            print(f" -> tersimpan! ({data['bahasa']} | {data['jenis_kata']})")
            baru += 1
        time.sleep(0.5) # biar gak di block
    return baru, kata_unik

def banner():
    print("\033[92m")
    print("╔════════════════════════════════════╗")
    print("║ KAMUS AI - TERMUX EDITION ║")
    print("║ Auto-learn dari KBBI & Dict ║")
    print("╚════════════════════════════════════╝\033[0m")
    print("Perintah: /db = lihat database | /cari [kata] | /exit = keluar & clear\n")

def main():
    init_db()
    clear()
    banner()

    while True:
        try:
            prompt = input("\033[93mKamu:\033[0m ").strip()
            if not prompt: continue

            if prompt.lower() in ["/exit","exit","keluar"]:
                print("\nMembersihkan terminal...")
                time.sleep(0.8)
                clear()
                break

            if prompt.startswith("/db"):
                conn = sqlite3.connect(DB_NAME)
                c = conn.cursor()
                c.execute("SELECT kata, bahasa, jenis_kata FROM kamus ORDER BY tgl DESC LIMIT 20")
                rows = c.fetchall()
                print(f"\n\033[96m[DATABASE] Total {len(rows)} kata terakhir:\033[0m")
                for r in rows: print(f" - {r[0]} [{r[1]} | {r[2]}]")
                conn.close()
                continue

            if prompt.startswith("/cari "):
                kata = prompt.split(" ")[1].lower()
                row = cek_db(kata)
                if row:
                    print(f"\n\033[96mKata: {row[0]}\nBahasa: {row[1]}\nFungsi/Jenis: {row[2]}\nArti: {row[3]}\nKapan Dipakai: {row[4]}\nContoh: {row[5]}\033[0m\n")
                else:
                    print("Belum ada di database, coba ketik kata itu di chat biasa biar aku pelajari.")
                continue

            # === MODE BELAJAR OTOMATIS ===
            baru, semua_kata = proses_belajar(prompt)

            # === MODE JAWAB ===
            # Cek apakah user nanya arti kata
            row_terkait = None
            for k in semua_kata:
                r = cek_db(k)
                if r:
                    row_terkait = r
                    break

            print("\n\033[92mAI:\033[0m ", end="")
            if baru > 0:
                print(f"Aku baru aja belajar {baru} kata baru dari kalimat kamu! Database ku update. ")
            if row_terkait:
                print(f"Kata kunci '{row_terkait[0]}' itu fungsinya sebagai {row_terkait[2]} ({row_terkait[1]}). Artinya: {row_terkait[3]}")
                print(f" -> Kapan dipakai: {row_terkait[4]}")
                if row_terkait[5]!= "-": print(f" -> Contoh: {row_terkait[5]}")
            else:
                print("Oke noted, kalimat kamu sudah aku proses. Tanya aja '/cari [kata]' kalau mau detail arti kata yang sudah aku simpan.")
            print("")

        except KeyboardInterrupt:
            clear()
            break

if __name__ == "__main__":
    main()
