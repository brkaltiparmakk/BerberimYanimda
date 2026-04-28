# Berber Yanımda - Flutter UI Tasarım Dokümanı

## 1. Proje Özeti

**Uygulama Adı:** Berber Yanımda  
**Platform:** Flutter  
**Hedef Platformlar:** iOS ve Android  
**Tasarım Dili:** Premium koyu tema  
**Genel Stil:** Modern, minimal, lüks berber/barbershop estetiği  
**Ana Renk Yapısı:** Siyah, koyu gri ve altın vurgu rengi  

Berber Yanımda uygulaması; kullanıcıların yakınındaki berberleri keşfetmesini, hizmet seçmesini, personel seçmesini, tarih/saat belirlemesini, ödeme yapmasını ve randevularını yönetmesini sağlayan mobil bir randevu uygulamasıdır.

Tasarım Flutter ile rahat uygulanabilir, component bazlı, tekrar kullanılabilir ve responsive olacak şekilde geliştirilmelidir.

---

# 2. Genel Tasarım Kuralları

## 2.1 Tema

Uygulama genelinde **premium koyu tema** kullanılacaktır.

Ana his:

- Koyu arka plan
- Altın vurgu rengi
- Yuvarlatılmış kartlar
- Temiz ve okunabilir tipografi
- Minimal ama şık arayüz
- Gereksiz kalabalıktan uzak mobil deneyim

## 2.2 UI Yaklaşımı

Tasarımda component yapısı tutarlı olmalıdır. Aynı tipteki butonlar, kartlar, inputlar, chipler ve listeler tüm ekranlarda aynı kurallarla kullanılmalıdır.

Flutter tarafında tasarım şu yapı ile ilerlemelidir:

- `ThemeData`
- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppRadius`
- Ortak reusable widgetlar
- Feature bazlı ekran yapısı

---

# 3. Renk Paleti

## 3.1 Ana Renkler

```dart
class AppColors {
  static const backgroundPrimary = Color(0xFF0B0B0D);
  static const backgroundSecondary = Color(0xFF111114);

  static const cardBackground = Color(0xFF18181B);
  static const cardBackgroundLight = Color(0xFF202024);

  static const borderColor = Color(0xFF2A2A2E);

  static const primaryGold = Color(0xFFD6A84F);
  static const primaryGoldLight = Color(0xFFF0C76A);
  static const primaryGoldDark = Color(0xFFA97C2E);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B8B8);
  static const textMuted = Color(0xFF7A7A7A);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}
3.2 Renk Kullanım Kuralları
Ana arka plan her zaman #0B0B0D olmalıdır.
Kart arka planlarında #18181B kullanılmalıdır.
İkincil kartlarda veya hover/selected durumlarında #202024 kullanılabilir.
Primary Gold sadece önemli aksiyonlarda kullanılmalıdır:
Randevu Al
Devam Et
Kaydet
Onayla
Aktif tab/chip
Seçili tarih/saat
Uzun açıklama metinlerinde beyaz yerine Text Secondary kullanılmalıdır.
Pasif alanlar gri tonlarda gösterilmelidir.
Hata, iptal ve çıkış işlemleri kırmızı tonlarla belirtilmelidir.
4. Tipografi
4.1 Font Ailesi

Flutter için önerilen ana font:

Inter

Alternatif fontlar:

Poppins

Premium başlık alternatifi:

Playfair Display
Cormorant Garamond
4.2 Text Style Yapısı
class AppTextStyles {
  static const largeTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
}
4.3 Kullanım Alanları
Büyük Başlık

Örnek:

Merhaba Burak 👋

Kullanım:

Ana sayfa header
Onboarding başlıkları
Başarılı işlem ekranları
Ekran Başlığı

Örnek:

Randevu Oluştur

Kullanım:

AppBar title
Sayfa başlığı
Bölüm Başlığı

Örnek:

Yakındaki Berberler

Kullanım:

Liste başlıkları
Kart grupları
Form bölümleri
Normal Metin

Kullanım:

