#!/usr/bin/env bash
# Atmaca marka varlıklarını üretir: marka/kaynak/*.png (Figma'da üretilen ham görseller)
# -> marka/varlik/ (sistemde kullanılan son haller).
# Fedora 44 kabında çalışır:  podman run --rm -v $PWD:/a -w /a fedora:44 bash tarifler/varlik-uret.sh
set -euo pipefail
K=marka/kaynak; V=marka/varlik
rpm -q ImageMagick >/dev/null 2>&1 || dnf -y -q install ImageMagick curl >/dev/null
mkdir -p $V/yazi $V/duvar
for a in SemiBold Regular; do
  [ -f $V/yazi/Poppins-$a.ttf ] || curl -sfL -o $V/yazi/Poppins-$a.ttf \
    https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-$a.ttf
done
KALIN=$V/yazi/Poppins-SemiBold.ttf; INCE=$V/yazi/Poppins-Regular.ttf

# Renk paleti (KDE örneğinden)
SLOGAN="özgür • güvenli • milli"   # logonun altındaki yazı
LACI0='#0D1B2A'; MAVI='#2563EB'; ACIKMAVI='#60A5FA'; BEYAZ='#E2E8F0'

# 1) Logo: yeşil zemini (chroma key) şeffaf yap, kenardaki yeşil sızıntıyı temizle, kırp
magick $K/logo-yesil.png -alpha set -fuzz 30% -transparent '#00FF00' \
  -channel G -fx 'min(g,max(r,b))' +channel \
  -trim +repage -background none -gravity center -extent '%[fx:max(w,h)]x%[fx:max(w,h)]' \
  -resize 1024x1024 $V/logo.png
for s in 16 22 24 32 48 64 96 128 256 512; do magick $V/logo.png -resize ${s}x${s} $V/logo-$s.png; done

# 2) Yazılı logo: simge + ATMACA + harf aralıklı LINUX (+ isteğe bağlı slogan), şeffaf.
#    Sloganlı sürüm yalnızca duvar kâğıtlarında; açılış, kurucu vb. yerlerde sloganı yok.
yazili() { # $1=çıktı $2=ATMACA rengi $3=LINUX rengi $4=slogan (boşsa yok)
  local slogan=()
  [ -n "${4:-}" ] && slogan=( \( -size 1x40 xc:none +size \) \( -font $INCE -pointsize 50 -kerning 0 -fill "$ACIKMAVI" label:"$4" \) )
  magick -background none \
    \( $V/logo.png -resize 420x420 \) \
    \( -font $KALIN -pointsize 150 -fill "$2" -kerning 12 label:ATMACA \) \
    \( -font $KALIN -pointsize 64 -fill "$3" -kerning 46 label:LINUX \) \
    "${slogan[@]}" \
    -gravity center -append "$1"
}
yazili $V/logo-yazili-koyu.png "$BEYAZ" "$ACIKMAVI"
yazili $V/logo-yazili-acik.png "#1B263B" "#3B82F6"
yazili $V/logo-yazili-slogan-koyu.png "$BEYAZ" "$ACIKMAVI" "$SLOGAN"
yazili $V/logo-yazili-slogan-acik.png "#1B263B" "#3B82F6" "$SLOGAN"

# 3) Duvar kâğıtları: 3840x2160 ve 1920x1080
duvar() { # $1=kaynak $2=ad $3=logo bindir (bos|koyu|acik)
  magick $K/$1.png -filter Lanczos -resize 3840x2160^ -gravity center -extent 3840x2160 /tmp/d.png
  if [ "$3" != bos ]; then
    magick /tmp/d.png \( $V/logo-yazili-slogan-$3.png -resize x1000 \) -gravity center -composite /tmp/d.png
  fi
  magick /tmp/d.png -quality 92 $V/duvar/$2-3840x2160.jpg
  magick /tmp/d.png -resize 1920x1080 -quality 92 $V/duvar/$2-1920x1080.jpg
}
duvar gunduz Atmaca bos
duvar gece Atmaca-Gece bos
duvar koyu Atmaca-Koyu koyu
duvar acik Atmaca-Acik acik

# 4) Açılış (splash) / giriş / GRUB arka planı: logosuz koyu zemin
magick $K/koyu.png -resize 1920x1080^ -gravity center -extent 1920x1080 -quality 92 $V/koyu-zemin.jpg
magick $K/koyu.png -filter Lanczos -resize 3840x2160^ -gravity center -extent 3840x2160 -quality 92 $V/koyu-zemin-4k.jpg
magick $V/koyu-zemin.jpg -resize 1920x1080 $V/grub-zemin.png

# 5) Kurucu (Anaconda) görselleri
magick $V/logo-yazili-koyu.png -resize x200 $V/kurucu-yan-logo.png
magick -size 1x1 xc:"$LACI0" $V/kurucu-yan-zemin.png

echo "Varlıklar hazır:"; ls -la $V $V/duvar
