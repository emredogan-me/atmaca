# 05 — Atmaca görünümü: Fedora'yı baştan sona Atmaca'ya çevirmek

Bu derste ilk ISO'da hâlâ Fedora'dan kalan her şeyi bulup Atmaca'nın kendi
tasarımıyla değiştiriyoruz: logo, duvar kâğıtları, renkler, açılış ve giriş
ekranları, paket depoları.

## 1. Önce kalıntıları bulmak

Tahminle iş yapmamak için çalışan ISO'nun içine baktık:

```bash
bsdtar -xf atmaca-kde.iso LiveOS/squashfs.img      # ISO'nun içindeki sistem imajı
unsquashfs -l LiveOS/squashfs.img | grep -i fedora  # adında fedora geçen dosyalar
```

Sonra her dosyanın hangi pakete ait olduğunu, imajın kendi paket veritabanıyla
sorduk (`rpm --dbpath ... -qf DOSYA`). Bulduklarımız:

| Ne görünüyordu | Hangi paketten | Ne yaptık |
|---|---|---|
| "Fedora" KDE görünümü | `plasma-lookandfeel-fedora` | `atmaca-plasma` yerine geçti |
| F44 duvar kâğıtları | `f44-backgrounds-*`, `desktop-backgrounds-kde` | `atmaca-arkaplan` yerine geçti |
| Giriş ekranı zemini | `kde-settings-plasmalogin` | `atmaca-plasma` yerine geçti |
| Kurucudaki Fedora simgesi | `breeze-icon-theme-fedora` | kickstart'tan çıkarıldı |
| Firefox başlangıç sayfası | `firefox` içindeki ayar dosyası | `/etc/firefox/policies` ile değiştirildi |
| **Depo tanımı hiç yoktu!** | `fedora-repos` kurulmamıştı | `atmaca-repos` eklendi |

Sonuncusu önemli bir hataydı: `fedora-release` paketini çıkarınca ona bağlı gelen
`fedora-repos` da gelmemişti. Yani kurulu sistemde `dnf` güncelleme bulamazdı.

## 2. "Yerine geçen paket" yöntemi

Fedora'nın bir paketini silip boşluk bırakmıyoruz. Aynı görevi yapan bir Atmaca
paketi yazıyoruz ve spec dosyasında iki satırla bunu dnf'ye bildiriyoruz:

```
Provides:  plasma-lookandfeel-fedora = 99   # "o paketi isteyen bana razı olsun"
Obsoletes: plasma-lookandfeel-fedora < 99   # "o paket kuruluysa beni koy, onu kaldır"
```

`plasma-workspace` gibi paketler `plasma-lookandfeel-fedora` ister. Bizim paketimiz
bu adı "sağladığı" için bağımlılık bozulmaz.

## 3. Dokunmadan ezmek: `/etc/xdg`

Fedora'nın KDE ayarları `/usr/share/kde-settings/kde-profile/default/xdg` altında.
KDE ayar dosyalarını `XDG_CONFIG_DIRS` sırasıyla okur ve **`/etc/xdg` önce gelir**.
Biz de Fedora'nın dosyasını değiştirmek yerine `/etc/xdg/kdeglobals` dosyasına kendi
varsayılanımızı yazdık:

```ini
[KDE]
LookAndFeelPackage=org.atmaca.koyu.desktop
```

Fedora'nın paketi güncellense bile bizim ayarımız geçerli kalır.

## 4. Atmaca görünümü neyden oluşuyor

- **Görünüm paketi** (`org.atmaca.koyu.desktop`, `org.atmaca.acik.desktop`):
  renk şeması, simge teması, duvar kâğıdı ve panel düzenini bir arada tutar.
  "Sistem Ayarları → Görünüm" bölümünde iki seçenek olarak çıkar.
- **Renk şemaları** (`AtmacaKoyu.colors`, `AtmacaAcik.colors`): her KDE uygulaması
  pencere, düğme ve seçim renklerini buradan alır.
- **Açılış ekranı** (`Splash.qml`): giriş yaptıktan sonra görünen ekran. Küçük
  bir QML dosyası: KDE `stage` değerini 1'den 6'ya kadar artırır, çubuk ona göre
  dolar.
- **Plymouth teması** (`atmaca.plymouth`): bilgisayar açılırken, masaüstünden
  önce görünen ekran. Dönen simge resimlerini Fedora'nın `spinner` temasından
  sembolik bağla alıyoruz, logo ise bizim.
- **Duvar kâğıdı**: `contents/images` ve `contents/images_dark` klasörleri.
  KDE koyu temada otomatik olarak `images_dark` klasöründeki gece resmini kullanır.

## 5. Değiştiremediklerimiz ve nedenleri

- **`VERSION_ID=44`:** Fedora tabanlı yazılımlar (ör. üçüncü parti depo
  kurulum betikleri) bu değere bakar. Bu yüzden kullanıcıya gösterilen ad
  `PRETTY_NAME="Atmaca Linux"`, sürüm `VERSION="1.0"`; `44` yalnızca teknik
  alanda kalıyor.