Açıklama metinleri
Kart açıklamaları
Yardımcı bilgiler
5. Layout Sistemi
5.1 Genel Ölçüler
class AppSpacing {
  static const double screenHorizontal = 20;
  static const double screenVertical = 16;

  static const double cardPadding = 16;

  static const double itemSpacing = 12;
  static const double sectionSpacing = 16;
  static const double bottomButtonSpacing = 20;
}
5.2 Border Radius
class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
}
5.3 Sayfa Kuralları
Tüm ekranlarda SafeArea kullanılmalıdır.
Sayfa horizontal padding değeri genellikle 20px olmalıdır.
Uzun sayfalarda SingleChildScrollView, CustomScrollView veya ListView kullanılmalıdır.
Alt kısımda kritik aksiyon varsa sticky bottom button kullanılmalıdır.
Minimum dokunulabilir alan yüksekliği 44px olmalıdır.
Ekran taşmalarına karşı Flexible, Expanded, FittedBox ve TextOverflow.ellipsis kullanılmalıdır.
6. Buton Sistemi
6.1 Primary Button

En önemli aksiyonlar için kullanılacaktır.

Kullanım alanları:

Randevu Al
Devam Et
Giriş Yap
Kayıt Ol
Randevuyu Onayla
Kaydet
Ana Sayfaya Dön

Özellikler:

Height: 52px
Width: double.infinity
Background: #D6A84F
Text Color: #0B0B0D
Border Radius: 14px
Font Size: 15-16
Font Weight: 600

Örnek widget adı:

PrimaryButton

Örnek kullanım:

PrimaryButton(
  text: 'Randevu Al',
  onPressed: () {},
)
6.2 Secondary Button

İkincil aksiyonlar için kullanılacaktır.

Kullanım alanları:

Takvime Ekle
Randevularım
Yol Tarifi Al
Berberi Ara
Detayları Gör

Özellikler:

Height: 48px
Background: transparent veya #18181B
Border: 1px #2A2A2E
Text Color: #FFFFFF
Border Radius: 14px
Font Weight: 500

Örnek widget adı:

SecondaryButton
6.3 Danger Button

Riskli işlemler için kullanılacaktır.

Kullanım alanları:

Randevuyu İptal Et
Çıkış Yap
Hesabı Sil

Özellikler:

Height: 48-52px
Background: #EF4444
Text Color: #FFFFFF
Border Radius: 14px
Font Weight: 600

Örnek widget adı:

DangerButton
6.4 Small Button

Kart içi kısa aksiyonlar için kullanılacaktır.

Kullanım alanları:

Randevu Al
Detayları Gör
Uygula

Özellikler:

Height: 34-38px
Horizontal Padding: 12-16px
Background: #D6A84F
Text Color: #0B0B0D
Border Radius: 10px
Font Size: 12-13
Font Weight: 600
7. Input Alanları
7.1 TextField

Tüm form alanlarında ortak input componenti kullanılmalıdır.

Özellikler:

Height: 52px
Background: #18181B
Border: 1px #2A2A2E
Focused Border: 1px #D6A84F
Border Radius: 14px
Text Color: #FFFFFF
Hint Color: #7A7A7A
Horizontal Padding: 14px
Icon Color: #B8B8B8

Örnek widget adı:

AppTextField

Kullanım örnekleri:

Ad Soyad
Telefon numarası
E-posta
Şifre
Kupon kodunuzu girin
7.2 Search Input

Arama alanı özel component olarak hazırlanmalıdır.

Özellikler:

Height: 48-52px
Background: #18181B
Border Radius: 14px
Left Icon: Search
Right Icon: Filter
Hint: Berber, hizmet veya semt ara

Örnek widget adı:

SearchInput
8. Chip / Filtre Sistemi
8.1 Category Chip

Kategoriler ve filtreler için kullanılacaktır.

Örnek chipler:

