#!/usr/bin/env python3
"""Atmaca pencere çerçevesi temalarını üretir (KDE Aurorae): marka/kde/aurorae/Atmaca-{Koyu,Acik}.

Aurorae, KWin'in SVG tabanlı çerçeve altyapısıdır. Bir tema şunlardan oluşur:
  decoration.svg   çerçeve, 9 parçaya bölünmüş (köşeler, kenarlar, orta); KWin parçaları
                   pencere boyutuna göre yerleştirip kenarları uzatır
  close.svg, minimize.svg, maximize.svg, restore.svg
                   düğmeler; her biri durum başına bir öğe içerir (active-center, hover-center...)
  <ad>rc           ölçüler ve yazı renkleri

Çerçeveyi önce tek parça SVG olarak çiziyoruz (gölge + yuvarlak üst köşeli başlık + 1px kenar),
2 kat çözünürlükte PNG'ye çevirip 9 parçaya kesiyor ve her parçayı SVG'ye gömüyoruz; böylece
gölge bulanıklığı her yerde aynı ve yüksek DPI ekranda keskin kalır. Düğmeler saf vektördür.

Kullanım (Fedora kabında, rsvg-convert ve ImageMagick gerekir):
    python3 tarifler/cerceve-uret.py
"""
import base64
import os
import shutil
import subprocess
import tempfile

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "marka", "kde", "aurorae")

P = 14            # gölge payı (her yönde)
R = 8             # başlığın üst köşe yarıçapı
BASLIK = 36       # başlık çubuğu yüksekliği (TitleEdgeTop + TitleHeight + TitleEdgeBottom)
ORTA = 10         # parçaların uzatılan orta şeridi
KAT = 2           # PNG çözünürlük katı

TEMALAR = {
    "Atmaca-Koyu": dict(ad="Atmaca Koyu", baslik="#0D1B2A", baslik_pasif="#111E2E", kenar="#2B3A52",
                        govde="#142133", yazi="226,232,240", yazi_pasif="148,163,184", golge=.55),
    "Atmaca-Acik": dict(ad="Atmaca Açık", baslik="#E2E8F0", baslik_pasif="#EEF2F6", kenar="#B8C2CF",
                        govde="#F1F5F9", yazi="13,27,42", yazi_pasif="100,116,139", golge=.30),
}

# Düğme renkleri (her iki temada aynı): küçült sarı, büyüt yeşil, kapat kırmızı.
# İşaret her zaman beyaz olduğu için tonlar beyazın okunacağı kadar koyu seçildi.
# (normal, üzerine gelince, basınca)
DUGME = {"minimize": ("#E9A30C", "#F5B82E", "#C98A06"), "maximize": ("#1FA347", "#2FBF5A", "#178A3B"),
         "restore": ("#1FA347", "#2FBF5A", "#178A3B"), "close": ("#E5383B", "#F25255", "#C4282B")}
# Windows'taki gibi ince işaretler: 16x16 alanda, dairenin ortasında
ISARET = {
    "minimize": '<path d="M5 8.5 H11"/>',
    "maximize": '<rect x="5.25" y="5.25" width="5.5" height="5.5" rx=".6"/>',
    "restore": '<rect x="4.75" y="6.75" width="4.5" height="4.5" rx=".5"/><path d="M6.75 6.75 V5.4 A.6 .6 0 0 1 7.35 4.8 H10.6 A.6 .6 0 0 1 11.2 5.4 V8.65 A.6 .6 0 0 1 10.6 9.25 H9.25"/>',
    "close": '<path d="M5.5 5.5 L10.5 10.5 M10.5 5.5 L5.5 10.5"/>',
}


def tam_cerceve(t, etkin):
    """Çerçevenin tamamı: gölge, başlık (üst köşeler yuvarlak), gövde ve 1px kenar."""
    g = (P + R) * 2 + ORTA
    y = P + BASLIK + ORTA + 1 + P
    ic_g, ic_y = g - 2 * P, y - 2 * P
    renk = t["baslik"] if etkin else t["baslik_pasif"]
    golge = t["golge"] if etkin else t["golge"] * .55
    sekil = (f"M{P} {P + R} A{R} {R} 0 0 1 {P + R} {P} H{P + ic_g - R} "
             f"A{R} {R} 0 0 1 {P + ic_g} {P + R} V{P + ic_y} H{P} Z")
    # 1px kenar: piksel ortasına denk gelsin diye yarım piksel içeriden çizilir
    a, b, c, d = P + .5, P + .5, P + ic_g - .5, P + ic_y - .5
    kenar = f"M{a} {b + R} A{R - .5} {R - .5} 0 0 1 {a + R} {b} H{c - R} A{R - .5} {R - .5} 0 0 1 {c} {b + R} V{d} H{a} Z"
    return g, y, f'''<svg xmlns="http://www.w3.org/2000/svg" width="{g}" height="{y}" viewBox="0 0 {g} {y}">
<defs><filter id="b" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter></defs>
<path d="{sekil}" transform="translate(0 3)" fill="#000" opacity="{golge}" filter="url(#b)"/>
<path d="{sekil}" fill="{t["govde"]}"/>
<path d="M{P} {P + R} A{R} {R} 0 0 1 {P + R} {P} H{P + ic_g - R} A{R} {R} 0 0 1 {P + ic_g} {P + R} V{P + BASLIK} H{P} Z" fill="{renk}"/>
<path d="{kenar}" fill="none" stroke="{t["kenar"]}" stroke-width="1"/>
</svg>'''


