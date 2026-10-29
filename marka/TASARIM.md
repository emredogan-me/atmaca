# Atmaca Linux — Tasarım Paketi (onay için)

Slogan: **özgür • güvenli • milli**
Yazı tipi (logo ve başlıklar): **Poppins** (açık lisans, OFL)

## Renk paleti

| Renk | Kod | Nerede |
|---|---|---|
| Gece laciverti | `#0D1B2A` | Başlık çubukları, açılış zemini |
| Koyu lacivert | `#1B263B` | Düğmeler, paneller |
| Derin mavi | `#1E3A8A` | İkincil vurgu |
| Atmaca mavisi | `#2563EB` | Seçim, vurgu rengi, ilerleme çubuğu |
| Gök mavisi | `#60A5FA` | Bağlantılar, üzerine gelince |
| Gri | `#A8B2BD` | Soluk yazılar |
| Bulut beyazı | `#E2E8F0` | Koyu temada yazılar |

## Paketin içindekiler

- `00-genel-bakis.jpg` — her şey tek sayfada
- `logo/` — simge (16 pikselden 1024 piksele kadar), koyu ve açık zemin için yazılı logo
- `duvar-kagitlari/` — 4 duvar kâğıdı, her biri 4K (3840×2160) ve Full HD:
  - **Atmaca**: gündüz, dağlar ve atmaca (varsayılan). Koyu temada otomatik olarak gece sürümüne geçer.
  - **Atmaca-Gece**: ay ışığı
  - **Atmaca-Koyu**: lacivert, ortada logo (giriş ekranının zemini bunun logosuz hali)
  - **Atmaca-Acik**: beyaz kanatlar, ortada logo (açık tema)
- `onizleme/` — sistemde nasıl görüneceğinin taslakları:
  1. KDE açılış ekranı (giriş yaptıktan sonra)
  2. Plymouth (bilgisayar açılırken)
  3. Giriş ekranı
  4. Kilit ekranı
  5. Masaüstü ve alt panel
  6. Renk paleti
  7. Simgenin küçük boyutlarda nasıl göründüğü
  8-9. Simgeler: KDE'nin Atmaca mavisindeki klasör/sistem simgeleri + Atmaca'ya özel simgeler
- `kde-renk-semalari/` — **Atmaca Koyu** (varsayılan) ve **Atmaca Açık**. Bütün KDE uygulamaları bu renkleri kullanır.
- `simge-temasi/` — **Atmaca** ve **Atmaca-Koyu** simge temaları. KDE ile tam uyum için
  klasörler, çöp, ayarlar, uçbirim gibi genel simgeler KDE'nin kendi (Breeze) simgeleridir ve
  vurgu rengi sayesinde **Atmaca mavisinde** görünür. Atmaca'ya özel olanlar (hakkımızda,
  yardım, topluluk, bağış, güvenlik, güncelleme, depo, kurulum, canlı USB, uygulama menüsü)
  Breeze'nin çizim kurallarıyla çizildi; böylece hiçbir yer ötekinden "daha modern" durmaz.

## Varsayılan ayarlar (kurulumdan sonra elle yapılmasına gerek kalmasın)

- Dil ve klavye: **Türkçe**, **Türkçe Q** klavye, İstanbul saat dilimi
- Görünüm: **Atmaca Koyu** (Sistem Ayarları'ndan Atmaca Açık seçilebilir)
- Yazı tipi: **Inter** (bütün arayüz), logo ve başlıklarda Poppins
- Pencere düğmeleri: KDE'nin kendi Breeze çerçevesi (varsayılan hali); Atmaca'nın renkli daire
  düğmeli çerçevesi Sistem Ayarları'ndan seçilebilir
- Panel: altta yüzen panel; Dosyalar, Firefox, Uçbirim, Yazılım Merkezi ve Ayarlar sabitlenmiş
- Açılış: Plymouth'ta Atmaca logosu, KDE açılış ekranında logo ve ilerleme çubuğu
- Giriş ve kilit ekranı: Atmaca zeminleri
- Konsole (uçbirim): Atmaca renk teması

## Bilerek böyle bıraktıklarım

- **Uygulama logoları:** Firefox, Okular gibi uygulamaların logoları o projelerin markasıdır;
  değiştirmiyoruz.
- **GRUB menüsü:** Kurulu sistemde menü varsayılan olarak gizli (Shift ile açılır).
  USB'den açılışta görünen menünün yazısı "Start Atmaca Linux" oldu; görsel GRUB teması
  bir sonraki adımda eklenecek.
- **Görsellerin üretimi:** Görseller yapay zekâyla üretildi; 4K sürümler büyütülerek elde edildi. Çok büyük ekranlarda hafif yumuşaklık görülebilir.
- **Logonun vektör sürümü:** Şimdilik PNG; çizgileri ayrı ayrı düzenlenebilen bir vektör (SVG) sürümü yok. Bunun için logoyu bir tasarım programında yeniden çizmek gerekir.
