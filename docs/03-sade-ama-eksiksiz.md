# Ders 3 — Sade ama Eksiksiz Paket Listesi

## Fedora'nın KDE ortamı nasıl kurulur?
`dnf environment info kde-desktop-environment` üç tür grup gösterir:
- **Zorunlu gruplar**: core, standard, base-graphical, hardware-support, fonts,
  multimedia, printing, kde-desktop… → masaüstünün çalışması için **şart**
- **Varsayılan gruplar**: kde-apps, kde-media, kde-pim, libreoffice, firefox →
  "olsa iyi olur" ekleri; oyunlar, torrent, e-posta, ofis…
- **İsteğe bağlı**: kde-education, 3d-printing…

Atmaca zorunluları alır, varsayılanların yerine günlük uygulamaları tek tek seçer.

## MariaDB nereden geliyordu?
`kde-desktop` → `akonadi-server-mysql` → `mariadb-server`.
Akonadi, KMail/KOrganizer'ın veritabanı motorudur. E-posta istemcisi kurmadığımız
için Akonadi'ye de MariaDB'ye de gerek yok: `-akonadi-server`, `-mariadb*`.

## Dikkat: her şeyi çıkaramazsın
İlk denemede `kaccounts-*` paketlerini de çıkardık. Sonuç:
`kaccounts → kf6-purpose → plasma-workspace` zinciri koptu ve **masaüstünün kendisi**
listeden düştü. Bu yüzden her değişiklikten sonra:
```bash
./tarifler/paket-kontrol.sh kde
```
Bu betik hiçbir şey kurmadan dnf'e listeyi çözdürür; bozulan paket varsa uyarır.

## Sonuç
| | Önce | Şimdi |
|---|---|---|
| Paket | 2268 | 1902 |
| İndirme | 3,4 GB | 2 GB |
| MariaDB / Akonadi / ABRT | var | yok |
| Masaüstü, giriş ekranı, ağ, ses, yazıcı, Bluetooth, Türkçe | var | var |

Ayrıca: `glibc-all-langpacks` (tüm diller, ~230 MB) yerine yalnızca Türkçe + İngilizce.
Fedora 44'te KDE giriş ekranı artık SDDM değil **plasma-login-manager**
(`plasmalogin.service`).