Tümü
Popüler
Erkek Kuaförü
Sakal
Cilt Bakımı
Yakınımda
En Yüksek Puan
Müsait Olanlar
En Uygun Fiyat
Favoriler
8.2 Aktif Chip
Background: #D6A84F
Text Color: #0B0B0D
Border Radius: 20px
Padding: horizontal 10px, vertical 8px
Font Size: 12-13
Font Weight: 600
8.3 Pasif Chip
Background: #18181B
Border: 1px #2A2A2E
Text Color: #B8B8B8
Border Radius: 20px

Örnek widget adı:

CategoryChip
9. Kart Componentleri
9.1 BarberCard

Ana sayfa, keşfet ve favoriler ekranlarında kullanılacaktır.

Özellikler:

Background: #18181B
Border: 1px #2A2A2E
Border Radius: 16px
Padding: 12px
Image Size: 86x86px
Image Radius: 12px

İçerik:

Berber adı
Puan
Yorum sayısı
Semt
Mesafe
Başlangıç fiyatı
Müsaitlik durumu
Favori ikonu
Randevu Al butonu

Örnek veri:

Modern Barber
⭐ 4.8 (120)
Kadıköy, İstanbul
1.2 km
Başlangıç ₺250
Bugün müsait

Widget adı:

BarberCard
9.2 ServiceCard

Hizmet seçimi ekranında kullanılacaktır.

Özellikler:

Background: #18181B
Border Radius: 14px
Padding: 14px
Height: 58-68px
Selected Border: #D6A84F

İçerik:

Checkbox
Hizmet adı
Süre
Fiyat

Örnek:

Saç Kesimi     30 dk     ₺250
Sakal Tıraşı   20 dk     ₺150

Widget adı:

ServiceCard
9.3 StaffCard

Personel seçimi ekranında kullanılacaktır.

Özellikler:

Background: #18181B
Border Radius: 16px
Padding: 14px
Selected Border: 1.5px #D6A84F

İçerik:

Profil fotoğrafı
Personel adı
Uzmanlık
Puan
Müsaitlik durumu
Radio button

Örnek:

Mehmet Usta
Saç Kesimi Uzmanı
⭐ 4.9
Bugün müsait

Widget adı:

StaffCard
9.4 AppointmentCard

Randevularım ve randevu detay alanlarında kullanılacaktır.

Özellikler:

Background: #18181B
Border Radius: 16px
Padding: 14px

İçerik:

Berber fotoğrafı
Berber adı
Tarih
Saat
Personel
Hizmetler
Fiyat
Durum etiketi

Durum renkleri:

Yaklaşan: Gold
Onaylandı: Green
Tamamlandı: Gray
İptal Edildi: Red

Widget adı:

AppointmentCard
10. Bottom Navigation

Ana ekranlarda sabit bottom navigation kullanılmalıdır.

10.1 Sekmeler
Ana Sayfa
Keşfet
Randevularım
Favoriler
Profil
10.2 Tasarım Özellikleri
Height: 72-80px
Background: #0B0B0D
Border Top: 1px #2A2A2E
Active Icon Color: #D6A84F
Active Text Color: #D6A84F
Inactive Icon Color: #7A7A7A
Inactive Text Color: #7A7A7A
Font Size: 11-12
Icon Size: 22-24
10.3 İkon Önerileri
Ana Sayfa: home
Keşfet: search
Randevularım: calendar
Favoriler: heart
Profil: user

Widget adı:

AppBottomNavBar
11. AppBar Sistemi
11.1 Standart AppBar
Background: #0B0B0D
Elevation: 0
Title Color: #FFFFFF
Title Font Size: 18-20
Title Weight: 600
Back Icon Color: #FFFFFF
Action Icon Color: #FFFFFF

Kullanım alanları:

Randevu Oluştur
Hizmet Seçimi
Personel Seçimi
Tarih ve Saat Seçimi
Randevu Özeti
Ödeme
Profil Düzenle
Ayarlar
Yardım & Destek

Widget adı:

CustomAppBar
11.2 Ana Sayfa Header

Ana sayfada klasik AppBar yerine özel header kullanılabilir.

İçerik:

Merhaba Burak 👋
İstanbul, Kadıköy
Profil avatarı
Bildirim ikonu

Widget adı:

