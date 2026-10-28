# Atmaca Linux paket depoları.
# Fedora'nın fedora-repos paketinin YERİNE geçer: dnf'nin paketleri ve güncellemeleri
# indirdiği depo tanımlarını "Atmaca" adıyla taşır. Paketler hâlâ Fedora 44'ün
# yansı sunucularından ve Fedora imzasıyla gelir; bu yüzden imza anahtarı da buradadır.
# Kaynak ağaç tarifler/marka-derle.sh tarafından hazırlanır.
Name:           atmaca-repos
Version:        44
Release:        2
Summary:        Atmaca Linux paket deposu tanımları
License:        MIT
BuildArch:      noarch
Source0:        atmaca-repos-agac.tar

Provides:       fedora-repos = %{version}-99
Provides:       fedora-repos(%{version}) = %{version}-99
Obsoletes:      fedora-repos < 99
# Flathub tanımını biz taşıyoruz
Provides:       fedora-flathub-remote = 99
Obsoletes:      fedora-flathub-remote < 99

%description
dnf'nin kullandığı ana depo, güncellemeler ve openh264 depoları ile paket
imzalarını doğrulayan anahtar. Ayrıca Flathub (Flatpak uygulamaları).

%prep
%setup -q -c -T
tar -xf %{SOURCE0}

%install
cp -a agac/. %{buildroot}/

%files -f dosyalar.txt
