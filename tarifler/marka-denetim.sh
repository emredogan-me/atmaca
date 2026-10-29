#!/usr/bin/env bash
# Atmaca marka denetimi: ISO'ya giren sistem imajında Fedora adı ya da logosu kalmış mı?
# Kickstart'taki "%post --nochroot" bölümünden, imajın kök klasörüyle çağrılır:
#   bash tarifler/marka-denetim.sh <imaj kökü>   → rapor standart çıktıya yazılır
#
# Bilerek kalanlar (raporda "beklenen" diye işaretlenir):
#   - /boot/efi/EFI/fedora: Güvenli Önyükleme imzalı GRUB bu yolu arar
#   - çekirdek adındaki fc44, rpm makroları (%fedora): paket uyumu için
#   - plasma-lookandfeel-fedora / kde-settings paketlerinin adı: KDE bunları zorunlu ister,
#     içlerindeki görünür Fedora parçaları atmaca-plasma tetikleyicileriyle kaldırılır
#   - NetworkManager-config-connectivity-fedora: internet bağlantısı denetimi (paket adı görünmez)
#   - org.fedoraproject.Anaconda.*: kurucunun iç D-Bus adları (değiştirilirse kurucu çalışmaz)
set -uo pipefail
K="${1:?imaj kökü verilmeli}"
SORUN=0
baslik() { printf '\n=== %s ===\n' "$1"; }
sorun() { echo "SORUN: $*"; SORUN=$((SORUN+1)); }

baslik "Kimlik (os-release)"
grep -E '^(NAME|PRETTY_NAME|VERSION|ID|ID_LIKE|LOGO)=' "$K/etc/os-release"
grep -qi fedora <(grep -E '^(NAME|PRETTY_NAME|VERSION|LOGO)=' "$K/etc/os-release") && sorun "os-release görünür alanlarında Fedora geçiyor"

baslik "Adında fedora geçen paketler"
rpm --root "$K" -qa --qf '%{NAME}\n' | grep -i fedora | sort | while read -r p; do
  case "$p" in plasma-lookandfeel-fedora|fedora-gpg-keys|fedora-repos-*|NetworkManager-config-connectivity-fedora) echo "beklenen: $p";;
               *) echo "SORUN: paket $p";; esac
done

baslik "Fedora logo ve marka paketleri"
for p in fedora-logos fedora-release fedora-release-common fedora-repos generic-logos \
         f44-backgrounds-base f44-backgrounds-kde desktop-backgrounds-kde breeze-icon-theme-fedora \
         fedora-appstream-metadata fedora-bookmarks kde-settings-plasmalogin; do
  rpm --root "$K" -q "$p" >/dev/null 2>&1 && sorun "$p kurulu"
done
echo "denetlendi"

baslik "Görünür klasörlerde adında fedora geçen dosyalar"
for d in usr/share/pixmaps usr/share/icons usr/share/wallpapers usr/share/backgrounds \
         usr/share/plasma usr/share/plymouth usr/share/anaconda usr/share/cockpit/branding \
         usr/share/color-schemes usr/share/sddm usr/share/applications etc/xdg etc/yum.repos.d; do
  [ -d "$K/$d" ] || continue
  find "$K/$d" -iname '*fedora*' 2>/dev/null | sed "s#^$K##"
done | grep -v -E '^/usr/share/cockpit/branding/fedora|^/usr/share/icons/hicolor/.*/apps/fedora-logo|^/usr/share/pixmaps/fedora|/org\.fedoraproject\.Anaconda|^/usr/share/anaconda/gnome/' \
     | while read -r f; do echo "SORUN: $f"; done
echo "(beklenen: cockpit/branding/fedora, pixmaps/fedora-*, fedora-logo simgeleri ve kurucu simgesi"
echo " org.fedoraproject.AnacondaInstaller — dosya adı Fedora, içerik Atmaca, uygulamalar bu adları arar;"
echo " org.fedoraproject.Anaconda.* — kurucunun iç D-Bus adları, görünmez; anaconda/gnome — KDE'de kullanılmaz)"

baslik "Menüde/masaüstünde görünen yazılarda Fedora"
grep -l -i -E '^(Name|GenericName|Comment)(\[(tr|en.*)\])?=.*fedora' \
  "$K"/usr/share/applications/*.desktop "$K"/etc/xdg/autostart/*.desktop 2>/dev/null \
  | sed "s#^$K##" | while read -r f; do echo "SORUN: $f"; done

baslik "Depo tanımları"
ls "$K/etc/yum.repos.d/"
grep -h '^name=' "$K"/etc/yum.repos.d/*.repo | grep -i fedora && sorun "depo adında Fedora"

baslik "Açılış ve görünüm"
echo "Plymouth: $(chroot "$K" plymouth-set-default-theme 2>/dev/null || echo bilinmiyor)"
grep -h '^LookAndFeelPackage=' "$K/etc/xdg/kdeglobals" 2>/dev/null
ls "$K/usr/share/plasma/look-and-feel/" 2>/dev/null
ls -la "$K/usr/share/wallpapers/" 2>/dev/null | grep -i fedora && sorun "Fedora duvar kâğıdı kısayolu"
ls "$K/usr/share/plasma/look-and-feel/" 2>/dev/null | grep -i fedora && sorun "Fedora KDE görünümü"
grep -h '^\(id\|about\)=' "$K/usr/lib64/firefox/distribution/distribution.ini" 2>/dev/null
grep -h '^Name\(\[tr\]\)\?=' "$K/usr/share/applications/liveinst.desktop" 2>/dev/null

baslik "SONUÇ"
echo "Ciddi sorun sayısı (SORUN satırları yukarıda): $SORUN + paket/dosya satırları"