HomeHeader
12. Görsel Kullanımı
12.1 Berber Görselleri
Sıcak ışıklı berber salonu fotoğrafları kullanılmalıdır.
Görseller koyu temaya uyumlu olmalıdır.
Çok parlak ve beyaz ağırlıklı görsellerden kaçınılmalıdır.
Görsellerin üzerine hafif siyah gradient uygulanabilir.
12.2 Image Radius
Small Image Radius: 10px
Card Image Radius: 12px
Header Image Radius: 0 veya alt köşelerde 24px
Avatar Radius: Circle
12.3 Placeholder

Görsel yüklenmezse:

Background: #202024
Icon: scissors veya image
Icon Color: #7A7A7A

Widget önerisi:

AppNetworkImage
BarberImage
AvatarImage
13. Ekran Listesi

Uygulamada aşağıdaki ekranlar bulunmalıdır.

13.1 Splash Screen

Amaç:

Uygulama açılış ekranıdır.

İçerik:

Logo
Berber Yanımda
Berberin cebinde.
Loading bar veya küçük progress indicator

Tasarım:

Background: #0B0B0D
Logo Color: #D6A84F
App Name: büyük ve premium
Subtitle: #B8B8B8
13.2 Onboarding Screen

Amaç:

Kullanıcıya uygulamanın temel faydasını anlatır.

Onboarding adımları:

Yakındaki berberleri keşfet
Kolayca randevu al
Güvenli ödeme yap

İçerik:

Üstte büyük görsel
Başlık
Açıklama
Sayfa indikatörü
İleri butonu
Atla butonu
13.3 Login Screen

İçerik:

Hoş Geldin!
Hesabına giriş yap
Telefon numarası
Şifre
Şifremi unuttum?
Giriş Yap
Google ile devam et
Apple ile devam et
Hesabın yok mu? Kayıt Ol

Tasarım notu:

Form alanları koyu kart içinde olabilir. Sosyal giriş butonları secondary button tarzında olmalıdır.

13.4 Register Screen

İçerik:

Hesap Oluştur
Ad Soyad
Telefon
E-posta
Şifre
Şifre Tekrar
Kayıt Ol
Zaten hesabın var mı? Giriş Yap
13.5 OTP Doğrulama Screen

İçerik:

Doğrulama Kodu
Telefonunuza gönderilen 6 haneli kodu giriniz
6 adet kod kutusu
Kodu tekrar gönder
Sayaç: 00:45

Tasarım:

Kod kutuları: 44x52px
Selected border: #D6A84F
13.6 Ana Sayfa

İçerik:

Merhaba Burak 👋
İstanbul, Kadıköy
Search bar
Kategori chipleri
Yakındaki Berberler
Popüler Hizmetler
Bugün Müsait Olanlar
Bottom Navigation

Kategori chipleri:

Tümü
Popüler
Erkek Kuaförü
Sakal
Cilt Bakımı

Berber kartı örneği:

Modern Barber
⭐ 4.8 (120)
1.2 km
Saç Kesimi • Sakal • Bakım
Başlangıç ₺250
Bugün müsait
Randevu Al
13.7 Berber Listeleme Screen

İçerik:

Search bar
Filtre chipleri
Berber listesi

Filtreler:

Yakınımda
En Yüksek Puan
Müsait Olanlar
En Uygun Fiyat
Favoriler
13.8 Harita Screen

İçerik:

Harita
Berber pinleri
Alt selected barber card
Detayları Gör butonu

Tasarım:

Map style koyu tema olabilir
Selected pin gold olmalı
Alt kart draggable bottom sheet gibi olmalı
13.9 Berber Detay Screen

İçerik:

Kapak görseli
Geri butonu
Favori butonu
Berber adı
Puan
Yorum sayısı
Mesafe
Adres
Açık/Kapalı durumu
Çalışma saatleri
Hizmetler
Çalışanlar
Yorumlar
Galeri
Konum
Sticky Randevu Al butonu

Tab yapısı:

Hizmetler
Çalışanlar
Yorumlar
Galeri
Konum
13.10 Hizmet Seçimi Screen

İçerik:

Hizmet Seçimi
Almak istediğiniz hizmetleri seçin
Saç Kesimi - 30 dk - ₺250
Sakal Tıraşı - 20 dk - ₺150
Saç + Sakal - 45 dk - ₺400
Damat Tıraşı - 60 dk - ₺800
Cilt Bakımı - 30 dk - ₺300
Saç Boyama - 45 dk - ₺600
Toplam Süre
Toplam Tutar
Devam Et

Seçili hizmet:

Checkbox selected
Border Gold
13.11 Personel Seçimi Screen

İçerik:

Personel Seçimi
Hizmetinizi kimin yapmasını istersiniz?
Mehmet Usta
Ali Öncel
Enes Yıldız
Farketmez
Devam Et

Personel kartında:

Avatar
Ad
Uzmanlık
Puan
Müsaitlik
Radio seçimi
13.12 Tarih ve Saat Seçimi Screen

İçerik:

Tarih ve Saat Seçimi
Uygun tarih ve saati seçin
Yatay tarih selector
Saat slotları
Devam Et

Tarih kutusu:

Width: 54-62px
Height: 72px
Selected Background: #D6A84F
Selected Text: #0B0B0D
Inactive Background: #18181B

Saat slotu:

Height: 44px
Border Radius: 12px
Selected Background: #D6A84F
Unavailable Background: #111114
Unavailable Text: #4B4B4B
13.13 Randevu Özeti Screen

İçerik:

Randevu Özeti
Lütfen bilgilerinizi kontrol edin
Berber
Hizmetler
Personel
Tarih
Saat
Adres
Notunuz
Toplam Tutar
Devam Et

Not alanı:

Çok satırlı TextField
Hint: Saç çok kısa olmasın.
13.14 Ödeme Screen

İçerik:

Ödeme
Ödeme yönteminizi seçin
Kayıtlı Kartlar
Yeni Kart Ekle
Ödeme Yöntemi
Online Ödeme
Berberde Öde
Kupon Kodu
Toplam Tutar
Randevuyu Onayla

Kart listesi örneği:

**** 5678
12/58
Visa / Mastercard icon
13.15 Randevu Başarılı Screen

İçerik:

Büyük success ikonu
Randevun oluşturuldu!
Modern Barber
Tarih
Saat
Personel
Hizmetler
Tutar
Takvime Ekle
Randevularım
Ana Sayfaya Dön

Tasarım:

Başarı ikonu yeşil olmalı
Ana aksiyon altın buton olmalı
13.16 Randevularım Screen

İçerik:

Randevularım
Yaklaşan
Geçmiş
İptal Edilen
Randevu kartları

Durumlar:

Onaylandı
Yaklaşan
Tamamlandı
İptal Edildi
13.17 Randevu Detay Screen

İçerik:

Randevu Detay
Durum etiketi
Berber görseli
Berber adı
Adres
Tarih
Saat
Personel
Hizmetler
Tutar
Berberi Ara
Yol Tarifi Al
Randevuyu İptal Et
13.18 Favoriler Screen

İçerik:

Favorilerim
Favori berber kartları
Kalp ikonu aktif kırmızı veya gold
Randevu Al
13.19 Bildirimler Screen

İçerik:

Bildirimler
Randevunuz onaylandı
Randevunuza 1 saat kaldı
Kampanya
Randevunuz iptal edildi
Ödeme başarılı

Bildirim tipleri:

Info icon
Success icon
Warning icon
Error icon
13.20 Profil Screen

İçerik:

Profil
Profil kartı
Ad Soyad
Telefon
E-posta
Profili Düzenle
Favorilerim
Ödeme Yöntemlerim
Bildirimler
Ayarlar
Yardım & Destek
Çıkış Yap
13.21 Profil Düzenleme Screen

İçerik:

Profil Düzenle
Avatar
Ad Soyad
Telefon
E-posta
Doğum Tarihi
Kaydet
13.22 Ayarlar Screen

İçerik:

Ayarlar
Bildirim Ayarları
Konum İzni
Tema
Dil
Gizlilik Politikası
Kullanım Şartları
Hesabı Sil
13.23 Yardım & Destek Screen

