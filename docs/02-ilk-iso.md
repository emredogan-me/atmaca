# Ders 2 — İlk Atmaca ISO'su (KDE)

## Kickstart nedir?
Bir "kurulum tarifi". Hangi paketler, hangi dil, hangi hizmetler, kurulumdan sonra
hangi komutlar çalışsın — hepsi tek dosyada. Fedora'nın kendi ISO'ları da böyle yazılır.

Bölümleri:
- Üst kısım: dil, klavye, saat dilimi, ağ, disk düzeni
- `%packages ... %end`: kurulacak paketler. `@ad` bir **grup**, `-paket` çıkarma demek
- `%post ... %end`: imaj hazırlandıktan sonra içinde çalışan kabuk komutları

## Katmanlar
```
kickstart/atmaca-taban.ks   ortak: çekirdek, Türkçe, donanım, canlı açılış, kurucu
kickstart/atmaca-kde.ks     %include atmaca-taban.ks + KDE Plasma
kickstart/atmaca-gnome.ks   (ileride) %include atmaca-taban.ks + GNOME
```
`ksflatten` `%include`'ları birleştirip tek dosya yapar; `ksvalidator` hataları denetler.

## Derleme kabı
`tarifler/Containerfile` araçları (lorax, anaconda…) bir kez kurulu bir imaj yapar:
`atmaca-derleme:44`. Her seferinde 460 paket indirmekten kurtuluruz.

## ISO üretmek
```bash
./tarifler/iso-uret.sh kde
```
Arka planda `livemedia-creator --make-iso --no-virt` çalışır:
1. Boş bir disk imajı açar, kickstart'taki paketleri içine `dnf` ile kurar
2. `%post` komutlarını çalıştırır
3. Sistemi sıkıştırır (squashfs/erofs), açılış dosyalarını (GRUB, EFI) ekler
4. Hepsini `build/iso-kde/atmaca-kde.iso` yapar

## Test
```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom build/iso-kde/atmaca-kde.iso
```

## Neden sudo?
`livemedia-creator` imajı bir **loop aygıtına** (dosyayı disk gibi gösteren çekirdek
özelliği) bağlar. Bunu yalnızca root yapabilir; normal kullanıcının podman'ı (rootless)
`losetup` hatası verir. Bu yüzden betik kendini `sudo` ile yeniden başlatır.
