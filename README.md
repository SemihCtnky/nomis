# Kilitçim - Kuyumcu Yönetim Sistemi

Kilitçim, kuyumcu atölyeleri için tasarlanmış profesyonel bir iOS uygulamasıdır. SwiftUI ve SwiftData teknolojileri kullanılarak geliştirilmiştir.

## ✨ Özellikler

### Ana Özellikler
- **Rol Tabanlı Erişim**: Admin ve görüntüleyici rolleri
- **Otomatik Kaydetme**: 3 saniyede bir taslak kaydetme
- **Güvenli Kimlik Doğrulama**: Keychain tabanlı güvenli şifre saklama
- **Kapsamlı Yedekleme**: JSON/CSV export/import + ZIP desteği
- **Gelişmiş Analiz**: Tarih, ayar ve kart bazlı fire analizi

### 📱 Modüller

#### 1. Şarnel
- Ayar ve altın giriş/çıkış takibi
- Demirli değerler (3 hücre + hurda + toz)
- Otomatik altın oranı hesaplama
- Asit çıkışı tablosu (dinamik satır ekleme)
- Fire hesaplama ve özet raporlama

#### 2. Kilit Toplama
- Model, firma, ayar, tarih takibi
- Kasa/Dil/Yay/Kilit kategorileri
- Giriş/Çıkış (Adet/Gram) tablosu
- Otomatik fire ve özet hesaplamaları
- Süre takibi ve verimlilik raporları

#### 3. Günlük İşlemler
- 7 farklı işlem kartı:
  - **Tezgah** (2 kart): Giriş/Çıkış takibi
  - **Cila**: Cila işlemleri
  - **Ocak**: Ocak işlemleri
  - **Patlatma**: Patlatma işlemleri
  - **Tambur**: Tambur işlemleri
  - **Makine Kesme**: Makine kesme işlemleri
  - **Testere Kesme**: Testere kesme işlemleri
- Haftalık form yönetimi (Pazartesi-Cuma)
- Her kart için ayrı ayar ve fire takibi
- Haftalık fire özeti
- Tamamlanmış formlar düzenlenemez

#### 4. Notlar
- Basit not alma sistemi
- Otomatik zaman damgası
- Başlık ve içerik desteği
- Düzenleme geçmişi

#### 5. Analiz
- **Kilit Toplama Analizi**: Model, firma, ayar bazlı raporlar
- **Şarnel Analizi**: Fire ve altın oranı analizleri
- **Günlük İşlemler Analizi**: Kart bazlı fire takibi
- Tarih aralığı filtreleme (Haftalık/Aylık/Yıllık)
- Ayar seçimi ve filtreleme
- PDF ve CSV export
- Grafik ve özet raporlar

#### 6. Yedekleme
- Tam veri export/import
- JSON ve CSV formatları
- ZIP arşiv desteği
- Veri kurtarma ve taşıma

#### 7. Ayarlar
- **Model Yönetimi**: Model ekleme, düzenleme, silme (sadece admin)
- **Firma Yönetimi**: Firma ekleme, düzenleme, silme (sadece admin)
- **Uygulama Bilgileri**: Versiyon ve geliştirici bilgileri
- **Çıkış Yapma**: Güvenli oturum kapatma

## 🔐 Kullanıcı Rolleri ve Hesaplar

### Admin
```
Kullanıcı Adı: admin
Şifre: 9023
```
**Yetkiler:**
- Tüm formları oluşturma, düzenleme, silme
- Model ve firma yönetimi
- Kullanıcı yönetimi
- Tüm ayarlara erişim

### Görüntüleyici Hesapları
```
Kullanıcı Adı: kadir
Şifre: 2390

Kullanıcı Adı: yalçın
Şifre: 4806
```
**Yetkiler:**
- Tüm verileri görüntüleme (salt-okunur)
- Form ve kayıtları inceleme
- Düzenleme ve silme yetkisi yok
- Model/firma ekleme/düzenleme yok

## 🏗️ Teknik Detaylar

### Mimari
- **UI Framework**: SwiftUI
- **Veri Katmanı**: SwiftData
- **Güvenlik**: Keychain Services
- **Hedef Platform**: iPadOS 17+, iPhone uyumlu
- **Swift Versiyonu**: 5.10+

