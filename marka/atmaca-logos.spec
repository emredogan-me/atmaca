# Atmaca Linux logoları: Fedora'nın generic-logos paketindeki her resmi aynı yolda,
# aynı boyutta Atmaca simgesiyle değiştirir. fedora-logos'un yerine geçer.
Name:           atmaca-logos
Version:        44
Release:        1
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

%description
Atmaca simgesi, Plymouth açılış teması, kurucu ve önyükleyici görselleri.

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

%files -f dosyalar.txt