def parcala(svg, g, y, onek, gecici):
    """Tam çerçeveyi 2x PNG'ye çevirip 9 parçaya keser; her parçayı <image> olarak döndürür."""
    kaynak, png = os.path.join(gecici, "c.svg"), os.path.join(gecici, "c.png")
    open(kaynak, "w").write(svg)
    subprocess.run(["rsvg-convert", "-z", str(KAT), kaynak, "-o", png], check=True)
    sol, sag = P + R, P + R
    ust, alt = P + BASLIK, 1 + P
    sutun = [(0, sol), (sol, ORTA), (sol + ORTA, sag)]
    satir = [(0, ust), (ust, ORTA), (ust + ORTA, alt)]
    adlar = [["topleft", "top", "topright"], ["left", "center", "right"],
             ["bottomleft", "bottom", "bottomright"]]
    ogeler, ox = [], 0
    for i, (sy, sh) in enumerate(satir):
        for j, (sx, sw) in enumerate(sutun):
            parca = os.path.join(gecici, "p.png")
            subprocess.run(["magick", png, "-crop", f"{sw * KAT}x{sh * KAT}+{sx * KAT}+{sy * KAT}",
                            "+repage", parca], check=True)
            veri = base64.b64encode(open(parca, "rb").read()).decode()
            # Parçalar SVG içinde yan yana dizilir; KWin her birini kimliğiyle bulur
            ogeler.append(f'<image id="{onek}{adlar[i][j]}" x="{sx + ox}" y="{sy}" width="{sw}" height="{sh}" '
                          f'preserveAspectRatio="none" xlink:href="data:image/png;base64,{veri}"/>')
    return ogeler


def dugme_durumlari(ad):
    """Her durum için düğmenin içeriği: renkli daire + her zaman görünen beyaz işaret."""
    normal, acik, koyu = DUGME[ad]

    def daire(dolgu, isaret_opak=1.0, daire_opak=1.0):
        return (f'<circle cx="8" cy="8" r="7" fill="{dolgu}" opacity="{daire_opak}"/>'
                f'<g fill="none" stroke="#FFFFFF" stroke-opacity="{isaret_opak}" stroke-width="1.3" '
                f'stroke-linecap="round" stroke-linejoin="round">{ISARET[ad]}</g>')

    return {
        "active-center": daire(normal),
        "hover-center": daire(acik),
        "pressed-center": daire(koyu),
        "inactive-center": daire("#64748B", .8, .7),
        "deactivated-center": daire("#64748B", .5, .35),
    }


def dugme(ad):
    ogeler = "".join(f'<g id="{k}" transform="translate({i * 20} 0)">'
                     f'<rect width="16" height="16" fill="none"/>{v}</g>'
                     for i, (k, v) in enumerate(dugme_durumlari(ad).items()))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="100" height="16">{ogeler}</svg>'


def main():
    shutil.rmtree(CIKTI, ignore_errors=True)
    with tempfile.TemporaryDirectory() as gecici:
        for kimlik, t in TEMALAR.items():
            d = os.path.join(CIKTI, kimlik)
            os.makedirs(d)
            g, y, etkin = tam_cerceve(t, True)
            _, _, pasif = tam_cerceve(t, False)
            ogeler = parcala(etkin, g, y, "decoration-", gecici)
            ogeler += parcala(pasif, g, y, "decoration-inactive-", gecici)
            with open(os.path.join(d, "decoration.svg"), "w") as f:
                f.write(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                        f'width="{g}" height="{y}">{"".join(ogeler)}</svg>')
            for ad in DUGME:
                with open(os.path.join(d, f"{ad}.svg"), "w") as f:
                    f.write(dugme(ad))
            with open(os.path.join(d, f"{kimlik}rc"), "w") as f:
                f.write(f"""[General]
ActiveTextColor={t["yazi"]}
InactiveTextColor={t["yazi_pasif"]}
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=150
UseTextShadow=false
Shadow=true
DecorationPosition=0

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
TitleEdgeTop=8
TitleEdgeBottom=8
TitleEdgeLeft=10
TitleEdgeRight=10
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight=20
ButtonWidth=16
ButtonHeight=16
ButtonSpacing=8
ButtonMarginTop=2
ExplicitButtonSpacer=10
PaddingTop={P}
PaddingBottom={P}
PaddingLeft={P}
PaddingRight={P}
""")
            with open(os.path.join(d, "metadata.desktop"), "w") as f:
                f.write(f"""[Desktop Entry]
Name={t["ad"]}
Comment=Atmaca Linux pencere çerçevesi
X-KDE-PluginInfo-Author=Atmaca Linux
X-KDE-PluginInfo-Name={kimlik}
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
X-KDE-PluginInfo-Website=https://github.com/emredogan-me/atmaca
""")
    print("Çerçeve temaları:", ", ".join(TEMALAR), "->", CIKTI)


if __name__ == "__main__":
    main()
