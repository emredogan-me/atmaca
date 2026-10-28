#!/usr/bin/env python3
"""Atmaca simge temasını üretir: marka/simge/Atmaca (açık) ve Atmaca-Koyu.

İlke: KDE ile tam uyum. Klasörler, çöp, ayarlar, uçbirim gibi bütün genel simgeler
KDE'nin Breeze temasından gelir (index.theme: Inherits). Breeze klasörleri rengini
sistemin vurgu renginden aldığı için Atmaca mavisinde görünür.
Biz yalnızca Atmaca'ya özel simgeleri çiziyoruz, o da Breeze'nin kurallarıyla:
48x48 alanda neredeyse keskin köşeli kare, hafif çapraz geçiş, üstte 1px açık /
altta 1px koyu çizgi, işaretten sağ alt köşeye uzanan uzun gölge.

Kullanım: python3 tarifler/simge-uret.py
"""
import base64
import os
import shutil

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "marka", "simge")

# Atmaca paleti
LACI0, LACI1, DERIN, MAVI, ACIK, GRI, BEYAZ = (
    "#0D1B2A", "#1B263B", "#1E3A8A", "#3B82F6", "#60A5FA", "#A8B2BD", "#E2E8F0")

# 24x24 çizimler (çizgi tarzı; dolu parçalar "D:" ile başlar)
CIZIM = {
    "ev": ["M4 11 L12 4 L20 11", "M6 9.5 V20 H18 V9.5", "M10 20 V14 H14 V20"],
    "masaustu": ["M5 4 H19 A2 2 0 0 1 21 6 V14 A2 2 0 0 1 19 16 H5 A2 2 0 0 1 3 14 V6 A2 2 0 0 1 5 4 Z",
                 "M8 20 H16", "M12 16 V20"],
    "belge": ["M7 3 H14 L18 7 V19 A2 2 0 0 1 16 21 H8 A2 2 0 0 1 6 19 V4 A1 1 0 0 1 7 3 Z",
              "M14 3 V7 H18", "M9.5 12 H14.5", "M9.5 16 H14.5"],
    "indir": ["M12 4 V15", "M7 10 L12 15 L17 10", "M5 19.5 H19"],
    "muzik": ["M9 17 V6 L19 4 V15", "C:7,17,2", "C:17,15,2"],
    "resim": ["M5 5 H19 A2 2 0 0 1 21 7 V17 A2 2 0 0 1 19 19 H5 A2 2 0 0 1 3 17 V7 A2 2 0 0 1 5 5 Z",
              "M3 16 L8 11 L13 16", "M12.5 15 L15.5 12 L21 17", "C:15.5,8.5,1.4"],
    "video": ["M5 6 H14 A2 2 0 0 1 16 8 V16 A2 2 0 0 1 14 18 H5 A2 2 0 0 1 3 16 V8 A2 2 0 0 1 5 6 Z",
              "M16 10.5 L21 7.5 V16.5 L16 13.5"],
    "sablon": ["M4 4 H10 V10 H4 Z", "M14 4 H20 V10 H14 Z", "M4 14 H10 V20 H4 Z", "M14 14 H20 V20 H14 Z"],
    "genel": ["C:12,8,3", "M5.5 20 A6.5 5.5 0 0 1 18.5 20"],
    "cop": ["M4.5 7 H19.5", "M9.5 7 V4.5 H14.5 V7", "M6.5 7 L7.5 20 H16.5 L17.5 7", "M10 11 V16", "M14 11 V16"],
    "cop-dolu": ["M4.5 7 H19.5", "M9.5 7 V4.5 H14.5 V7", "M6.5 7 L7.5 20 H16.5 L17.5 7",
                 "D:M8.2 11 H15.8 L15.3 19 H8.7 Z"],
    "ayarlar": ["C:12,12,3", "M12 3 V5.5", "M12 18.5 V21", "M3 12 H5.5", "M18.5 12 H21",
                "M5.6 5.6 L7.4 7.4", "M16.6 16.6 L18.4 18.4", "M5.6 18.4 L7.4 16.6", "M16.6 7.4 L18.4 5.6",
                "C:12,12,7"],
    "ucbirim": ["M5 4 H19 A2 2 0 0 1 21 6 V18 A2 2 0 0 1 19 20 H5 A2 2 0 0 1 3 18 V6 A2 2 0 0 1 5 4 Z",
                "M7 9 L10 12 L7 15", "M12.5 15 H17"],
    "dosyalar": ["M3 7 A2 2 0 0 1 5 5 H9.5 L11.5 7 H19 A2 2 0 0 1 21 9 V17 A2 2 0 0 1 19 19 H5 A2 2 0 0 1 3 17 Z",
                 "M3 10 H21"],
    "yazilim": ["M6 8 H18 L17 20 H7 Z", "M9 8 V6.5 A3 3 0 0 1 15 6.5 V8", "M10 13 L12 15 L14.5 11.5"],
    "hakkinda": ["C:12,12,9", "M12 11 V16.5", "D:C:12,7.8,1.2"],
    "yardim": ["C:12,12,9", "M9.5 9.5 A2.5 2.5 0 1 1 12.8 11.9 A1.4 1.4 0 0 0 12 13.2 V14", "D:C:12,17,1.2"],
    "topluluk": ["C:9,8.5,3", "C:16.5,9.5,2.4", "M3 20 A6 5.5 0 0 1 15 20", "M14.5 15.2 A5 4.5 0 0 1 21 19.5"],
    "bagis": ["M12 20 L4.6 12.6 A4.4 4.4 0 0 1 12 6.8 A4.4 4.4 0 0 1 19.4 12.6 Z"],
    "guvenlik": ["M12 3 L19 6 V11 C19 15.5 16 18.8 12 21 C8 18.8 5 15.5 5 11 V6 Z", "M9 12 L11 14 L15 10"],
    "guncelleme": ["M19.5 12 A7.5 7.5 0 1 1 17 6.4", "M19.5 3.5 V8 H15"],
    "depo": ["M12 3 L20 7.5 V16.5 L12 21 L4 16.5 V7.5 Z", "M4 7.5 L12 12 L20 7.5", "M12 12 V21"],
    "kurulum": ["M12 3 V12.5", "M8 8.5 L12 12.5 L16 8.5",
                "M5.5 15 H18.5 A1.5 1.5 0 0 1 20 16.5 V19 A1.5 1.5 0 0 1 18.5 20.5 H5.5 A1.5 1.5 0 0 1 4 19 V16.5 A1.5 1.5 0 0 1 5.5 15 Z",
                "D:C:16.5,17.75,0.9"],
    "canli-usb": ["M8.5 3 H15.5 V9 H8.5 Z", "M7 9 H17 V19 A2 2 0 0 1 15 21 H9 A2 2 0 0 1 7 19 Z",
                  "M10.5 5.3 V6.7", "M13.5 5.3 V6.7"],
    "sistem": ["M6 6 H18 V18 H6 Z", "M9.5 9.5 H14.5 V14.5 H9.5 Z", "M9 3 V6", "M15 3 V6", "M9 18 V21",
               "M15 18 V21", "M3 9 H6", "M3 15 H6", "M18 9 H21", "M18 15 H21"],
}

