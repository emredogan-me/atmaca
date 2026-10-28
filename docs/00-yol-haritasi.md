# Atmaca Yol Haritası

## Aşama 1 — Derleme ortamı
- [ ] Ubuntu (WSL) üstüne `podman` kur
- [ ] `tarifler/fedora-kabi.sh` ile Fedora derleme kabını aç

## Aşama 2 — İlk ISO (henüz Fedora görünümlü)
- [ ] `kickstart/atmaca.ks`: Fedora KDE paket listesi
- [ ] `livemedia-creator` ile ilk canlı ISO, QEMU'da aç

## Aşama 3 — Fedora markasını tamamen silmek (%100 Atmaca)
Fedora'nın markası şu paketlerde; her birinin yerine Atmaca'nınki gelecek:

| Fedora paketi | Ne içerir | Atmaca karşılığı |
|---|---|---|
| `fedora-release*` | `/etc/os-release`, sürüm adı | `atmaca-release` |
| `fedora-logos` | logolar, simgeler | `atmaca-logos` |
| `plymouth-theme-*` | açılış animasyonu | `atmaca-plymouth` |
| `desktop-backgrounds-*`, `f*-backgrounds` | duvar kâğıtları | `atmaca-backgrounds` |
| `fedora-repos` | depo tanımları | `atmaca-repos` (Fedora deposu + Atmaca deposu) |
| GRUB/SDDM teması | önyükleyici ve giriş ekranı | `atmaca-grub-theme`, `atmaca-sddm-theme` |
| Anaconda kurucu | "Fedora'yı kur" yazıları | Atmaca markalı kurucu (ya da Calamares) |

Not: "Fedora" adı ve logosu tescilli markadır. Türetilmiş dağıtım bunları
**kullanmamalı** — bu yüzden markayı silmek zaten zorunlu.

## Aşama 4 — Atmaca deposu
- [ ] Kendi RPM'lerimizi yayınlayacağımız depo (Copr ya da kendi sunucumuz)

## Aşama 5 — `atmc`
- [ ] `dnf` sarmalayıcısı: `atmc kur`, `atmc kaldir`, `atmc guncelle`, `atmc geri-al`
- [ ] Sonra: `libdnf5` üstünde kendi aracımız

## Aşama 6 — Gerçek donanım
- [ ] USB'ye yaz, ASUS TUF F15'te canlı aç, kur
