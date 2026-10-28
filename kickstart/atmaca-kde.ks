# Atmaca Linux — KDE Plasma sürümü
# İlke: Fedora 44 KDE ile birebir aynı paket seti — ne eksik ne fazla.
# Fedora'nın "KDE Plasma Workspaces" ortamı (kde-desktop-environment): bütün zorunlu
# grupları + varsayılan grupları. Farklar yalnızca şunlar:
#   - Fedora marka paketleri yerine Atmaca'nınkiler (atmaca-taban.ks)
#   - ek olarak Thunderbird
#   - Flathub, Fedora'nın paketi yerine atmaca-repos içinden gelir
%include atmaca-taban.ks

%packages
# Ortamın zorunlu grupları
@admin-tools
@base-graphical
@desktop-accessibility
@dial-up
@guest-desktop-agents
@input-methods
@kde-desktop
@printing
# (core, fonts, hardware-support, multimedia, networkmanager-submodules, standard: atmaca-taban.ks)

# Ortamın varsayılan grupları
@firefox
@kde-apps
@kde-media
@kde-pim
@libreoffice
libreoffice-langpack-tr

# Ek olarak: Thunderbird e-posta (KMail de duruyor)
thunderbird

# Atmaca görünümü: renkler, açılış/giriş ekranı, duvar kâğıtları, panel
atmaca-plasma
atmaca-arkaplan
rsms-inter-fonts        # Atmaca'nın arayüz yazı tipi

# --- Fedora'dan farklı olanlar ---
# Fedora'nın Flathub ayar paketi: aynısını atmaca-repos kuruyor
-fedora-flathub-remote
# Fedora logolu simge ve Discover'daki "Fedora Linux" bileşeni
-breeze-icon-theme-fedora
-fedora-appstream-metadata
# Üçüncü parti depo tanımları (Chrome, NVIDIA, Steam) Fedora adıyla gelir;
# Atmaca'nın kendi sürümü yapılana kadar yok
-fedora-workstation-repositories
# Çökme raporlarını Fedora'nın sunucularına gönderir
-abrt*
%end

%post
sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys
# Fedora 44'te KDE giriş ekranı SDDM değil, plasma-login-manager
systemctl enable plasmalogin.service
systemctl set-default graphical.target
%end
