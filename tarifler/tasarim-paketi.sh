#!/usr/bin/env bash
# Onay için tasarım paketi: marka/varlik + renk şemaları + sistemde nasıl görüneceklerini
# gösteren önizlemeler -> teslim/atmaca-tasarim.zip
# Fedora 44 kabında çalışır:  podman run --rm -v $PWD:/a -w /a fedora:44 bash tarifler/tasarim-paketi.sh
set -euo pipefail
rpm -q ImageMagick zip >/dev/null 2>&1 || dnf -y -q install ImageMagick zip >/dev/null
V=marka/varlik; P=teslim/atmaca-tasarim; rm -rf teslim; mkdir -p $P/{logo,duvar-kagitlari,onizleme,kde-renk-semalari}
K=$V/yazi/Poppins-SemiBold.ttf; I=$V/yazi/Poppins-Regular.ttf
LACI0='#0D1B2A'; LACI1='#1B263B'; MAVI='#2563EB'; ACIKMAVI='#60A5FA'; GRI='#A8B2BD'; BEYAZ='#E2E8F0'

cp $V/logo.png $P/logo/atmaca-simge-1024.png
for s in 16 32 48 64 128 256 512; do cp $V/logo-$s.png $P/logo/atmaca-simge-$s.png; done
cp $V/logo-yazili-koyu.png $P/logo/atmaca-yazili-koyu-zemin.png
cp $V/logo-yazili-acik.png $P/logo/atmaca-yazili-acik-zemin.png
cp $V/duvar/*.jpg $P/duvar-kagitlari/
cp marka/kde/renk/*.colors $P/kde-renk-semalari/
cp -r marka/simge $P/simge-temasi

# Simge seti: Breeze'nin kendi simgeleri (vurgu rengi Atmaca mavisi) + Atmaca'ya özel olanlar.
# KDE, Breeze simgelerinin içindeki çizimi renk şemasının yazı rengiyle boyar: koyu temada
# açık, açık temada koyu. Önizleme de bunu taklit eder.
# BREEZE=<breeze-icon-theme açılmış klasörü> verilirse KDE simgeleri de önizlemeye girer.
rpm -q librsvg2-tools >/dev/null 2>&1 || dnf -y -q install librsvg2-tools >/dev/null
S=marka/simge/Atmaca/scalable
simgeler() { # $1=yazı rengi (Breeze'deki #232629 yerine) $2=zemin $3=etiket rengi $4=çıktı
  local d=/tmp/sg-$RANDOM i=0; mkdir -p $d
  ekle() { rsvg-convert -w 96 -h 96 "$1" -o $d/$(printf %02d $i).png; echo "$2" > $d/$(printf %02d $i).txt; i=$((i+1)); }
  if [ -n "${BREEZE:-}" ]; then
    for f in "places/64/user-home:Ev" "places/64/user-desktop:Masaüstü" "places/64/folder-documents:Belgeler" \
      "places/64/folder-download:İndirilenler" "places/64/folder-music:Müzikler" "places/64/folder-pictures:Resimler" \
      "places/64/folder-videos:Videolar" "places/64/user-trash:Çöp" "apps/48/preferences-system:Ayarlar" \
      "apps/48/utilities-terminal:Uçbirim" "apps/48/system-file-manager:Dosyalar" "apps/48/plasmadiscover:Yazılım Merkezi" \
      "apps/48/system-software-update:Güncelleme"; do
      k=$BREEZE/${f%%:*}.svg; case $f in places/*) k=/tmp/atmaca-klasor/places/64/$(basename $k);; esac
      sed "s/#3daee9/#3b82f6/Ig; s/#232629/$1/Ig" "$(readlink -f $k)" > $d/k.svg
      ekle $d/k.svg "${f##*:}"
    done
  fi
  for f in "atmaca-hakkinda:Hakkımızda" "atmaca-yardim:Yardım" "atmaca-topluluk:Topluluk" "atmaca-bagis:Bağış" \
    "atmaca-guvenlik:Güvenlik" "atmaca-guncelleme:Yenilikler" "atmaca-depo:Depo" "atmaca-kurulum:Kurulum" \
    "atmaca-canli-usb:Canlı USB"; do ekle $S/apps/${f%%:*}.svg "${f##*:}"; done
  ekle $S/places/start-here.svg "Uygulama menüsü"
  local args=(); for p in $d/*.png; do args+=(-label "$(cat ${p%.png}.txt)" "$p"); done
  magick montage -font $I -pointsize 15 -fill "$3" -background "$2" "${args[@]}" \
    -tile 8x -geometry 120x120+14+10 "$4"
}
mkdir -p $P/onizleme
[ -n "${BREEZE:-}" ] && python3 tarifler/breeze-klasor.py $BREEZE/places /tmp/atmaca-klasor
simgeler "#fcfcfc" "$LACI0" "$BEYAZ" $P/onizleme/8-simgeler-koyu.png
simgeler "#232629" "$BEYAZ" "$LACI0" $P/onizleme/9-simgeler-acik.png

O=$P/onizleme
# 1) KDE açılış ekranı (splash): koyu zemin + yazılı logo + ilerleme çubuğu
magick $V/koyu-zemin.jpg \( $V/logo-yazili-koyu.png -resize x340 \) -gravity center -geometry +0-40 -composite \
  -fill "$LACI1" -draw "roundrectangle 810,760 1110,764 2,2" \
  -fill "$MAVI"  -draw "roundrectangle 810,760 990,764 2,2" $O/1-kde-acilis-ekrani.png

# 2) Plymouth (bilgisayar açılırken, KDE'den önce): düz lacivert + logo + yükleniyor noktaları
magick -size 1920x1080 xc:"$LACI0" \( $V/logo-yazili-koyu.png -resize x300 \) -gravity center -geometry +0-60 -composite \
  -fill "$MAVI" -draw "circle 930,820 936,820" -fill "$ACIKMAVI" -draw "circle 960,820 966,820" \
  -fill "$GRI" -draw "circle 990,820 996,820" $O/2-plymouth-acilis.png

# 3) Giriş ekranı: koyu duvar kâğıdı + kullanıcı + parola kutusu
magick $V/koyu-zemin.jpg -fill "rgba(13,27,42,0.35)" -draw "rectangle 0,0 1920,1080" \
  \( $V/logo-128.png \) -gravity north -geometry +0+250 -composite \
  -gravity northwest -fill "$LACI1" -stroke "$ACIKMAVI" -strokewidth 2 -draw "circle 960,500 960,440" -stroke none \
  -fill "$GRI" -draw "circle 960,485 960,463" -draw "ellipse 960,535 40,25 180,360" \
  -fill "rgba(27,38,59,0.9)" -draw "roundrectangle 810,600 1110,644 8,8" -draw "roundrectangle 810,660 1110,704 8,8" \
  -fill "$MAVI" -draw "roundrectangle 810,724 1110,768 8,8" \
  -font $I -pointsize 20 -fill "$GRI" -annotate +830+611 "kullanıcı" -annotate +830+671 "••••••••" \
  -font $K -fill white -gravity north -annotate +0+734 "Giriş Yap" $O/3-giris-ekrani.png

# 4) Kilit ekranı: gece duvar kâğıdı + saat
magick $V/duvar/Atmaca-Gece-1920x1080.jpg -gravity center -font $K -pointsize 140 -fill "$BEYAZ" -annotate +0-120 "15:30" \
  -font $I -pointsize 34 -fill "$ACIKMAVI" -annotate +0+0 "Çarşamba, 29 Ekim" $O/4-kilit-ekrani.png

# 5) Masaüstü taslağı: duvar kâğıdı + yüzen alt panel
magick $V/duvar/Atmaca-1920x1080.jpg \
  -fill "rgba(13,27,42,0.88)" -draw "roundrectangle 360,1000 1560,1060 14,14" \
  \( $V/logo-48.png \) -gravity northwest -geometry +380+1006 -composite \
  -fill "$MAVI" -draw "roundrectangle 450,1012 486,1048 6,6" -fill "#F59E0B" -draw "roundrectangle 500,1012 536,1048 6,6" \
  -fill "$LACI1" -draw "roundrectangle 550,1012 586,1048 6,6" -fill "$ACIKMAVI" -draw "roundrectangle 600,1012 636,1048 6,6" \
  -fill "$GRI" -draw "roundrectangle 650,1012 686,1048 6,6" \
  -font $K -pointsize 22 -fill "$BEYAZ" -annotate +1450+1016 "15:30" $O/5-masaustu-taslak.png

# 6) Renk paleti
magick -size 1400x420 xc:"$LACI0" -font $K -pointsize 40 -fill "$BEYAZ" -annotate +60+80 "Atmaca renk paleti" /tmp/p.png
x=60; for r in "#0D1B2A" "#1B263B" "#1E3A8A" "#2563EB" "#60A5FA" "#A8B2BD" "#E2E8F0"; do
  magick /tmp/p.png -fill "$r" -stroke "#2b3a52" -draw "roundrectangle $x,130 $((x+160)),290 14,14" -stroke none \
    -font $I -pointsize 26 -fill "$GRI" -annotate +$((x+20))+340 "$r" /tmp/p.png; x=$((x+185)); done
cp /tmp/p.png $O/6-renk-paleti.png

# 7) Simge boyutları (gerçek boyutlarda, açık ve koyu zeminde)
magick -size 900x300 xc:"$LACI0" /tmp/s.png; magick -size 900x300 xc:"$BEYAZ" /tmp/s2.png
x=40; for s in 16 22 32 48 64 128 256; do
  magick /tmp/s.png \( $V/logo-$s.png \) -gravity northwest -geometry +$x+$((150-s/2)) -composite /tmp/s.png
  magick /tmp/s2.png \( $V/logo-$s.png \) -gravity northwest -geometry +$x+$((150-s/2)) -composite /tmp/s2.png
  x=$((x+s+40)); done
magick /tmp/s.png /tmp/s2.png -append $O/7-simge-boyutlari.png

# 8) Hepsi tek sayfada
magick \( $O/1-kde-acilis-ekrani.png $O/2-plymouth-acilis.png -resize 800x +append \) \
       \( $O/3-giris-ekrani.png $O/4-kilit-ekrani.png -resize 800x +append \) \
       \( $O/5-masaustu-taslak.png $V/duvar/Atmaca-Gece-1920x1080.jpg -resize 800x +append \) \
       \( $V/duvar/Atmaca-Koyu-1920x1080.jpg $V/duvar/Atmaca-Acik-1920x1080.jpg -resize 800x +append \) \
       -append $P/00-genel-bakis.jpg

cp marka/TASARIM.md $P/OKU-BENI.md
(cd teslim && zip -qr atmaca-tasarim.zip atmaca-tasarim)
ls -la teslim
