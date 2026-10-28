# Atmaca Linux logoları: Fedora'nın generic-logos paketindeki her resmi aynı yolda,
# aynı boyutta Atmaca simgesiyle değiştirir. fedora-logos'un yerine geçer.
Name:           atmaca-logos
Version:        44
Release:        2
Summary:        Atmaca Linux logoları ve açılış görselleri
License:        MIT
BuildArch:      noarch
Source0:        atmaca-logos-agac.tar

Provides:       system-logos = %{version}-%{release}
Provides:       fedora-logos = 99
Provides:       redhat-logos = 99
Provides:       gnome-logos = 99
Obsoletes:      fedora-logos < 99
Conflicts:      generic-logos
# Açılış teması (Plymouth) bu iki paketin dönen simge resimlerini kullanır
Requires:       plymouth-theme-spinner
Requires:       plymouth-plugin-two-step

%description
Atmaca simgesi, Plymouth açılış teması, kurucu ve önyükleyici görselleri.

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

# Canlı masaüstündeki kurulum kısayolunun adı anaconda-live paketinden gelir
# ("Sabit Diske Kur"); her kurulum/güncellemede Atmaca adıyla değiştiriyoruz.
%triggerin -- anaconda-live
D=/usr/share/applications/liveinst.desktop
[ -f $D ] && sed -i -e 's/^Name=.*/Name=Install Atmaca Linux/' -e "s/^Name\[tr\]=.*/Name[tr]=Atmaca Linux'u Kur/" \
  -e 's/^Comment=.*/Comment=Install Atmaca Linux to your computer/' \
  -e "s/^Comment\[tr\]=.*/Comment[tr]=Atmaca Linux'u bilgisayarınıza kurun/" $D || :

%files -f dosyalar.txt