# Simge adı (freedesktop / KDE) -> (biçim, çizim). Aynı çizimi birden çok ad kullanabilir.
UYGULAMA = {
    # Kurucu: Fedora'nın kendi simgesi (breeze-icon-theme-fedora) çıkarıldığı için bizden
    "anaconda": "kurulum", "liveinst": "kurulum", "org.fedoraproject.AnacondaInstaller": "kurulum",
    # Atmaca'ya özel (Hakkımızda, Topluluk, Bağış, Depo... uygulamaları/bağlantıları için)
    "atmaca-hakkinda": "hakkinda", "atmaca-yardim": "yardim", "atmaca-topluluk": "topluluk",
    "atmaca-bagis": "bagis", "atmaca-guvenlik": "guvenlik", "atmaca-guncelleme": "guncelleme",
    "atmaca-depo": "depo", "atmaca-kurulum": "kurulum", "atmaca-canli-usb": "canli-usb",
}
BASLAT = ["start-here", "start-here-kde", "start-here-kde-plasma", "distributor-logo", "atmaca-logo-icon"]


def cizim_svg(ad, renk, kalinlik):
    """24x24 çizimi SVG öğelerine çevirir (çağıran taraf ölçekler/taşır)."""
    parcalar = []
    for p in CIZIM[ad]:
        dolu = p.startswith("D:")
        p = p[2:] if dolu else p
        stil = (f'fill="{renk}" stroke="none"' if dolu else
                f'fill="none" stroke="{renk}" stroke-width="{kalinlik}" stroke-linecap="round" stroke-linejoin="round"')
        if p.startswith("C:"):
            x, y, r = p[2:].split(",")
            parcalar.append(f'<circle cx="{x}" cy="{y}" r="{r}" {stil}/>')
        else:
            parcalar.append(f'<path d="{p}" {stil}/>')
    return "".join(parcalar)


