#!/usr/bin/env python3
"""Breeze klasör simgelerini Atmaca'ya uyarlar (Fedora KDE'deki Breeze'nin hafif değiştirilmiş hali).

Breeze'de klasörün rengi sistemin vurgu renginden gelir (ColorScheme-Accent), içindeki
çizim (ev, nota, resim...) ise yazı renginden (ColorScheme-Text): açık temada koyu, koyu
temada açık. Atmaca'da çizim her iki temada da beyaz olsun diye yalnızca o parçayı
değiştiriyoruz; şekil, boyut ve diğer her şey Breeze'nin aynısı kalır.
16 ve 22 piksellik tek renkli küçük simgelere dokunulmaz (KDE'de yazı rengini izlemeleri doğru).

Kullanım: python3 tarifler/breeze-klasor.py <breeze/places klasörü> <tema klasörü>...
"""
import os
import re
import shutil
import sys

BOYUTLAR = ("32", "48", "64", "96")
ETIKET = re.compile(r"<path\b[^>]*>", re.S)


def uyarla(svg):
    def cevir(m):
        etiket = m.group(0)
        if "ColorScheme-Text" in etiket and "fill-opacity:0.6" in etiket:
            etiket = etiket.replace('class="ColorScheme-Text"', "")
            etiket = re.sub(r'style="[^"]*"', 'style="fill:#ffffff;fill-opacity:0.92;stroke:none"', etiket)
        return etiket
    # Vurgu renginin KDE dışı uygulamalardaki (GTK vb.) yedek değeri: Atmaca mavisi
    return ETIKET.sub(cevir, svg).replace("#3daee9", "#3b82f6")


def main():
    kaynak, temalar = sys.argv[1], sys.argv[2:]
    sayi = 0
    for boyut in BOYUTLAR:
        for ad in sorted(os.listdir(os.path.join(kaynak, boyut))):
            if not (ad.startswith("folder") or ad.startswith("user-")) or not ad.endswith(".svg"):
                continue
            yol = os.path.join(kaynak, boyut, ad)
            for tema in temalar:
                hedef_kl = os.path.join(tema, "places", boyut)
                os.makedirs(hedef_kl, exist_ok=True)
                hedef = os.path.join(hedef_kl, ad)
                if os.path.lexists(hedef):
                    os.remove(hedef)
                if os.path.islink(yol):
                    # Breeze'deki kısayollar (ör. folder-music -> folder-sound) aynen korunur
                    os.symlink(os.readlink(yol), hedef)
                else:
                    with open(yol) as f:
                        icerik = f.read()
                    with open(hedef, "w") as f:
                        f.write(uyarla(icerik))
            sayi += 1
    print(f"{sayi} Breeze klasör simgesi uyarlandı -> {', '.join(temalar)}")


if __name__ == "__main__":
    main()
