#!/usr/bin/env bash
# Atmaca marka paketlerini derler ve build/depo altında yerel bir dnf deposu kurar.
# Fedora 44 kabının içinde çalışır (CI ya da: podman run ... fedora:44 bash tarifler/marka-derle.sh).
#
#   atmaca-release   kimlik: ad, sürüm, os-release            (fedora-release-* yerine)
#   atmaca-logos     logolar + Plymouth açılış teması          (fedora-logos yerine)
#   atmaca-repos     dnf depo tanımları + imza anahtarı        (fedora-repos yerine)
#   atmaca-arkaplan  duvar kâğıtları + giriş ekranı zemini     (f44-backgrounds-* yerine)
#   atmaca-plasma    KDE görünümü, renkler, açılış, giriş...   (plasma-lookandfeel-fedora yerine)
#
# Yöntem: gerekli yerlerde Fedora'nın kendi paketini indir → aç → Atmaca'ya çevir →
# kendi adımızla yeniden paketle. Görseller marka/varlik/ altından gelir
# (tarifler/varlik-uret.sh üretir).
set -euxo pipefail

KOK="$(cd "$(dirname "$0")/.." && pwd)"
IS="$KOK/build/marka"
VARLIK="$KOK/marka/varlik"
SURUM=44          # Fedora tabanı: dnf ve paket uyumu için gerekli, kullanıcıya gösterilmez
ATMACA=1.0        # Atmaca'nın kendi sürümü: kullanıcının gördüğü
rm -rf "$IS"; mkdir -p "$IS" "$KOK/build/depo"
cd "$IS"

dnf -y install rpm-build createrepo_c cpio ImageMagick findutils

ac() { # $1=hedef klasör, geri kalanı: rpm dosyaları
  local h=$1; shift; mkdir -p "$h"
  for r in "$@"; do (cd "$h" && rpm2cpio "$r" | cpio -idm --quiet); done
}

