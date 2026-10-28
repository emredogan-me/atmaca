# Atmaca Linux KDE Plasma görünümü.
# Fedora'nın kde-settings-plasmalogin paketinin YERİNE geçer ve Fedora görünümlerini
# gizler. İçinde: Atmaca Koyu / Atmaca Açık görünümleri, renk şemaları, açılış ekranı,
# giriş ekranı, panel düzeni, Konsole teması, kurucu profili ve Firefox ayarları.
# Kaynak ağaç tarifler/marka-derle.sh tarafından hazırlanır.
Name:           atmaca-plasma
Version:        1.0
Release:        1
Summary:        Atmaca Linux KDE Plasma görünümü
License:        GPL-2.0-or-later
BuildArch:      noarch
Source0:        atmaca-plasma-agac.tar

Requires:       atmaca-arkaplan
Requires:       atmaca-logos
Provides:       kde-settings-plasmalogin = 99
Obsoletes:      kde-settings-plasmalogin < 99

%description
Atmaca'nın KDE Plasma masaüstü görünümü ve varsayılan ayarları.

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

# Firefox'un "Hakkında" penceresindeki dağıtım adı Firefox paketinin içinde duruyor;
# Firefox her kurulduğunda/güncellendiğinde Atmaca olarak düzeltiyoruz.
%triggerin -- firefox
D=/usr/lib64/firefox/distribution/distribution.ini
[ -f $D ] && sed -i 's/^id=.*/id=atmaca/; s/^about=.*/about=Mozilla Firefox - Atmaca Linux/; s/=fedora$/=atmaca/' $D || :

# plasma-workspace, plasma-lookandfeel-fedora paketinin tam kendi sürümünü istediği için
# o paketi yerinden edemiyoruz. Onun yerine içindeki "Fedora" görünümlerini siliyoruz;
# paket her güncellendiğinde bu tetikleyici yeniden çalışır.
%triggerin -- plasma-lookandfeel-fedora
rm -rf /usr/share/plasma/look-and-feel/org.fedoraproject.fedora*.desktop || :

%files -f dosyalar.txt
