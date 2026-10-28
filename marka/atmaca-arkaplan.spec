# Atmaca Linux duvar kâğıtları.
# Fedora'nın duvar kâğıdı paketlerinin YERİNE geçer. KDE'nin "Default" duvar kâğıdı
# Atmaca'yı gösterir; koyu temada kendiliğinden gece sürümüne geçer.
# Kaynak ağaç tarifler/marka-derle.sh tarafından hazırlanır.
Name:           atmaca-arkaplan
Version:        1.0
Release:        1
Summary:        Atmaca Linux duvar kâğıtları
License:        CC-BY-SA-4.0
BuildArch:      noarch
Source0:        atmaca-arkaplan-agac.tar

Provides:       desktop-backgrounds-kde = 99
Provides:       system-backgrounds-kde = 99
Provides:       f44-backgrounds-kde = 99
Provides:       f44-backgrounds-base = 99
Obsoletes:      desktop-backgrounds-kde < 99
Obsoletes:      f44-backgrounds-kde < 99
Obsoletes:      f44-backgrounds-base < 99

%description
Atmaca, Atmaca Gece, Atmaca Koyu ve Atmaca Açık duvar kâğıtları ile giriş
ekranı zemini.

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

# kde-settings-plasma "Fedora" adlı bir duvar kâğıdı kısayolu kurar; seçicide
# ikinci kez görünmesin diye her kurulum/güncellemede kaldırıyoruz.
%triggerin -- kde-settings-plasma
rm -f /usr/share/wallpapers/Fedora || :

%files -f dosyalar.txt