- **Çekirdek adındaki `fc44`:** Paketin kendi adı; değiştirmek için çekirdeği
  kendimiz derlememiz gerekir.
- **`/boot/efi/EFI/fedora` klasörü:** Güvenli Önyükleme (Secure Boot) imzalı
  GRUB bu yolu arar. Adını değiştirirsek imzalı açılış bozulur.
- **Depo adresleri:** Paketler hâlâ `mirrors.fedoraproject.org` adresinden
  iniyor. Kendi yansı sunucumuz olana kadar böyle kalacak; kullanıcı bunu görmez.

## Bu derste eklenen dosyalar

- `marka/kaynak/`: Figma'da yapay zekâyla üretilen ham görseller
- `marka/varlik/`: sistemde kullanılan hazır görseller (`tarifler/varlik-uret.sh` üretir)
- `marka/kde/`: renk şemaları, görünüm paketi, açılış ekranı, Konsole teması
- `marka/atmaca-{repos,arkaplan,plasma}.spec`: yeni paketler
- `tarifler/marka-derle.sh`: beş Atmaca paketini derleyen betik

## 6. Simgeler: KDE ile uyum

İlk denemede kendi simge setimizi çizdik (parlak, yuvarlak köşeli). KDE'nin geri
kalanı düz (flat) Breeze tarzında olduğu için yan yana gelince uyumsuz durdu. Çözüm:

- Genel simgeler (klasörler, çöp, ayarlar, uçbirim...) **KDE'nin kendi Breeze simgeleri.**
  Breeze klasörleri rengini sistemin vurgu renginden (`ColorScheme-Accent`) alır; vurgu
  rengi Atmaca mavisi olduğu için klasörler kendiliğinden Atmaca renginde görünür.
- Klasörlerin içindeki çizim normalde yazı renginden gelir (açık temada koyu). Atmaca'da
  her iki temada beyaz olsun diye `tarifler/breeze-klasor.py` yalnızca o parçayı değiştirir.
- Atmaca'ya özel simgeler (Hakkımızda, Topluluk, Bağış...) Breeze'nin çizim kurallarıyla
  çizildi: neredeyse keskin köşeli kare, üstte 1px açık / altta 1px koyu çizgi, uzun gölge.
- Breeze simgeleri LGPL lisanslıdır; uyarladığımız simgelerle birlikte lisans metni de
  temaya konur (`LISANS.txt`).

## 7. Kurucu (Anaconda) markası

Kurucu bir web sayfası gibi çalışır ve stilini Cockpit'in markalama klasöründen alır:
`/usr/share/cockpit/branding/<os-release ID>/branding.css`. Bizim klasörümüz olmasaydı
`ID_LIKE=fedora` üzerinden Fedora'nın renkleri ve logosu gelirdi. `atmaca-logos` artık
`branding/atmaca/` klasörünü kurar: Atmaca mavisi, Atmaca logosu. Kurucu profili
(`/etc/anaconda/profile.d/atmaca.conf`) Fedora KDE ayarlarını devralır (Btrfs, önyükleyici)
ama imza anahtarı ve güncelleme deposu adları Atmaca'nındır. Masaüstündeki kısayolun adı
"Atmaca Linux'u Kur" olur.

## 8. Otomatik marka denetimi

`tarifler/marka-denetim.sh` her ISO derlemesinde imajın içini tarar: os-release, adında
fedora geçen paketler, Fedora logo/duvar kâğıdı paketleri, görünür klasörlerdeki dosya
adları, menüde görünen yazılar, depo adları, açılış teması. Rapor GitHub'da
**marka-denetimi** adıyla ayrıca indirilebilir; ISO'yu indirmeden okunur.

## 9. İmzalama gerekiyor mu?

- **Güvenli Önyükleme (Secure Boot):** Fedora'nın Microsoft onaylı imzalı `shim`,
  GRUB ve çekirdeğini değiştirmeden kullanıyoruz; bu yüzden kendi imzamız gerekmiyor.
  Çekirdeği ya da GRUB'u kendimiz derlersek kendi anahtarımız gerekir (ya da kullanıcı
  Secure Boot'u kapatır / anahtarı kendisi tanıtır).
- **Paket imzası (GPG):** Fedora paketleri Fedora imzasıyla gelir, `atmaca-repos`
  doğrular. Bizim `atmaca-*` paketlerimiz şimdilik yalnızca ISO'nun içinde; internetten
  güncelleme verdiğimiz bir Atmaca deposu kurduğumuzda onları kendi GPG anahtarımızla
  imzalamamız ve açık anahtarı `atmaca-repos` içine koymamız gerekecek.
- **ISO:** SHA256 sağlama toplamı yayımlıyoruz. İsteğe bağlı olarak bu toplam dosyası da
  GPG ile imzalanabilir; açılış için gerekli değil, indirenin dosyanın bizden geldiğini
  doğrulaması içindir.