# ---------- 1) atmaca-release ----------
dnf download --destdir=fedora fedora-release-common fedora-release-kde fedora-release-identity-kde
ac release/agac "$IS"/fedora/*.rpm
echo "--- Fedora release paketlerinden gelen dosyalar:"; (cd release/agac && find . ! -type d | sort)

A=release/agac
rm -f $A/usr/lib/os-release $A/etc/os-release $A/usr/lib/os-release.d/* 2>/dev/null || true
mkdir -p $A/usr/lib $A/etc
cat > $A/usr/lib/os-release <<OS
NAME="Atmaca Linux"
VERSION="$ATMACA"
ID=atmaca
ID_LIKE=fedora
VERSION_ID=$SURUM
VERSION_CODENAME=""
PRETTY_NAME="Atmaca Linux"
ANSI_COLOR="0;38;2;37;99;235"
LOGO=atmaca-logo-icon
CPE_NAME="cpe:/o:atmaca:atmaca:$ATMACA"
HOME_URL="https://github.com/emredogan-me/atmaca"
SUPPORT_URL="https://github.com/emredogan-me/atmaca/issues"
BUG_REPORT_URL="https://github.com/emredogan-me/atmaca/issues"
VARIANT="KDE Plasma"
VARIANT_ID=kde
DEFAULT_HOSTNAME="atmaca"
PLATFORM_ID="platform:f$SURUM"
IMAGE_VERSION="$ATMACA"
OS
ln -sf ../usr/lib/os-release $A/etc/os-release
# "<ad> release <sürüm>" biçimi önemli: kurucu ve GRUB adı " release"den öncesini alır
echo "Atmaca Linux release $ATMACA" > $A/etc/atmaca-release
ln -sf atmaca-release $A/etc/system-release
ln -sf atmaca-release $A/etc/redhat-release
ln -sf atmaca-release $A/etc/fedora-release   # eski araçlar bu adı arar; içerik Atmaca
echo "cpe:/o:atmaca:atmaca:$ATMACA" > $A/etc/system-release-cpe
printf '\\S\nÇekirdek \\r — \\m\n\n' > $A/etc/issue
printf '\\S\nÇekirdek \\r — \\m\n' > $A/etc/issue.net

# Kalan metin dosyalarındaki marka adını değiştir (makrolar: %fedora / %dist kalır, paket uyumu için)
grep -rlI -e 'Fedora' $A | while read -r f; do
  case "$f" in */macros.d/*) sed -i 's/Fedora Project/Atmaca/g; s/Fedora/Atmaca/g' "$f";;
               *) sed -i 's/Fedora Linux/Atmaca Linux/g; s/Fedora Project/Atmaca/g; s/Fedora/Atmaca/g' "$f";; esac
done
grep -rlI -e 'fedoraproject.org' $A | xargs -r sed -i 's#https\?://[a-z.]*fedoraproject.org[^" ]*#https://github.com/emredogan-me/atmaca#g'

# ---------- 2) atmaca-logos (+ Plymouth teması) ----------
dnf download --destdir=generic generic-logos plymouth-theme-spinner
ac logos/agac "$IS"/generic/generic-logos-*.rpm
L=logos/agac
rm -rf $L/usr/share/doc/generic-logos $L/usr/share/licenses/generic-logos

# SVG isteyen yerler için: Atmaca simgesini içine gömen bir SVG
SIMGE_SVG=$IS/atmaca-simge.svg
cat > $SIMGE_SVG <<SVG
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="256" height="256" viewBox="0 0 256 256"><image width="256" height="256" xlink:href="data:image/png;base64,$(base64 -w0 "$VARLIK/logo-256.png")"/></svg>
SVG
find $L -name '*.svg' -exec cp "$SIMGE_SVG" {} \;
# Her PNG → aynı boyutta, ortalanmış Atmaca simgesi (geniş resimlerde yazılı logo)
find $L -name '*.png' | while read -r p; do
  read -r G Y < <(magick identify -format '%w %h\n' "$p" | head -1)
  if [ "$G" -ge $((Y*2)) ]; then magick "$VARLIK/logo-yazili-koyu.png" -resize x$((Y*9/10)) /tmp/l.png
  else K=$(( (G<Y ? G : Y) * 9 / 10 )); [ "$K" -lt 16 ] && K=$G; magick "$VARLIK/logo.png" -resize ${K}x${K} /tmp/l.png; fi
  magick -size ${G}x${Y} xc:none /tmp/l.png -gravity center -composite "$p"
done
# Atmaca'nın kendi adlı simgeleri (os-release LOGO=atmaca-logo-icon)
for b in 16 22 24 32 48 64 96 128 256 512; do
  mkdir -p $L/usr/share/icons/hicolor/${b}x${b}/apps
  cp "$VARLIK/logo-$b.png" $L/usr/share/icons/hicolor/${b}x${b}/apps/atmaca-logo-icon.png
done
mkdir -p $L/usr/share/icons/hicolor/scalable/apps $L/usr/share/pixmaps
cp $SIMGE_SVG $L/usr/share/icons/hicolor/scalable/apps/atmaca-logo-icon.svg
cp "$VARLIK/logo-256.png" $L/usr/share/pixmaps/atmaca-logo.png
magick "$VARLIK/logo-yazili-koyu.png" -resize x256 $L/usr/share/pixmaps/atmaca-logo-text.png
# Kurucunun yan çubuğu
if [ -d $L/usr/share/anaconda/pixmaps ]; then
  cp "$VARLIK/kurucu-yan-logo.png" $L/usr/share/anaconda/pixmaps/sidebar-logo.png
  magick "$VARLIK/kurucu-yan-zemin.png" -resize 300x1000! $L/usr/share/anaconda/pixmaps/sidebar-bg.png
fi
rm -f $L/usr/share/pixmaps/bootloader/*.icns $L/usr/share/pixmaps/bootloader/*.vol
# Plymouth teması: dönen simge resimleri spinner temasından (sembolik bağ), logo bizden
P=$L/usr/share/plymouth/themes/atmaca; mkdir -p $P
cp "$KOK/marka/plymouth/atmaca.plymouth" $P/
magick "$VARLIK/logo-yazili-koyu.png" -resize x300 $P/watermark.png
for f in $(rpm -qpl "$IS"/generic/plymouth-theme-spinner-*.rpm | grep '/themes/spinner/.*\.png$'); do
  b=$(basename $f); [ "$b" = watermark.png ] || ln -sf ../spinner/$b $P/$b
done
# Kurucu (Anaconda Web UI) ve Cockpit markası: os-release ID'sine göre seçilir
C=$L/usr/share/cockpit/branding/atmaca; mkdir -p $C
cp "$KOK/marka/kurucu/branding.css" $C/
cp "$VARLIK/logo-256.png" $C/logo.png
cp "$VARLIK/logo-256.png" $C/apple-touch-icon.png
magick "$VARLIK/logo-64.png" -define icon:auto-resize=64,48,32,16 $C/favicon.ico

# ---------- 3) atmaca-repos ----------
dnf download --destdir=depo fedora-repos fedora-gpg-keys
ac depo/fedora "$IS"/depo/*.rpm
R=repos/agac; mkdir -p $R/etc/yum.repos.d $R/etc/pki/rpm-gpg
for f in fedora:atmaca fedora-updates:atmaca-updates fedora-cisco-openh264:atmaca-openh264; do
  grep -v '^#' depo/fedora/etc/yum.repos.d/${f%%:*}.repo | sed \
    -e 's/^\[fedora-cisco-openh264/[atmaca-openh264/' -e 's/^\[fedora/[atmaca/' -e 's/^\[updates/[atmaca-updates/' \
    -e 's/^name=Fedora \$releasever openh264 (From Cisco)/name=Atmaca Linux - openh264 (Cisco)/' \
    -e 's/^name=Fedora \$releasever /name=Atmaca Linux /' \
    -e 's#RPM-GPG-KEY-fedora-\$releasever-\$basearch#RPM-GPG-KEY-atmaca-$releasever-primary#' \
    > $R/etc/yum.repos.d/${f##*:}.repo
done
for s in $SURUM $((SURUM+1)); do
  k=depo/fedora/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$s-primary
  [ -f $k ] && cp $k $R/etc/pki/rpm-gpg/RPM-GPG-KEY-atmaca-$s-primary
done
test -f $R/etc/pki/rpm-gpg/RPM-GPG-KEY-atmaca-$SURUM-primary
# Flathub: Discover'da Flatpak uygulamaları. Resmi tanım dosyası (imza anahtarı içinde)
mkdir -p $R/etc/flatpak/remotes.d
curl -sfL -o $R/etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
grep -q '^GPGKey=' $R/etc/flatpak/remotes.d/flathub.flatpakrepo
cat $R/etc/yum.repos.d/atmaca.repo

# ---------- 4) atmaca-arkaplan ----------
W=arkaplan/agac/usr/share/wallpapers; mkdir -p $W arkaplan/agac/usr/share/backgrounds/atmaca
duvar() { # $1=ad $2=görünen ad $3=koyu tema sürümü (boşsa yok)
  mkdir -p $W/$1/contents/images
  for c in 1920x1080 3840x2160; do cp "$VARLIK/duvar/$1-$c.jpg" $W/$1/contents/images/$c.jpg; done
  magick "$VARLIK/duvar/$1-1920x1080.jpg" -resize 400x $W/$1/contents/screenshot.jpg
  if [ -n "$3" ]; then mkdir -p $W/$1/contents/images_dark
    for c in 1920x1080 3840x2160; do cp "$VARLIK/duvar/$3-$c.jpg" $W/$1/contents/images_dark/$c.jpg; done; fi
  cat > $W/$1/metadata.json <<J
{
    "KPlugin": {
        "Authors": [ { "Name": "Atmaca Linux" } ],
        "Id": "$1",
        "License": "CC-BY-SA-4.0",
        "Name": "$2"
    }
}
J
}
duvar Atmaca "Atmaca" Atmaca-Gece
duvar Atmaca-Gece "Atmaca Gece" ""
duvar Atmaca-Koyu "Atmaca Koyu" ""
duvar Atmaca-Acik "Atmaca Açık" ""
ln -sf Atmaca $W/Default
ln -sf Atmaca $W/F44
cp "$VARLIK/koyu-zemin-4k.jpg" arkaplan/agac/usr/share/backgrounds/atmaca/giris.jpg

# ---------- 5) atmaca-plasma ----------
K=plasma/agac; G="$KOK/marka/kde/gorunum"
for t in koyu acik; do
  D=$K/usr/share/plasma/look-and-feel/org.atmaca.$t.desktop
  mkdir -p $D/contents/splash/images $D/contents/previews
  cp "$G/$t/metadata.json" $D/; cp "$G/$t/defaults" $D/contents/
  cp -r "$G/ortak/layouts" "$G/ortak/plasmoidsetupscripts" $D/contents/
  cp "$G/ortak/splash/Splash.qml" $D/contents/splash/
  cp "$VARLIK/koyu-zemin.jpg" $D/contents/splash/images/zemin.jpg
  magick "$VARLIK/logo-yazili-koyu.png" -resize x600 $D/contents/splash/images/logo-yazili.png
  [ $t = koyu ] && d=Atmaca-Gece || d=Atmaca-Acik
  cp "$VARLIK/duvar/$d-1920x1080.jpg" $D/contents/previews/fullscreenpreview.jpg
  magick "$VARLIK/duvar/$d-1920x1080.jpg" -resize 600x $D/contents/previews/preview.png
  magick "$VARLIK/koyu-zemin.jpg" \( "$VARLIK/logo-yazili-koyu.png" -resize x340 \) -gravity center -composite \
    -resize 600x $D/contents/previews/splash.png
done
mkdir -p $K/usr/share/color-schemes $K/etc/xdg $K/usr/lib/plasmalogin $K/usr/share/konsole \
         $K/etc/skel/.config $K/etc/anaconda/profile.d $K/etc/firefox/policies
cp "$KOK"/marka/kde/renk/*.colors $K/usr/share/color-schemes/
mkdir -p $K/usr/share/icons
cp -r "$KOK"/marka/simge/Atmaca "$KOK"/marka/simge/Atmaca-Koyu $K/usr/share/icons/
# Klasörler: Breeze'nin kendisi, yalnızca içteki çizim beyaz (tarifler/breeze-klasor.py)
dnf download --destdir=breeze breeze-icon-theme
ac breeze/agac "$IS"/breeze/breeze-icon-theme-*.rpm
python3 "$KOK/tarifler/breeze-klasor.py" breeze/agac/usr/share/icons/breeze/places \
  $K/usr/share/icons/Atmaca $K/usr/share/icons/Atmaca-Koyu
# Breeze simgeleri LGPL lisanslı: uyarladığımız simgelerle birlikte lisans metni de gider
for t in Atmaca Atmaca-Koyu; do
  find breeze/agac/usr/share/licenses -type f -exec cp {} $K/usr/share/icons/$t/ \;
  printf 'Klasör simgeleri KDE Breeze simge temasından uyarlanmıştır (LGPL-3.0).\nAtmaca simgeleri: Atmaca Linux.\n' > $K/usr/share/icons/$t/LISANS.txt
done
cp "$KOK"/marka/kde/xdg/* $K/etc/xdg/
cp "$KOK/marka/kde/giris-defaults.conf" $K/usr/lib/plasmalogin/defaults.conf
cp "$KOK"/marka/kde/konsole/Atmaca.* $K/usr/share/konsole/
cp "$KOK/marka/kde/konsole/konsolerc" $K/etc/skel/.config/konsolerc
cp "$KOK/marka/anaconda/atmaca.conf" $K/etc/anaconda/profile.d/
cp "$KOK/marka/firefox/policies.json" $K/etc/firefox/policies/

# ---------- 6) Paketle ----------
# Dosya listesi ağaçtan otomatik çıkarılır; spec kopyası bu listeyi okur
for ad in release logos repos arkaplan plasma; do
  agac=$ad/agac
  (cd "$agac" && find . ! -type d | sed 's#^\.##; s#^#"#; s#$#"#') > $IS/atmaca-$ad.dosyalar
  # Bizim açtığımız klasörler de paketin olsun (kaldırılınca geride boş klasör kalmasın)
  (cd "$agac" && find . -mindepth 1 -type d | grep -E 'atmaca|Atmaca|plymouth/themes/atmaca|look-and-feel/org.atmaca' \
     | sed 's#^\.##; s#^#%dir "#; s#$#"#') >> $IS/atmaca-$ad.dosyalar || true
  sed -i 's#^"/etc/\(.*\)"$#%config(noreplace) "/etc/\1"#' $IS/atmaca-$ad.dosyalar
  mkdir -p rpmbuild/SOURCES
  tar -C "$ad" -cf rpmbuild/SOURCES/atmaca-$ad-agac.tar agac
  sed "s#^%files -f dosyalar.txt#%files -f $IS/atmaca-$ad.dosyalar#" "$KOK/marka/atmaca-$ad.spec" > $IS/atmaca-$ad.spec
  rpmbuild -bb --define "_topdir $IS/rpmbuild" --define "debug_package %{nil}" $IS/atmaca-$ad.spec
done

cp rpmbuild/RPMS/noarch/*.rpm "$KOK/build/depo/"
createrepo_c "$KOK/build/depo"
ls -la "$KOK/build/depo"
cat release/agac/usr/lib/os-release
