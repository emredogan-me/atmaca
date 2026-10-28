#!/usr/bin/env bash
# Atmaca marka paketlerini (atmaca-release, atmaca-logos) derler ve build/depo
# altında yerel bir dnf deposu kurar. Fedora 44 kabının içinde çalışır (CI).
#
# Yöntem: Fedora'nın kendi paketlerini indir → aç → içindeki her "Fedora"yı Atmaca
# yap / her resmi Atmaca simgesiyle değiştir → kendi adımızla yeniden paketle.
# Böylece systemd ön ayarları gibi görünmeyen ama gerekli hiçbir dosya eksik kalmaz.
set -euxo pipefail

KOK="$(cd "$(dirname "$0")/.." && pwd)"
IS="$KOK/build/marka"
SURUM=44
rm -rf "$IS"; mkdir -p "$IS" "$KOK/build/depo"
cd "$IS"

dnf -y install rpm-build createrepo_c cpio librsvg2-tools ImageMagick findutils

# ---------- 1) atmaca-release ----------
dnf download --destdir=fedora fedora-release-common fedora-release-kde fedora-release-identity-kde
mkdir -p release/agac
for r in fedora/*.rpm; do (cd release/agac && rpm2cpio "$r" | cpio -idm --quiet); done
echo "--- Fedora release paketlerinden gelen dosyalar:"; (cd release/agac && find . ! -type d | sort)

A=release/agac
# Kimlik dosyaları: sıfırdan yazıyoruz
rm -f $A/usr/lib/os-release $A/etc/os-release $A/usr/lib/os-release.d/* 2>/dev/null || true
mkdir -p $A/usr/lib $A/etc
cat > $A/usr/lib/os-release <<OS
NAME="Atmaca Linux"
VERSION="$SURUM (KDE Plasma)"
ID=atmaca
ID_LIKE=fedora
VERSION_ID=$SURUM
VERSION_CODENAME=""
PRETTY_NAME="Atmaca Linux $SURUM (KDE Plasma)"
ANSI_COLOR="0;38;2;242;163;58"
LOGO=atmaca-logo-icon
CPE_NAME="cpe:/o:atmaca:atmaca:$SURUM"
HOME_URL="https://github.com/emredogan-me/atmaca"
SUPPORT_URL="https://github.com/emredogan-me/atmaca/issues"
BUG_REPORT_URL="https://github.com/emredogan-me/atmaca/issues"
VARIANT="KDE Plasma"
VARIANT_ID=kde
DEFAULT_HOSTNAME="atmaca"
PLATFORM_ID="platform:f$SURUM"
OS
ln -sf ../usr/lib/os-release $A/etc/os-release
echo "Atmaca Linux $SURUM" > $A/etc/atmaca-release
ln -sf atmaca-release $A/etc/system-release
ln -sf atmaca-release $A/etc/redhat-release
ln -sf atmaca-release $A/etc/fedora-release   # eski araçlar bu adı arar; içerik Atmaca
echo "cpe:/o:atmaca:atmaca:$SURUM" > $A/etc/system-release-cpe
printf '\\S\nÇekirdek \\r — \\m\n\n' > $A/etc/issue
printf '\\S\nÇekirdek \\r — \\m\n' > $A/etc/issue.net

# Kalan metin dosyalarındaki marka adını değiştir (makrolar: %fedora / %dist kalır, paket uyumu için)
grep -rlI -e 'Fedora' $A | while read -r f; do
  case "$f" in */macros.d/*) sed -i 's/Fedora Project/Atmaca/g; s/Fedora/Atmaca/g' "$f";;
               *) sed -i 's/Fedora Linux/Atmaca Linux/g; s/Fedora Project/Atmaca/g; s/Fedora/Atmaca/g' "$f";; esac
done
# Fedora'ya ait ağ adresleri
grep -rlI -e 'fedoraproject.org' $A | xargs -r sed -i 's#https\?://[a-z.]*fedoraproject.org[^" ]*#https://github.com/emredogan-me/atmaca#g'

# ---------- 2) atmaca-logos ----------
dnf download --destdir=generic generic-logos
mkdir -p logos/agac
(cd logos/agac && rpm2cpio ../../generic/*.rpm | cpio -idm --quiet)
L=logos/agac
SIMGE="$KOK/marka/logo/atmaca-simge.svg"
YAZI="$KOK/marka/logo/atmaca-yazi.svg"
rm -rf $L/usr/share/doc/generic-logos $L/usr/share/licenses/generic-logos

# Her SVG → Atmaca simgesi
find $L -name '*.svg' -exec cp "$SIMGE" {} \;
# Her PNG → aynı boyutta, ortalanmış Atmaca simgesi (geniş resimlerde yazılı logo)
find $L -name '*.png' | while read -r p; do
  read -r G Y < <(identify -format '%w %h\n' "$p" | head -1)
  K=$(( (G<Y ? G : Y) * 7 / 10 )); [ "$K" -lt 16 ] && K=$G
  if [ "$G" -ge $((Y*2)) ]; then KAYNAK="$YAZI"; GEN=$((G*8/10)); rsvg-convert -w $GEN "$KAYNAK" -o /tmp/l.png
  else rsvg-convert -w $K -h $K "$SIMGE" -o /tmp/l.png; fi
  convert -size ${G}x${Y} xc:none /tmp/l.png -gravity center -composite "$p"
done
# Atmaca'nın kendi adlı simgeleri (os-release LOGO=atmaca-logo-icon)
for b in 16 22 24 32 48 64 128 256; do
  mkdir -p $L/usr/share/icons/hicolor/${b}x${b}/apps
  rsvg-convert -w $b -h $b "$SIMGE" -o $L/usr/share/icons/hicolor/${b}x${b}/apps/atmaca-logo-icon.png
done
cp "$SIMGE" $L/usr/share/icons/hicolor/scalable/apps/atmaca-logo-icon.svg
mkdir -p $L/usr/share/pixmaps
rsvg-convert -w 256 "$SIMGE" -o $L/usr/share/pixmaps/atmaca-logo.png
rsvg-convert -w 512 "$YAZI"  -o $L/usr/share/pixmaps/atmaca-logo-text.png
# Fedora adlı dosyalar Atmaca resmini taşır; adlarını uygulamalar aradığı için koruyoruz
# fedora.icns / .vol (Mac açılış simgeleri) çevrilemez → kaldır
rm -f $L/usr/share/pixmaps/bootloader/*.icns $L/usr/share/pixmaps/bootloader/*.vol

# ---------- 3) Paketle ----------
# Dosya listesi ağaçtan otomatik çıkarılır; spec kopyası bu listeyi okur
for ad in atmaca-release atmaca-logos; do
  case $ad in atmaca-release) agac=release/agac;; atmaca-logos) agac=logos/agac;; esac
  (cd "$agac" && find . ! -type d | sed 's#^\.##; s#^#"#; s#$#"#') > $IS/$ad.dosyalar
  sed -i 's#^"/etc/\(.*\)"$#%config(noreplace) "/etc/\1"#' $IS/$ad.dosyalar
  mkdir -p rpmbuild/SOURCES
  tar -C "$(dirname $agac)" -cf rpmbuild/SOURCES/$ad-agac.tar agac
  sed "s#^%files -f dosyalar.txt#%files -f $IS/$ad.dosyalar#" "$KOK/marka/$ad.spec" > $IS/$ad.spec
  rpmbuild -bb --define "_topdir $IS/rpmbuild" --define "debug_package %{nil}" $IS/$ad.spec
done

cp rpmbuild/RPMS/noarch/*.rpm "$KOK/build/depo/"
createrepo_c "$KOK/build/depo"
rpm -qpl "$KOK"/build/depo/atmaca-release-*.rpm
cat release/agac/usr/lib/os-release
