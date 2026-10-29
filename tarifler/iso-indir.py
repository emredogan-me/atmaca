#!/usr/bin/env python3
"""GitHub'daki ISO'yu zip'i indirmeden, doğrudan .iso olarak indirir.

GitHub artifact'leri zip'tir. Bizim iş akışı ISO'yu sıkıştırmadan (compression-level: 0)
koyduğu için ISO zip'in içinde olduğu gibi durur. Bu betik zip'in yalnızca içindekiler
listesini ve ISO'nun baytlarını (HTTP Range ile parça parça) indirir; diske tek kopya yazılır.
Bağlantı koparsa kaldığı yerden devam eder; sonunda SHA256 ile doğrular.

Kullanım: python3 tarifler/iso-indir.py <artifact_id> <hedef klasör>
Jeton (token) ~/.git-credentials dosyasından okunur.
"""
import hashlib
import io
import os
import re
import sys
import time
import urllib.request
import zipfile

DEPO = "emredogan-me/atmaca"
PARCA = 16 * 1024 * 1024  # her istekte 16 MB


def jeton():
    for satir in open(os.path.expanduser("~/.git-credentials")):
        m = re.match(r"https://[^:]*:([^@]*)@github.com", satir.strip())
        if m:
            return m.group(1)
    sys.exit("~/.git-credentials içinde GitHub jetonu yok")


def indirme_adresi(artifact):
    """GitHub API, asıl dosyanın geçici (imzalı) adresine yönlendirir; o adresi alırız."""
    istek = urllib.request.Request(
        f"https://api.github.com/repos/{DEPO}/actions/artifacts/{artifact}/zip",
        headers={"Authorization": f"Bearer {jeton()}"})

    class Durdur(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *a, **k):
            return None
    try:
        urllib.request.build_opener(Durdur).open(istek)
    except urllib.error.HTTPError as h:
        if h.code in (301, 302, 303, 307, 308):
            return h.headers["Location"]
        raise
    sys.exit("Yönlendirme gelmedi")


class UzakDosya(io.RawIOBase):
    """HTTP Range ile okunan, zipfile'ın 'dosya' sandığı nesne. Hatada bekleyip yeniden dener."""

    def __init__(self, adres_al):
        self.adres_al, self.adres = adres_al, adres_al()
        self.konum, self.boyut = 0, None
        self.boyut = int(self._iste(0, 0)[1].split("/")[-1])

    def _iste(self, bas, son):
        for deneme in range(30):
            try:
                r = urllib.request.urlopen(urllib.request.Request(
                    self.adres, headers={"Range": f"bytes={bas}-{son}"}), timeout=60)
                return r.read(), r.headers.get("Content-Range", "")
            except urllib.error.HTTPError as e:
                if e.code == 403:
                    # GitHub'ın verdiği geçici indirme adresinin süresi (~10 dk) doldu: yenisini al
                    print(f"\n{time.strftime('%X')} indirme adresinin süresi doldu, yenisi alınıyor", flush=True)
                    self.adres = self.adres_al()
                    continue
                print(f"\n{time.strftime('%X')} bağlantı sorunu ({e}); {10 * (deneme + 1)} sn sonra yeniden",
                      flush=True)
                time.sleep(10 * (deneme + 1))
                continue
            except Exception as e:
                print(f"\n{time.strftime('%X')} bağlantı sorunu ({e}); {10 * (deneme + 1)} sn sonra yeniden",
                      flush=True)
                time.sleep(10 * (deneme + 1))
                if deneme % 5 == 4:
                    self.adres = self.adres_al()  # imzalı adresin süresi dolmuş olabilir
        sys.exit("30 denemede indirilemedi")

    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self.konum

    def seek(self, k, nereden=0):
        self.konum = {0: k, 1: self.konum + k, 2: self.boyut + k}[nereden]
        return self.konum

    def readinto(self, b):
        if self.konum >= self.boyut:
            return 0
        son = min(self.konum + len(b), self.boyut) - 1
        veri, _ = self._iste(self.konum, son)
        b[:len(veri)] = veri
        self.konum += len(veri)
        return len(veri)


def main():
    artifact, hedef = sys.argv[1], sys.argv[2]
    zf = zipfile.ZipFile(io.BufferedReader(UzakDosya(lambda: indirme_adresi(artifact)), PARCA))
    iso = next(i for i in zf.infolist() if i.filename.endswith(".iso"))
    beklenen = None
    toplamlar = next((i for i in zf.infolist() if i.filename.endswith("SHA256SUMS")), None)
    if toplamlar:
        for satir in zf.read(toplamlar).decode().splitlines():
            if satir.strip().endswith(os.path.basename(iso.filename)):
                beklenen = satir.split()[0]
    yol = os.path.join(hedef, os.path.basename(iso.filename))
    # Önce geçici adla indir: aynı adlı eski bir ISO varsa onun üstüne asla yazılmaz,
    # kaldığı yerden devam da yalnızca bu geçici dosyadan yapılır
    gecici = yol + ".indiriliyor"
    print(f"{iso.filename}: {iso.file_size / 1024**3:.2f} GB -> {yol}")
    if iso.compress_type != zipfile.ZIP_STORED:
        sys.exit("ISO zip içinde sıkıştırılmış; bu yöntem yalnızca sıkıştırılmamışta çalışır")

    mevcut = os.path.getsize(gecici) if os.path.exists(gecici) else 0
    if mevcut > iso.file_size:
        mevcut = 0
    with zf.open(iso) as kaynak, open(gecici, "r+b" if mevcut else "wb") as cikti:
        if mevcut:
            print(f"Kaldığı yerden devam: {mevcut / 1024**3:.2f} GB zaten inmiş")
            kaynak.seek(mevcut)
            cikti.seek(mevcut)
        bas, inen = time.time(), 0
        while True:
            parca = kaynak.read(PARCA)
            if not parca:
                break
            cikti.write(parca)
            inen += len(parca)
            simdi = mevcut + inen
            hiz = inen / max(time.time() - bas, 1)
            kalan = (iso.file_size - simdi) / max(hiz, 1)
            print(f"\r{simdi / 1024**3:5.2f} / {iso.file_size / 1024**3:.2f} GB  "
                  f"%{100 * simdi / iso.file_size:4.1f}  {hiz / 1024**2:5.2f} MB/sn  "
                  f"kalan ~{kalan / 60:4.0f} dk", end="", flush=True)
    print("\nİndi, doğrulanıyor...")
    h = hashlib.sha256()
    with open(gecici, "rb") as f:
        for blok in iter(lambda: f.read(PARCA), b""):
            h.update(blok)
    if beklenen and h.hexdigest() != beklenen:
        os.remove(gecici)
        sys.exit(f"SHA256 TUTMADI: {h.hexdigest()} (beklenen {beklenen}); bozuk dosya silindi")
    os.replace(gecici, yol)
    print(f"TAMAM: {yol} doğrulandı (SHA256 {h.hexdigest()})")


if __name__ == "__main__":
    main()