İçerik:

Yardım & Destek
Sıkça Sorulan Sorular
Bize Ulaşın
Canlı Destek
Sorun Bildir
14. Randevu Akışı

Randevu alma süreci kullanıcıyı yormayacak şekilde adım adım ilerlemelidir.

Akış:

Berber Detay
↓
Hizmet Seçimi
↓
Personel Seçimi
↓
Tarih ve Saat Seçimi
↓
Randevu Özeti
↓
Ödeme
↓
Randevu Başarılı

Alternatif kısa akış:

Ana Sayfa / Liste
↓
Randevu Al
↓
Hizmet Seç
↓
Personel Seç
↓
Tarih/Saat Seç
↓
Özet
↓
Ödeme / Onay
15. Animasyon Kuralları

Flutter uygulamasında hafif animasyonlar kullanılmalıdır.

Page transition: 250-300ms
Button press scale: 0.98
Card tap ripple: subtle
Loading shimmer: Berber kartlarında kullanılabilir
Success animation: Lottie veya custom check animation

Dikkat:

Abartılı animasyonlardan kaçınılmalıdır.
Premium uygulama hissi korunmalıdır.
Sayfa geçişleri sade, hızlı ve akıcı olmalıdır.
16. İkon Sistemi
16.1 Önerilen İkon Paketleri
Lucide Icons
Phosphor Icons
Material Symbols Rounded
16.2 Kullanılacak İkonlar
scissors
calendar
clock
map-pin
star
heart
user
home
search
bell
settings
credit-card
logout
phone
navigation
check-circle
x-circle
gift
tag
filter
16.3 İkon Kuralları
Icon Size: 20-24px
Active Icon Color: #D6A84F
Inactive Icon Color: #7A7A7A
Danger Icon Color: #EF4444
Default Icon Color: #B8B8B8
17. Flutter Component Listesi

Aşağıdaki componentler ortak widget olarak hazırlanmalıdır.

PrimaryButton
SecondaryButton
DangerButton
SmallButton

AppTextField
SearchInput
PasswordTextField
OtpInput

CategoryChip
FilterChip

BarberCard
ServiceCard
StaffCard
AppointmentCard
NotificationItem
ProfileMenuItem
PaymentMethodCard
CouponCard
PriceSummaryCard

DateSelector
TimeSlotGrid

AppBottomNavBar
CustomAppBar
HomeHeader
SectionHeader

AppNetworkImage
AvatarImage
StatusBadge
RatingView
EmptyState
LoadingShimmer
18. Önerilen Flutter Klasör Yapısı
lib/
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_theme.dart
│   │   ├── app_spacing.dart
│   │   └── app_radius.dart
│   │
│   ├── constants/
│   │   └── app_assets.dart
│   │
│   └── widgets/
│       ├── buttons/
│       │   ├── primary_button.dart
│       │   ├── secondary_button.dart
│       │   └── danger_button.dart
│       │
│       ├── inputs/
│       │   ├── app_text_field.dart
│       │   └── search_input.dart
│       │
│       ├── cards/
│       │   ├── barber_card.dart
│       │   ├── service_card.dart
│       │   ├── staff_card.dart
│       │   └── appointment_card.dart
│       │
│       ├── navigation/
│       │   └── app_bottom_nav_bar.dart
│       │
│       └── common/
│           ├── section_header.dart
│           ├── status_badge.dart
│           └── app_network_image.dart
│
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── otp_screen.dart
│   │
│   ├── home/
│   │   └── home_screen.dart
│   │
│   ├── barber/
│   │   ├── barber_list_screen.dart
│   │   ├── barber_detail_screen.dart
│   │   └── map_screen.dart
│   │
│   ├── booking/
│   │   ├── service_selection_screen.dart
│   │   ├── staff_selection_screen.dart
│   │   ├── date_time_selection_screen.dart
│   │   ├── appointment_summary_screen.dart
│   │   ├── payment_screen.dart
│   │   └── appointment_success_screen.dart
│   │
│   ├── appointments/
│   │   ├── appointments_screen.dart
│   │   └── appointment_detail_screen.dart
│   │
│   ├── favorites/
│   │   └── favorites_screen.dart
│   │
│   ├── notifications/
│   │   └── notifications_screen.dart
│   │
│   └── profile/
│       ├── profile_screen.dart
│       ├── edit_profile_screen.dart
│       ├── settings_screen.dart
│       └── support_screen.dart
│
└── main.dart
19. Responsive Kurallar