def uygulama(cizim):
    """48x48 Breeze tarzı uygulama simgesi, Atmaca mavisi zemin + beyaz işaret."""
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">'
        '<defs><linearGradient id="z" x1="4" y1="44" x2="44" y2="4" gradientUnits="userSpaceOnUse">'
        f'<stop offset="0" stop-color="#2563EB"/><stop offset="1" stop-color="#60A5FA"/></linearGradient>'
        '<linearGradient id="g" x1="24" y1="24" x2="40" y2="40" gradientUnits="userSpaceOnUse">'
        '<stop offset="0" stop-color="#0D1B2A"/><stop offset="1" stop-color="#0D1B2A" stop-opacity="0"/></linearGradient></defs>'
        '<rect x="4" y="4" width="40" height="40" rx="1" fill="url(#z)"/>'
        '<path d="M24 34 L34 44 H43 A1 1 0 0 0 44 43 V34 L34 24 Z" fill="url(#g)" opacity=".45"/>'
        '<path d="M4 42 V43 A1 1 0 0 0 5 44 H43 A1 1 0 0 0 44 43 V42 A1 1 0 0 1 43 43 H5 A1 1 0 0 1 4 42 Z" opacity=".3"/>'
        '<path d="M4 6 V5 A1 1 0 0 1 5 4 H43 A1 1 0 0 1 44 5 V6 A1 1 0 0 0 43 5 H5 A1 1 0 0 0 4 6 Z" fill="#ffffff" opacity=".3"/>'
        f'<g transform="translate(12 12)">{cizim_svg(cizim, "#FCFCFC", 2)}</g></svg>')


def baslat(logo_png):
    veri = base64.b64encode(open(logo_png, "rb").read()).decode()
    return ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            'width="64" height="64" viewBox="0 0 64 64">'
            f'<image width="64" height="64" xlink:href="data:image/png;base64,{veri}"/></svg>')


def yaz(tema, alt, ad, icerik):
    yol = os.path.join(CIKTI, tema, "scalable", alt)
    os.makedirs(yol, exist_ok=True)
    with open(os.path.join(yol, ad + ".svg"), "w") as f:
        f.write(icerik)


def index_theme(tema, ad, miras, aciklama):
    with open(os.path.join(CIKTI, tema, "index.theme"), "w") as f:
        f.write(f"""[Icon Theme]
Name={ad}
Comment={aciklama}
Inherits={miras},hicolor
Example=folder
DisplayDepth=32
Directories=places/32,places/48,places/64,places/96,scalable/places,scalable/apps

[places/32]
Size=32
Context=Places
Type=Fixed

[places/48]
Size=48
Context=Places
Type=Fixed

[places/64]
Size=64
Context=Places
Type=Fixed

[places/96]
Size=96
Context=Places
Type=Fixed

[scalable/places]
Size=64
MinSize=8
MaxSize=512
Type=Scalable
Context=Places

[scalable/apps]
Size=64
MinSize=8
MaxSize=512
Type=Scalable
Context=Applications
""")


def main():
    shutil.rmtree(CIKTI, ignore_errors=True)
    logo = os.path.join(KOK, "marka", "varlik", "logo-128.png")
    for tema, miras, aciklama in (("Atmaca", "breeze", "Atmaca Linux simgeleri (açık tema)"),
                                  ("Atmaca-Koyu", "breeze-dark", "Atmaca Linux simgeleri (koyu tema)")):
        ad = tema.replace("-", " ")
        for isim, c in UYGULAMA.items():
            yaz(tema, "apps", isim, uygulama(c))
        for isim in BASLAT:
            yaz(tema, "places" if isim.startswith("start-here") else "apps", isim, baslat(logo))
        index_theme(tema, ad, miras, aciklama)
    print("Simge sayısı:", len(UYGULAMA) + len(BASLAT), "x 2 tema ->", CIKTI)


if __name__ == "__main__":
    main()