### Tasarım
- **Tema**: Lüks ve profesyonel
- **Renk Paleti**: 
  - Derin yeşil (ana renk)
  - Altın vurgular
  - Krem/Off-white arkaplanlar
- **Tipografi**: System font, başlıklarda semibold
- **Bileşenler**: Yuvarlatılmış kartlar, hafif gölgeler

### Yerelleştirme
- **Dil**: Türkçe (tr)
- **Locale**: tr_TR
- **Tarih/Sayı Formatları**: Türkiye standartları

## 📊 Veri Modelleri

### Şarnel Form
```swift
- karatAyar: Int
- girisAltin/cikisAltin: Double?
- demirli_1/2/3: Double?
- demirliHurda/Toz: Double?
- asitCikislari: [AsitItem]
- altinOrani: Double? (computed)
- fire: Double? (computed)
```

### Kilit Toplama Form
```swift
- model: String?
- firma: String?
- ayar: Int?
- startedAt/endedAt: Date?
- kasa/dil/yay/kilit: [KilitKategori]
- toplamGirisGram/toplamCikisGram: Double
- fireGram: Double (computed)
```

### Günlük Form
```swift
- baslamaTarihi/bitisTarihi: Date
- gunlukVeriler: [GunlukGunVerisi] (5 gün)
- isWeeklyCompleted: Bool
```

### Not
```swift
- title: String
- text: String
- createdAt: Date
- lastEditedAt: Date?
- createdByUsername: String
- lastEditedByUsername: String?
```

## 💾 Güvenlik ve Veri Yönetimi

### Kimlik Doğrulama
- Keychain'de güvenli şifre saklama
- Oturum yönetimi
- Rol tabanlı erişim kontrolü

### Veri Güvenliği
- Otomatik taslak kaydetme (3 saniye)
- Background/foreground geçişlerinde kaydetme
- Hata toleranslı veri işleme
- Güvenli backup/restore mekanizması

### Önemli Özellikler
- **Satır Sıralaması**: Günlük işlemlerde satırların sırası asla değişmez
- **Fire Hesaplaması**: Negatif fire değerleri otomatik olarak 0'a yuvarlanır
- **Haftalık Tamamlama**: Tamamlanan formlar düzenlenemez
- **Admin Koruması**: Kritik işlemler için admin şifresi gerektirir

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Xcode 15.4+
- iOS 17.0+ (iPad için optimize)
- Swift 5.10+

### Adımlar
1. Projeyi Xcode'da açın
2. Bundle ID'yi kendi ID'nize değiştirin (Signing & Capabilities)
3. Team'inizi seçin
4. Simulator veya gerçek cihazda çalıştırın

### İlk Çalıştırma
1. Uygulama açıldığında login ekranı görünür
2. Yukarıdaki hesaplardan biriyle giriş yapın
3. Ana ekranda 7 modül kartını görürsünüz
4. Tüm modüller tam fonksiyoneldir

## 📝 API Referansı

### Formatters
- `safeFormat()`: Güvenli sayı formatı (nil kontrolü)
- `dateTimeFormatter`: Türkçe tarih/saat formatı
- `turkishNumberFormatter`: Ondalık sayı formatı (virgül ayracı)

### Theme
- `primaryGreen`: Ana renk (#2D5D3F)
- `accent`: Vurgu rengi
- `nomisCard()`: Kart stil modifier'ı
- `PrimaryButtonStyle`: Ana buton stili

## 📱 Proje Durumu

### ✅ Tamamlanan Özellikler
- Tüm 7 modül tam fonksiyonel
- Rol tabanlı erişim kontrolü
- Otomatik kaydetme sistemi
- Gelişmiş analiz ve raporlama
- Yedekleme ve veri transfer
- Model/Firma yönetimi
- Not sistemi

### 🎯 Uygulama Hazır Durumda
Bu uygulama üretim için hazırdır ve App Store'a yüklenebilir.

## 📞 İletişim

**Not**: Bu uygulama profesyonel kuyumcu atölyeleri için tasarlanmış, üretim seviyesinde bir yönetim sistemidir.

---

**Versiyon**: 1.0.0  
**Son Güncelleme**: Ekim 2025  
**Platform**: iOS 17.0+