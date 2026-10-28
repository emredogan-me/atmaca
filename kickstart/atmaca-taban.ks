# Atmaca Linux — ortak taban (tüm masaüstü sürümleri bunu %include eder)
# Paketler Fedora 44 depolarından gelir; ad, logo, depo tanımları ve görünüm Atmaca'nındır.

lang tr_TR.UTF-8
keyboard --xlayouts=tr
timezone Europe/Istanbul --utc
selinux --enforcing
firewall --enabled --service=mdns
network --bootproto=dhcp --device=link --activate
rootpw --lock
shutdown

# Canlı ISO için tek bölüm; boyut kurulu sistem değil, canlı imajın kendisi
zerombr
clearpart --all
part / --size=16384 --fstype=ext4

url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f44&arch=x86_64
# Atmaca'nın kendi paketleri (tarifler/marka-derle.sh üretir). cost düşük = öncelikli
repo --name=atmaca --baseurl=file:///atmaca/build/depo --cost=10

services --enabled=NetworkManager,chronyd

%packages
@core
@standard
@hardware-support
@fonts
@multimedia
@networkmanager-submodules
kernel
kernel-modules
kernel-modules-extra
linux-firmware

# Canlı açılış
dracut-live
livesys-scripts
grub2-efi-x64
grub2-efi-x64-cdboot
grub2-pc
shim-x64
efibootmgr
syslinux

# Türkçe
langpacks-tr
glibc-langpack-tr
glibc-langpack-en
glibc-all-langpacks     # Fedora'daki gibi: kurucuda her dil seçilebilsin

# Kurucu
anaconda-live
anaconda-install-env-deps

# Atmaca kimliği — Fedora markasının yerine
atmaca-release
atmaca-logos
atmaca-repos
-fedora-release*
-fedora-repos*
-fedora-logos
-generic-release*
-generic-logos
-fedora-bookmarks
-fedora-chromium-config*
%end

%post
# Canlı oturum hizmeti (liveuser oluşturur)
systemctl enable livesys.service livesys-late.service

# Açılış ekranı (Plymouth): Atmaca teması. Canlı imajın initramfs'i bundan sonra
# yeniden üretildiği için tema ISO'nun açılışına da girer.
plymouth-set-default-theme atmaca

# Fedora'dan kalan bir şey var mı? Derleme kaydına yaz (doğrulama için)
echo "=== ATMACA KİMLİK DENETİMİ ==="
cat /etc/os-release
ls /etc/yum.repos.d/
plymouth-set-default-theme
rpm -qa | grep -iE '^(fedora|generic)-(release|logos|repos)|lookandfeel-fedora|backgrounds' && echo "UYARI: Fedora marka paketi kaldı" || echo "Fedora marka paketi yok"
%end

%post --nochroot
# Marka denetimi: imajda Fedora adı/logosu kalmış mı? Rapor derleme çıktısına yazılır
# (GitHub'da "marka-denetimi" adıyla ayrıca indirilebilir).
bash /atmaca/tarifler/marka-denetim.sh "${ANA_INSTALL_PATH:-/mnt/sysimage}" > /atmaca/build/marka-denetim.txt 2>&1 || true
%end
