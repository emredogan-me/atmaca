# Atmaca Linux — KDE Plasma sürümü
# İlke: eksiksiz bir masaüstü, ama gereksiz yük yok.
# Fedora'nın "kde-desktop-environment" ortamındaki zorunlu gruplar alınır;
# kde-apps / kde-media / kde-pim / libreoffice gibi "varsayılan ekler" alınmaz,
# yerine her gün gereken uygulamalar tek tek seçilir.
%include atmaca-taban.ks

%packages
# KDE ortamının zorunlu grupları (dial-up, input-methods, guest-agents hariç)
@base-graphical
@printing
@desktop-accessibility
@admin-tools
@kde-desktop

# Günlük uygulamalar (kde-apps / kde-media yerine seçilmiş)
firefox
okular                  # PDF / belge
gwenview                # resim
kcalc                   # hesap makinesi
elisa-player            # müzik
haruna                  # video
kate                    # metin düzenleyici

# --- Gereksizler ---
# Akonadi + MariaDB: yalnızca KMail/KOrganizer içindir, onları kurmuyoruz
-akonadi-server
-akonadi-server-mysql
-mariadb*
-kio-gdrive
# Hata raporlayıcı Fedora'nın sunucularına gönderir
-abrt*
# Fedora'ya özel depo/marka paketleri (Aşama 3'te Atmaca karşılıkları gelecek)
-fedora-flathub-remote
-fedora-workstation-repositories
-NetworkManager-config-connectivity-fedora
# Uzak masaüstü sunucuları ve kullanım anketi
-krdp
-krfb
-kde-inotify-survey
-plasma-desktop-doc
%end

%post
sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys
# Fedora 44'te KDE giriş ekranı SDDM değil, plasma-login-manager
systemctl enable plasmalogin.service
systemctl set-default graphical.target
%end
