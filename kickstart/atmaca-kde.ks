# Atmaca Linux — KDE Plasma sürümü
%include atmaca-taban.ks

%packages
@kde-desktop-environment
@kde-apps
@kde-media
sddm
sddm-breeze
plasma-workspace-wayland
firefox
%end

%post
# livesys'e hangi masaüstünü kuracağını söyle
sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys
systemctl enable sddm.service
systemctl set-default graphical.target
%end
