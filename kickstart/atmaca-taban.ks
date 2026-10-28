# Atmaca Linux — ortak taban (tüm masaüstü sürümleri bunu %include eder)
# Şimdilik Fedora 44 depolarını kullanır; markalama Aşama 3'te değişecek.

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
part / --size=12288 --fstype=ext4

url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f44&arch=x86_64

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
-glibc-all-langpacks

# Kurucu
anaconda-live
anaconda-install-env-deps

# Atmaca'da istemediklerimiz
-@dial-up
-@input-methods
%end

%post
# Canlı oturum hizmeti (liveuser oluşturur)
systemctl enable livesys.service livesys-late.service

# Henüz atmaca-release yok: canlı sistemde en azından adımızı görelim
echo "Atmaca Linux (geliştirme) — Fedora 44 tabanı" > /etc/issue.d/atmaca.issue
%end
