# Ders 1 — Fedora Tabanlı Dağıtım Nasıl Yapılır?

## Fikir
Bir dağıtım üç katmandan oluşur:

1. **Çekirdek (Linux)** — donanımla konuşur.
2. **Paketler** — kabuk, KDE, Firefox... binlerce program.
3. **Kimlik** — ad, logo, açılış ekranı, tema, kurucu, depo.

Fedora bize 1. ve 2. katmanı hazır ve güncel veriyor. Biz 3. katmanı tamamen
değiştiriyoruz. Ubuntu Debian'dan, Pardus Debian'dan, Nobara Fedora'dan böyle doğdu.

## ISO nasıl üretilir?
Fedora'nın kendi ISO'larını da üreten araç **livemedia-creator**'dır (`lorax` paketi).
Ona bir **kickstart** dosyası veririz: "şu paketleri kur, şunları sil, şu ayarları yap".
O da bunu bir canlı ISO'ya çevirir.

## Neden kap (podman)?
Biz Ubuntu (WSL) üstündeyiz; `dnf` ve `livemedia-creator` Fedora araçları.
`podman` ile Ubuntu içinde küçük bir Fedora açıp araçları orada çalıştırırız.
Bilgisayarına Fedora kurmana gerek kalmaz.

## Komutlar
```bash
sudo apt install -y podman      # bir kez
./tarifler/fedora-kabi.sh       # Fedora kabına gir
```
Kabın içinde `cat /etc/fedora-release` en güncel Fedora sürümünü gösterir.

## apt → dnf
| apt | dnf |
|---|---|
| `apt install x` | `dnf install x` |
| `apt remove x` | `dnf remove x` |
| `apt upgrade` | `dnf upgrade` |
| `apt search x` | `dnf search x` |
| `dpkg -L x` | `rpm -ql x` |
| — | `dnf history undo last` |