Tasarım minimum 360px genişlikte düzgün çalışmalıdır.

Kurallar:

Minimum cihaz genişliği: 360px
Standart tasarım genişliği: 390px
Büyük ekranlarda max content width korunmalı
Text overflow durumlarında ellipsis kullanılmalı
Kartlar ekran dışına taşmamalı
Butonlar minimum 44px yüksekliğinde olmalı

Flutter tarafında kullanılabilecek yapılar:

MediaQuery
LayoutBuilder
Flexible
Expanded
FittedBox
SafeArea
SingleChildScrollView
CustomScrollView
SliverList
20. Durum Yönetimi Notları

Tasarım dokümanı UI odaklıdır. Ancak geliştirici tarafında aşağıdaki state yapıları dikkate alınmalıdır.

20.1 Ana State Alanları
Kullanıcı bilgileri
Konum bilgisi
Berber listesi
Favoriler
Seçili berber
Seçili hizmetler
Seçili personel
Seçili tarih
Seçili saat
Ödeme yöntemi
Randevu durumu
Bildirimler
20.2 Önerilen State Management

Projeye göre aşağıdaki yapılardan biri kullanılabilir:

Riverpod
Bloc / Cubit
Provider
GetX

Kurumsal ve uzun vadeli yapı için öneri:

Riverpod veya Bloc
21. Dummy Data Önerileri

Geliştirme sürecinde UI testleri için mock data kullanılmalıdır.

21.1 Barber Model
class Barber {
  final String id;
  final String name;
  final String district;
  final String city;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int startingPrice;
  final bool isAvailableToday;
  final String imageUrl;
  final bool isFavorite;
}
21.2 Service Model
class BarberService {
  final String id;
  final String name;
  final int durationMinutes;
  final int price;
  final bool isSelected;
}
21.3 Staff Model
class Staff {
  final String id;
  final String name;
  final String expertise;
  final double rating;
  final bool isAvailableToday;
  final String avatarUrl;
}
21.4 Appointment Model
class Appointment {
  final String id;
  final String barberName;
  final String barberImageUrl;
  final DateTime dateTime;
  final String staffName;
  final List<String> services;
  final int totalPrice;
  final AppointmentStatus status;
}

enum AppointmentStatus {
  upcoming,
  confirmed,
  completed,
  cancelled,
}
22. Tasarımda Dikkat Edilecekler
Tüm ekranlarda metinler okunabilir olmalıdır.
Gold renk fazla kullanılmamalıdır.
Kartlar arası boşluk yeterli olmalıdır.
Bottom navigation ana ekranlarda sabit olmalıdır.
Kritik aksiyonlar alt kısımda sticky button olarak konumlandırılmalıdır.
Form ekranları sade olmalıdır.
Hatalı inputlar kırmızı border ve kısa açıklama göstermelidir.
Loading, empty ve error stateleri ayrıca tasarlanmalıdır.
Görseller uygulamaya premium hava katmalıdır.
Randevu akışı sade ve anlaşılır olmalıdır.
Aynı component farklı ekranlarda tekrar kullanılmalıdır.
Her ekranda gereksiz bilgi kalabalığından kaçınılmalıdır.
23. Geliştirici İçin İlk Yapılacaklar

Flutter geliştirici aşağıdaki sırayla ilerleyebilir:

