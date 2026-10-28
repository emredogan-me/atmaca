# Atmaca Linux kimlik paketi.
# Fedora'nın fedora-release-* paketlerinin YERİNE geçer: aynı dosyaları (systemd ön
# ayarları, rpm makroları…) taşır ama ad, logo ve adresler Atmaca'dır.
# Kaynak ağaç tarifler/marka-derle.sh tarafından hazırlanır.
%global surum 44

Name:           atmaca-release
Version:        %{surum}
Release:        2
Summary:        Atmaca Linux sürüm ve kimlik dosyaları
License:        MIT
BuildArch:      noarch
Source0:        atmaca-release-agac.tar

Provides:       system-release
Provides:       system-release(%{version})
Provides:       system-release(releasever) = %{version}
Provides:       base-module(platform:f%{version})
# Fedora paketleri bunları ister; aynı işi biz görüyoruz
Provides:       fedora-release = %{version}-99
Provides:       fedora-release-common = %{version}-99
Provides:       fedora-release-kde = %{version}-99
Provides:       fedora-release-identity = %{version}-99
Provides:       fedora-release-variant = %{version}-99
Provides:       generic-release = %{version}-99
Obsoletes:      fedora-release < 99
Obsoletes:      fedora-release-common < 99
Obsoletes:      fedora-release-kde < 99
Obsoletes:      fedora-release-kde-desktop < 99
Obsoletes:      fedora-release-identity-kde-desktop < 99
Provides:       fedora-release-kde-desktop = %{version}-99
Obsoletes:      fedora-release-identity-kde < 99
Obsoletes:      fedora-release-identity-basic < 99
Conflicts:      generic-release
Requires:       atmaca-repos

%description
Atmaca Linux'un adı, sürümü, /etc/os-release dosyası ve sistem ön ayarları.

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

%files -f dosyalar.txt
