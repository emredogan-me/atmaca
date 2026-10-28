# Ders 4 — Fedora Markasını Silmek, Atmaca Kimliği

## Marka nerede yaşar?
Bir dağıtımın "kimliği" birkaç pakette toplanır:

| Fedora paketi | İçinde | Atmaca karşılığı |
|---|---|---|
| `fedora-release-common`, `-kde`, `-identity-kde` | `/etc/os-release`, sürüm adı, systemd ön ayarları, rpm makroları | `atmaca-release` |
| `fedora-logos` | logolar, Plymouth açılış resmi, kurucu görselleri | `atmaca-logos` |

`/etc/os-release` en önemlisi: KDE'nin "Bu sistem hakkında" ekranı, `hostnamectl`,
`fastfetch`, GRUB menüsü… hepsi adı buradan okur.

## Neden sıfırdan yazmadık da "dönüştürdük"?
`fedora-release` içinde görünmeyen ama hayati dosyalar var — örneğin
`/usr/lib/systemd/system-preset/*.preset`: hangi hizmetlerin (NetworkManager, ses…)
açılışta başlayacağını söyler. Bunlar eksik olursa sistem "açılır ama interneti yok".
Bu yüzden `tarifler/marka-derle.sh`:
1. Fedora'nın paketini indirir ve açar (`rpm2cpio | cpio`)
2. `os-release`'i sıfırdan Atmaca olarak yazar
3. Kalan dosyalardaki "Fedora" yazılarını "Atmaca" yapar
4. Kendi adımızla yeniden paketler

Logolarda da aynısı: Fedora'nın `generic-logos` paketindeki **her resim, aynı yolda ve
aynı boyutta** Atmaca simgesiyle değiştirilir. Böylece hiçbir uygulama "resim bulunamadı"
demez.

## Provides / Obsoletes
Yüzlerce Fedora paketi `Requires: fedora-logos` ya da `system-release` der.
`atmaca-logos` bunu karşılar:
```
Provides:  fedora-logos = 99      ← "bu ihtiyacı ben karşılarım"
Obsoletes: fedora-logos < 99      ← "o paketin yerine geçerim"
```
`ID_LIKE=fedora` da os-release'te kalır: Fedora için yazılmış programlar Atmaca'yı
"Fedora ailesinden" tanır ve çalışmaya devam eder. Ubuntu da `ID_LIKE=debian` der.

## Yerel depo
Kendi paketlerimiz `build/depo` altında bir dnf deposu olur (`createrepo_c`);
kickstart'ta `repo --name=atmaca` ile eklenir.

## Logo
`marka/logo/atmaca-simge.svg`: lacivert daire, turuncu kanatlar, beyaz atmaca.
Bu bir **yer tutucu**; istediğin zaman kendi çizdiğin SVG ile değiştir, her şey
yeniden üretilir.

## Henüz Fedora olarak kalanlar (sonraki adımlar)
- `fedora-repos`: depo tanımları (paketler hâlâ Fedora sunucularından gelir — bu doğru)
- Duvar kâğıdı ve KDE açılış ekranı teması
- GRUB menüsü teması