1. AppColors dosyasını oluştur
2. AppTextStyles dosyasını oluştur
3. AppTheme yapısını kur
4. Ortak buton componentlerini oluştur
5. Input componentlerini oluştur
6. Kart componentlerini oluştur
7. Bottom navigation yapısını hazırla
8. Auth ekranlarını geliştir
9. Ana sayfa ve listeleme ekranlarını geliştir
10. Randevu akış ekranlarını geliştir
11. Profil, ayarlar ve destek ekranlarını geliştir
12. Responsive kontrolleri yap
13. Dummy data ile UI testlerini tamamla
24. Öncelikli MVP Ekranları

İlk sürüm için aşağıdaki ekranlar önceliklidir:

Splash Screen
Onboarding Screen
Login Screen
Register Screen
Ana Sayfa
Berber Listeleme Screen
Berber Detay Screen
Hizmet Seçimi Screen
Personel Seçimi Screen
Tarih ve Saat Seçimi Screen
Randevu Özeti Screen
Ödeme Screen
Randevu Başarılı Screen
Randevularım Screen
Profil Screen

İkinci faza bırakılabilecek ekranlar:

Harita Screen
Bildirimler Screen
Favoriler Screen
Profil Düzenleme Screen
Ayarlar Screen
Yardım & Destek Screen
25. Genel Tasarım Promptu

Aşağıdaki prompt, Figma AI, görsel üretim aracı veya UI tasarım asistanına verilebilir.

Berber Yanımda isimli Flutter mobil uygulaması için yüksek çözünürlüklü, okunabilir, premium koyu temalı UI tasarım seti oluştur.

Tasarım siyah, koyu gri ve altın renk paleti kullanmalı. Tüm ekranlar gerçek mobil uygulama ekranı gibi görünmeli. Her ekran iPhone veya Android telefon frame içinde gösterilmeli. Bütün ekranlarda Türkçe metinler okunabilir olmalı.

UI modern, minimal, lüks ve Flutter ile uygulanabilir component yapısında olmalı.

Renkler:
Background: #0B0B0D
Card Background: #18181B
Secondary Card: #202024
Primary Gold: #D6A84F
Text Primary: #FFFFFF
Text Secondary: #B8B8B8
Text Muted: #7A7A7A
Border: #2A2A2E
Success: #22C55E
Error: #EF4444

Ekranlar:
Splash Screen
Onboarding
Login
Register
OTP Doğrulama
Ana Sayfa
Berber Listeleme
Harita
Berber Detay
Hizmet Seçimi
Personel Seçimi
Tarih ve Saat Seçimi
Randevu Özeti
Ödeme
Randevu Başarılı
Randevularım
Randevu Detay
Favoriler
Bildirimler
Profil
Profil Düzenleme
Ayarlar
Yardım & Destek

Tasarım kuralları:
Butonlar yuvarlatılmış olmalı.
Kartlar yuvarlatılmış ve temiz olmalı.
Bottom navigation 5 sekmeli olmalı.
Aktif sekme gold renkte olmalı.
Tüm ekranlar okunabilir olmalı.
Her ekranın adı altında yazmalı.
Tasarım Figma/Dribbble kalitesinde olmalı.
Flutter geliştiricisinin kolayca uygulayabileceği net component yapısı bulunmalı.
26. Teslim Kriterleri

Geliştirici işi teslim ederken aşağıdaki kriterler kontrol edilmelidir:

Tüm renkler AppColors üzerinden yönetiliyor mu?
Text stilleri AppTextStyles üzerinden geliyor mu?
Butonlar ortak component olarak mı kullanılmış?
Kartlar tekrar kullanılabilir widget mı?
Bottom navigation tüm ana ekranlarda tutarlı mı?
SafeArea tüm ekranlarda kullanılmış mı?
Responsive taşma sorunu var mı?
Minimum 360px genişlikte düzgün çalışıyor mu?
Dark tema tüm ekranlarda tutarlı mı?
Randevu akışı eksiksiz çalışıyor mu?
Loading, empty ve error stateleri var mı?
27. Genel Not

Bu doküman, Berber Yanımda Flutter mobil uygulamasının UI geliştirme sürecinde temel referans olarak kullanılmalıdır. Geliştirici, ekranları bu component sistemi üzerinden inşa etmeli ve tasarım tutarlılığını tüm uygulama boyunca korumalıdır.