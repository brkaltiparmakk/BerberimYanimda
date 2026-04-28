# Berber Yanımda - Risk, Siber Güvenlik ve Operasyonel Ön Hazırlık Dokümanı

## 1. Dokümanın Amacı

Bu doküman, **Berber Yanımda** mobil uygulamasının ticari olarak yayınlanmadan önce karşılaşabileceği teknik, hukuki, operasyonel ve siber güvenlik risklerini belirlemek için hazırlanmıştır.

Amaç sadece saldırı olduktan sonra “kim yaptı bunu” diye monitöre bakmak değildir. Amaç; saldırı, veri sızıntısı, ödeme problemi, sistem kesintisi, kötüye kullanım ve kullanıcı güveni kaybı gibi riskleri önceden azaltmaktır.

Bu doküman aşağıdaki alanları kapsar:

- Siber güvenlik riskleri
- API güvenliği
- Mobil uygulama güvenliği
- Kullanıcı verisi güvenliği
- KVKK uyumluluğu
- Ödeme güvenliği
- Randevu sistemi kötüye kullanım riskleri
- Admin panel güvenliği
- Loglama ve izleme
- Yedekleme ve felaket kurtarma
- Sızma testi hazırlığı
- Yayın öncesi güvenlik kontrol listesi

## 2. Proje Kapsamı

### 2.1 Uygulama Tipi
Ticari mobil randevu uygulaması
Flutter iOS / Android uygulaması
REST API backend
Veritabanı destekli sistem
Online ödeme / berberde ödeme
Konum bazlı berber listeleme
Kullanıcı, berber sahibi, personel ve admin rolleri

### 2.2 Kritik Varlıklar

Bu projede korunması gereken kritik varlıklar şunlardır:

Kullanıcı hesapları
Telefon numaraları
E-posta adresleri
Profil bilgileri
Konum bilgileri
Randevu bilgileri
Ödeme işlem kayıtları
Berber işletme bilgileri
Personel bilgileri
Admin panel erişimi
API tokenları
Veritabanı bağlantı bilgileri
SMS / ödeme / Firebase API anahtarları

### 2.3 Hassas Veri Kategorileri

Uygulamada aşağıdaki hassas veya önemli veri türleri işlenebilir:

Ad soyad
Telefon numarası
E-posta adresi
Konum bilgisi
Randevu geçmişi
Ödeme işlem bilgisi
Cihaz token bilgisi
IP adresi
Kullanıcı işlem logları

KVKK tarafında kişisel verilerin hukuka aykırı işlenmesini ve erişimini önlemek, ayrıca verilerin güvenli muhafazasını sağlamak için teknik ve idari tedbirler alınması gerekir. KVKK’nın kişisel veri güvenliği rehberinde de veri sorumlularının bu konuda teknik ve idari tedbirler alması gerektiği açıkça belirtilir.

## 3. Temel Güvenlik Standartları

Bu proje için aşağıdaki güvenlik kaynakları referans alınmalıdır:

OWASP API Security Top 10
OWASP Mobile Top 10
OWASP ASVS
KVKK Kişisel Veri Güvenliği Rehberi
PCI-DSS ödeme güvenliği prensipleri

OWASP API Security Top 10, API’lerde özellikle nesne bazlı yetkilendirme hataları gibi yaygın risklere dikkat çeker. Bu proje API yoğun bir sistem olduğu için her ID bazlı erişimde kullanıcı yetkisi ayrıca kontrol edilmelidir.

Mobil uygulama tarafında OWASP Mobile Top 10 2024; hatalı kimlik bilgisi kullanımı, yetersiz tedarik zinciri güvenliği, güvensiz authentication/authorization, yetersiz input/output validation, güvensiz iletişim ve güvensiz veri saklama gibi başlıkları öne çıkarır. Flutter uygulaması yayınlanmadan önce bu başlıklar özellikle kontrol edilmelidir.

OWASP ASVS ise web ve API uygulamalarında güvenlik kontrollerinin hangi seviyede doğrulanacağını belirlemek için kullanılabilecek açık bir doğrulama standardıdır. Projede en az ASVS seviye 1, ödeme ve admin panel için ise daha yüksek seviye kontroller hedeflenmelidir.

## 4. Risk Sınıflandırması

Riskler aşağıdaki seviyelerde değerlendirilmelidir.

Kritik:
Veri sızıntısı, ödeme manipülasyonu, admin panel ele geçirilmesi, kullanıcı hesabı ele geçirilmesi.

Yüksek:
Yetkisiz randevu işlemi, başka kullanıcının verilerine erişim, API token çalınması, SMS/OTP kötüye kullanımı.

Orta:
Spam kayıt, sahte yorum, fake randevu, rate limit eksikliği, zayıf loglama.

Düşük:
UI hataları, küçük veri tutarsızlıkları, düşük etkili kullanım hataları.

## 5. Ana Risk Matrisi

| Risk | Etki | Olasılık | Seviye | Önlem |
| --- | --- | --- | --- | --- |
| Kullanıcı hesabı ele geçirilmesi | Yüksek | Orta | Kritik | Güçlü şifre, OTP, rate limit, refresh token güvenliği |
| Admin panel ele geçirilmesi | Çok yüksek | Orta | Kritik | MFA, IP kısıtı, rol bazlı yetki, audit log |
| Başka kullanıcının randevusunu görme | Yüksek | Orta | Kritik | Object level authorization |
| API brute force saldırısı | Orta | Yüksek | Yüksek | Rate limiting, captcha, IP bazlı koruma |
| OTP kötüye kullanımı | Orta | Yüksek | Yüksek | OTP süre limiti, tekrar gönderme limiti |
| Ödeme manipülasyonu | Çok yüksek | Orta | Kritik | Backend fiyat hesaplama, webhook doğrulama |
| Veritabanı sızıntısı | Çok yüksek | Düşük/Orta | Kritik | Şifreleme, erişim kısıtı, yedek güvenliği |
| Sahte randevu oluşturma | Orta | Yüksek | Yüksek | Telefon doğrulama, rate limit, iptal politikası |
| Sahte yorum | Orta | Orta | Orta | Sadece tamamlanan randevuya yorum |
| Konum verisinin kötüye kullanımı | Yüksek | Orta | Yüksek | Minimum veri toplama, izin yönetimi |
| Mobil app reverse engineering | Orta | Orta | Orta | Obfuscation, root/jailbreak kontrolleri |
| API key sızıntısı | Yüksek | Orta | Kritik | Secret manager, env, client tarafına secret koymama |
| DDoS saldırısı | Yüksek | Orta | Yüksek | CDN, WAF, rate limit, autoscale |
| Yedeklerden veri sızıntısı | Çok yüksek | Orta | Kritik | Şifreli yedek, erişim kısıtı |
| Loglarda hassas veri tutulması | Yüksek | Orta | Yüksek | Masking, log politikası |

## 6. API Güvenliği

### 6.1 Genel API Kuralları

Tüm API endpointleri aşağıdaki kurallara uymalıdır:

HTTPS dışında API erişimi olmamalıdır.
Tüm authenticated endpointler JWT ile korunmalıdır.
Her endpoint rol ve kullanıcı yetkisi kontrolü yapmalıdır.
Frontend’den gelen fiyat, süre, rol, kullanıcı ID gibi kritik değerlere güvenilmemelidir.
Pagination olmayan liste endpointi bırakılmamalıdır.
Tüm inputlar validate edilmelidir.
Hatalar kullanıcıya teknik detay sızdırmamalıdır.

### 6.2 Object Level Authorization

En kritik konulardan biridir. Kullanıcıdan gelen herhangi bir ID üzerinden işlem yapılacaksa backend şu soruyu sormalıdır:

Bu kullanıcı bu kayda erişmeye gerçekten yetkili mi?

Kötü örnek:

GET /api/v1/appointments/123

Sadece token geçerli diye randevu dönülmemelidir.

Doğru kontrol:

Appointment.CustomerUserId == AuthenticatedUserId
veya
Appointment.BarberShop.OwnerUserId == AuthenticatedUserId
veya
User.Role == Admin

OWASP API Security Top 10’da Broken Object Level Authorization ilk sırada yer aldığı için bu konu projenin en kritik güvenlik maddelerinden biridir.

### 6.3 Rate Limiting

Aşağıdaki limitler uygulanmalıdır:

Login:
Dakikada 5 istek / IP
Dakikada 5 istek / telefon numarası

OTP gönderme:
45 saniyede 1 istek
Günde maksimum 10 OTP / telefon numarası

OTP doğrulama:
5 hatalı deneme sonrası 10 dakika kilit

Register:
Dakikada 3 istek / IP

Randevu oluşturma:
Dakikada 5 istek / kullanıcı
Günde maksimum makul limit

Genel API:
Dakikada 100 istek / kullanıcı
Dakikada 300 istek / IP

### 6.4 API Versiyonlama
/api/v1/auth/login
/api/v1/barbers
/api/v1/appointments

Versiyonsuz API çıkılmamalıdır. Yoksa ileride “v1 miydi v2 miydi” diye production’da arkeoloji yapılır.

### 6.5 Güvenli Hata Mesajları

Yanlış:

{
  "message": "SQL Exception: Users table column PasswordHash..."
}

Doğru:

{
  "success": false,
  "message": "İşlem sırasında hata oluştu."
}

Login için yanlış:

Bu telefon numarası sistemde kayıtlı değil.

Daha güvenli:

Telefon numarası veya şifre hatalı.

## 7. Kimlik Doğrulama Güvenliği

### 7.1 Şifre Politikası
Minimum 8 karakter
En az 1 büyük harf
En az 1 küçük harf
En az 1 rakam
En az 1 özel karakter önerilir
Yaygın şifreler engellenmelidir
Şifre hashlenmeden saklanmamalıdır

### 7.2 Şifre Hashleme

Şifreler kesinlikle düz metin tutulmamalıdır.

Önerilen algoritmalar:

Argon2id
BCrypt
PBKDF2

.NET tarafında:

ASP.NET Core Identity PasswordHasher
veya BCrypt.Net

### 7.3 JWT Güvenliği
Access token kısa ömürlü olmalı: 15-60 dakika
Refresh token uzun ömürlü olabilir: 7-30 gün
Refresh token veritabanında hashli tutulmalıdır
Logout işleminde refresh token revoke edilmelidir
Token içine gereksiz kişisel veri koyulmamalıdır
JWT secret env veya secret manager içinde saklanmalıdır

### 7.4 Refresh Token Tablosu
CREATE TABLE RefreshTokens (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    TokenHash NVARCHAR(MAX) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    RevokedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    IpAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(MAX) NULL
);

### 7.5 OTP Güvenliği
OTP 6 haneli olmalı
3 dakika geçerli olmalı
45 saniye dolmadan tekrar gönderilmemeli
5 hatalı denemeden sonra geçici kilit uygulanmalı
OTP düz metin saklanmamalı, hashli saklanmalıdır
OTP SMS içeriğinde uygulama adı net yazmalıdır

Örnek SMS:

Berber Yanımda doğrulama kodunuz: 123456. Bu kod 3 dakika geçerlidir.

## 8. Mobil Uygulama Güvenliği

Flutter uygulaması için aşağıdaki kontroller uygulanmalıdır.

### 8.1 Client Secret Saklama Riski

Mobil uygulamanın içine kesinlikle şu bilgiler gömülmemelidir:

Veritabanı connection string
JWT secret
SMS provider key
Ödeme provider secret
Firebase server key
Admin token
Sabit API şifresi

Mobil uygulama herkesin cebinde çalışan bir yazılımdır. Yani “secret’ı app içine koydum kim görecek” fikri, anahtarı paspasın altına koyup “hırsız nereden bilsin” demek gibidir.

### 8.2 Güvenli İletişim
Tüm trafik HTTPS üzerinden olmalıdır.
HTTP endpoint bırakılmamalıdır.
TLS sertifikası geçerli olmalıdır.
Gerekirse certificate pinning değerlendirilebilir.
API base URL production ve test için ayrı olmalıdır.

OWASP Mobile Top 10’da güvensiz iletişim ve güvensiz veri saklama gibi başlıklar mobil uygulamalar için önemli riskler arasında yer alır.

### 8.3 Local Storage

Mobil cihazda saklanacak veriler sınırlı olmalıdır.

Saklanabilir:

Access token
Refresh token
Tema ayarı
Dil ayarı
Son kullanılan şehir

Saklanmamalı:

Şifre
Kart bilgisi
Admin bilgisi
Gizli API key
Tam ödeme bilgileri

Flutter tarafında öneri:

flutter_secure_storage

### 8.4 Root / Jailbreak Kontrolü

Production uygulamada değerlendirilebilir.

Root edilmiş Android cihaz
Jailbreak yapılmış iOS cihaz
Emulator tespiti
Debug mode kontrolü

Bu kontroller tek başına güvenlik sağlamaz ama riskli cihazlarda ek güvenlik uyarısı verilebilir.

### 8.5 Obfuscation

Flutter release build için obfuscation uygulanmalıdır.

flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info

## 9. Veritabanı Güvenliği

### 9.1 Temel Kurallar
Veritabanı public internete açık olmamalıdır.
Sadece backend sunucusu veritabanına erişebilmelidir.
Veritabanı kullanıcısı minimum yetkiye sahip olmalıdır.
Admin/root kullanıcı uygulamada kullanılmamalıdır.
Production ve test veritabanı ayrı olmalıdır.
Yedekler şifreli tutulmalıdır.

### 9.2 Hassas Alanlar

Aşağıdaki alanlar korunmalıdır:

PasswordHash
RefreshToken
OtpCode
Payment Provider Transaction Id
PhoneNumber
Email
DeviceToken

### 9.3 Migration Kontrolü
Migrationlar source control içinde tutulmalı
Production migration manuel onayla uygulanmalı
Veritabanı değişikliği öncesi yedek alınmalı
Rollback planı hazırlanmalı

### 9.4 Soft Delete

Ticari sistemlerde direkt silme risklidir.

Aşağıdaki tablolarda soft delete kullanılmalıdır:

Users
BarberShops
StaffMembers
BarberServices
Appointments
Reviews
Coupons

Örnek alan:

IsActive BIT NOT NULL DEFAULT 1
DeletedAt DATETIME2 NULL

## 10. Ödeme Güvenliği

### 10.1 Kritik Kural

Ödeme tutarı asla frontend’den gelen değere göre kabul edilmemelidir.

Yanlış:

{
  "appointmentId": "x",
  "amount": 10
}

Doğru:

Backend appointmentId üzerinden hizmetleri bulur.
Fiyatları veritabanından hesaplar.
Kuponu backend doğrular.
Ödeme tutarını backend oluşturur.

### 10.2 Kart Bilgisi

Kart bilgileri mümkünse uygulama backend’inde tutulmamalıdır.

Öneri:

iyzico / PayTR / Param gibi ödeme sağlayıcıların güvenli ödeme sayfası veya tokenizasyon yapısı kullanılmalı.
Kart numarası backend veritabanında saklanmamalı.
CVV kesinlikle saklanmamalı.

### 10.3 Webhook Güvenliği

Ödeme sağlayıcı callback/webhook endpointi mutlaka doğrulanmalıdır.

Kontroller:

Signature doğrulaması
IP whitelist, destekleniyorsa
Transaction ID kontrolü
Appointment ID kontrolü
Tutar eşleşmesi
Currency eşleşmesi
Aynı webhook tekrar gelirse ikinci kez işlem yapılmaması

Webhook idempotent olmalıdır.

Örnek:

Aynı ProviderTransactionId daha önce Paid olarak işlendi ise tekrar işlem yapma.

### 10.4 İade Süreci
Randevu iptal politikası tanımlanmalı
Online ödeme iadesi manuel veya otomatik olabilir
İade kaydı Payments tablosunda tutulmalı
Refund status ayrı izlenmeli

## 11. Admin Panel Güvenliği

Admin panel ticari uygulamanın kalbidir. Ayrıca saldırgan için açık büfe gibidir, insanlık yine menüye dönüşüyor.

### 11.1 Admin Erişim Kuralları
Admin panel ayrı subdomain üzerinden çalışmalı
Örnek: admin.berberyanimda.com
MFA zorunlu olmalı
Admin şifre politikası daha güçlü olmalı
IP kısıtı değerlendirilmeli
Admin işlemleri audit log’a yazılmalı
Admin token süresi kısa olmalı

### 11.2 Admin Rolleri

Tek bir admin rolü yerine alt roller tanımlanabilir.

SuperAdmin
SupportAdmin
FinanceAdmin
ContentModerator
BarberApprovalAdmin

### 11.3 Kritik Admin İşlemleri

Aşağıdaki işlemler mutlaka loglanmalıdır:

Kullanıcı pasife alma
Berber onaylama
Berber pasife alma
Ödeme durumu değiştirme
Randevu iptali
Kupon oluşturma
Admin kullanıcı oluşturma
Yetki değiştirme

Audit log örneği:

{
  "adminUserId": "admin-id",
  "action": "BARBER_APPROVED",
  "entityName": "BarberShop",
  "entityId": "barber-id",
  "ipAddress": "1.2.3.4",
  "createdAt": "2026-04-24T12:00:00"
}

## 12. KVKK ve Veri Mahremiyeti

### 12.1 Temel KVKK Ön Hazırlıkları

Ticari yayından önce aşağıdaki metinler hazırlanmalıdır:

Aydınlatma Metni
Gizlilik Politikası
Kullanım Şartları
Çerez Politikası, web varsa
Açık Rıza Metni, gerekiyorsa
Ticari Elektronik İleti Onayı, kampanya bildirimi varsa
Veri Saklama ve İmha Politikası

### 12.2 Minimum Veri İlkesi

Sadece gerçekten ihtiyaç duyulan veri alınmalıdır.

Örnek:

Randevu için telefon gerekir.
Doğum tarihi zorunlu olmamalıdır.
Konum izni sadece yakındaki berberleri göstermek için istenmelidir.
Kart bilgisi uygulama veritabanında tutulmamalıdır.

### 12.3 Kullanıcı Hakları

Kullanıcılar aşağıdaki işlemleri yapabilmelidir:

Profil bilgilerini görüntüleme
Profil bilgilerini güncelleme
Hesap silme talebi oluşturma
Bildirim izinlerini kapatma
Konum iznini kapatma
Kişisel verileri hakkında başvuru yapma

### 12.4 Veri Saklama Süreleri

Önerilen politika:

Aktif kullanıcı verisi: Hesap aktif olduğu sürece
Randevu kayıtları: Hukuki/ticari gereklilik süresince
Ödeme işlem kayıtları: Muhasebe ve mevzuat gerekliliklerine göre
OTP kayıtları: Maksimum 24 saat
Log kayıtları: 6-12 ay
Pasif cihaz tokenları: 90 gün sonra temizlenebilir

Bu süreler hukuk/mali müşavir değerlendirmesi ile netleştirilmelidir. Ben burada hukuk bürosu değilim, sadece pahalı hataları önceden işaretleyen tatsız bir alarmım.

## 13. Kötüye Kullanım Senaryoları

### 13.1 Sahte Randevu

Risk:

Kullanıcı sürekli randevu oluşturup iptal eder.
Berberin takvimini kilitler.
Gerçek müşteriler randevu alamaz.

Önlemler:

Telefon doğrulama zorunlu
Günlük randevu oluşturma limiti
Çok sık iptal eden kullanıcıyı riskli işaretleme
Online ön ödeme / kapora seçeneği
Berber tarafında kara liste özelliği

### 13.2 Spam Kayıt

Risk:

Botlar binlerce sahte kullanıcı oluşturur.
SMS maliyeti patlar.
Veritabanı kirlenir.

Önlemler:

Rate limit
reCAPTCHA / Turnstile
OTP gönderim limiti
IP bazlı limit
Telefon numarası bazlı limit
Geçici e-posta engelleme, e-posta kullanılıyorsa

### 13.3 Sahte Yorum

Risk:

Rakip berber kötü yorum basar.
Sahte hesaplarla puan manipülasyonu yapılır.

Önlemler:

Sadece tamamlanmış randevuya yorum
Her randevuya tek yorum
Şüpheli yorumları moderasyon kuyruğuna alma
Admin panelde yorum silme/pasife alma

### 13.4 Kupon Suiistimali

Risk:

Aynı kullanıcı sürekli yeni hesap açıp hoş geldin kuponu kullanır.

Önlemler:

Telefon bazlı kupon limiti
Cihaz bazlı risk kontrolü
Ödeme yöntemi bazlı risk kontrolü
IP bazlı anomali kontrolü
Kupon kullanım geçmişi

## 14. Loglama ve İzleme

### 14.1 Loglanması Gereken Olaylar
Başarılı giriş
Başarısız giriş
OTP gönderimi
OTP doğrulama hatası
Randevu oluşturma
Randevu iptal
Ödeme başlatma
Ödeme sonucu
Admin giriş
Admin kritik işlem
Yetkisiz erişim denemesi
API hata kayıtları
Rate limit aşımı

### 14.2 Loglarda Tutulmaması Gerekenler
Şifre
OTP kodu
Kart numarası
CVV
Refresh token düz metin
JWT token tam hali
Gizli API key

### 14.3 Log Masking

Örnek:

Telefon: +90555******33
E-posta: b****@example.com
Kart: **** **** **** 1234

### 14.4 İzleme Araçları

MVP için:

Serilog
Dosya log
Database audit log

Production için:

Seq
ElasticSearch / Kibana
Grafana Loki
Application Insights
Sentry

### 14.5 Alarm Senaryoları
5 dakika içinde çok fazla 500 hatası
Login başarısızlıklarında ani artış
OTP gönderiminde anormal artış
Payment webhook hataları
Database bağlantı hatası
CPU / RAM / disk kullanımının kritik seviyeye çıkması

## 15. Yedekleme ve Felaket Kurtarma

### 15.1 Yedekleme Gereksinimleri
Veritabanı günlük tam yedek
Kritik sistemlerde saatlik transaction/log backup
Görsel dosyalar için günlük yedek
Yedekler şifreli saklanmalı
Yedeklere erişim kısıtlı olmalı
Yedek geri dönüş testi düzenli yapılmalı

### 15.2 RPO / RTO Hedefleri
RPO, veri kaybı toleransı:
MVP için maksimum 24 saat
Ticari production için 1-4 saat önerilir

RTO, sistemi geri ayağa kaldırma süresi:
MVP için 8 saat
Ticari production için 1-4 saat önerilir

### 15.3 Felaket Senaryoları
Veritabanı bozulması
Sunucu çökmesi
Yanlış migration
Dosya storage kaybı
Ödeme webhook işleyememe
Saldırı sonrası sistem kapatma
Admin hesabı ele geçirilmesi

### 15.4 Geri Dönüş Testi

Ayda en az 1 kez test ortamına restore yapılmalıdır.

Kontrol listesi:

Backup açılıyor mu?
Veritabanı tutarlı mı?
Uygulama restore DB ile çalışıyor mu?
Görseller erişilebilir mi?
Randevu kayıtları doğru mu?
Ödeme kayıtları doğru mu?

## 16. Altyapı Güvenliği

### 16.1 Sunucu Güvenliği
SSH/RDP public açık olmamalı
Yönetim erişimi VPN üzerinden olmalı
Sunucular düzenli patchlenmeli
Firewall sadece gerekli portları açmalı
Production ortamında debug kapalı olmalı
Default kullanıcılar kapatılmalı
Güçlü parola ve MFA kullanılmalı

### 16.2 Açık Port Politikası

Örnek:

443 HTTPS açık
80 sadece HTTPS redirect için açık olabilir
Database portu public kapalı
SSH/RDP public kapalı
Admin panel mümkünse IP kısıtlı

### 16.3 WAF / CDN

Production için önerilir:

Cloudflare
AWS WAF
Azure Front Door / WAF
Nginx rate limit

Koruma alanları:

DDoS
Bot trafik
Rate limit
SQL injection denemeleri
XSS payloadları
Kötü IP reputation

## 17. CI/CD Güvenliği

### 17.1 Repository Güvenliği
Main branch korumalı olmalı
Pull request zorunlu olmalı
Kod review yapılmalı
Secret dosyaları commitlenmemeli
.env dosyaları gitignore içinde olmalı
Dependency güncellemeleri takip edilmeli

### 17.2 Pipeline Kontrolleri
Build
Unit test
Integration test
Static code analysis
Dependency vulnerability scan
Secret scan
Docker image scan, kullanılıyorsa

### 17.3 Secret Yönetimi

Kötü:

appsettings.json içine production şifresi yazmak
Flutter içine API secret koymak
GitHub’a .env dosyası atmak

Doğru:

Environment variables
Azure Key Vault
AWS Secrets Manager
GitHub Actions Secrets
Docker secrets

## 18. Sızma Testi Hazırlığı

Ticari yayından önce sızma testi yaptırılması önerilir.

### 18.1 Test Kapsamı
Mobil uygulama güvenlik testi
API sızma testi
Admin panel sızma testi
Authentication / authorization testi
Payment akışı testi
Rate limit testi
Dosya upload testi
JWT / refresh token testi
KVKK veri erişim testi

### 18.2 Test Kullanıcıları

Sızma testi için ayrı hesaplar oluşturulmalıdır:

Customer test kullanıcısı
BarberOwner test kullanıcısı
Staff test kullanıcısı
Admin test kullanıcısı
Pasif kullanıcı
Onaysız berber sahibi

### 18.3 Özellikle Test Edilecek Senaryolar
Başka kullanıcının randevusunu görme
Başka berberin hizmetini düzenleme
Frontend’den fiyat değiştirerek ödeme başlatma
JWT role claim değiştirerek admin endpointine erişme
OTP brute force
Login brute force
Dosya upload ile zararlı dosya yükleme
Webhook sahteciliği
Coupon tekrar kullanımı

## 19. Yayın Öncesi Güvenlik Kontrol Listesi

### 19.1 Backend
- [ ] HTTPS zorunlu
- [ ] JWT güvenli yapılandırıldı
- [ ] Refresh token DB’de hashli tutuluyor
- [ ] Şifreler hashli tutuluyor
- [ ] Role bazlı authorization var
- [ ] Object level authorization kontrolleri var
- [ ] Rate limit aktif
- [ ] Global exception middleware aktif
- [ ] Swagger production’da kapalı veya korumalı
- [ ] CORS sadece izinli domainlere açık
- [ ] Input validation aktif
- [ ] SQL injection riski için ORM/parameterized query kullanılıyor
- [ ] Loglarda hassas veri yok
- [ ] Admin işlemleri audit log’a yazılıyor

### 19.2 Mobil Uygulama
- [ ] Production build release modda
- [ ] Debug loglar kapalı
- [ ] API secret app içinde yok
- [ ] Token secure storage içinde saklanıyor
- [ ] HTTP endpoint kullanılmıyor
- [ ] Obfuscation aktif
- [ ] Hata mesajları teknik detay göstermiyor
- [ ] Konum izni açıklaması net
- [ ] Bildirim izni kullanıcıya açık anlatılıyor

### 19.3 Ödeme
- [ ] Kart bilgisi sistemde saklanmıyor
- [ ] Tutar backend tarafından hesaplanıyor
- [ ] Webhook signature doğrulanıyor
- [ ] Aynı webhook ikinci kez işlenmiyor
- [ ] Başarılı ödeme sonrası appointment status doğru güncelleniyor
- [ ] Failed ödeme senaryosu test edildi
- [ ] Refund / iptal süreci tanımlandı

### 19.4 KVKK
- [ ] Aydınlatma metni hazır
- [ ] Gizlilik politikası hazır
- [ ] Kullanım şartları hazır
- [ ] Açık rıza süreçleri değerlendirildi
- [ ] Ticari ileti izni ayrı alınıyor
- [ ] Hesap silme talebi süreci var
- [ ] Veri saklama politikası var
- [ ] Log ve yedek saklama süresi belirlendi

### 19.5 Operasyon
- [ ] Veritabanı yedekleri aktif
- [ ] Restore testi yapıldı
- [ ] Monitoring aktif
- [ ] Kritik hata alarmları aktif
- [ ] Production ortam değişkenleri güvenli
- [ ] Admin panel erişimi korumalı
- [ ] Incident response planı hazır

## 20. Olay Müdahale Planı

Saldırı veya veri sızıntısı şüphesi olduğunda izlenecek adımlar:

1. Olay tespit edilir.
2. Etkilenen sistem veya endpoint izole edilir.
3. Loglar korunur.
4. Admin ve teknik ekip bilgilendirilir.
5. Saldırı tipi belirlenir.
6. Gerekirse tokenlar revoke edilir.
7. Şifre sıfırlama süreci başlatılır.
8. Açık kapatılır.
9. Etkilenen kullanıcılar belirlenir.
10. Hukuki/KVKK bildirim gerekliliği değerlendirilir.
11. Kalıcı önlem alınır.
12. Olay sonrası rapor hazırlanır.

### 20.1 Olay Rapor Formatı
Olay Tarihi:
Tespit Eden:
Etkilenen Sistem:
Olay Türü:
Etkilenen Kullanıcı Sayısı:
Veri Sızıntısı Var mı:
Alınan İlk Aksiyon:
Kök Neden:
Kalıcı Çözüm:
Tekrar Yaşanmaması İçin Önlem:

## 21. Ticari Riskler

### 21.1 Kullanıcı Güveni Riski

Risk:

Randevu oluşturulmasına rağmen berberin haberi olmaması
Ödeme alınıp randevu oluşmaması
Konum hatalı gösterilmesi
Bildirimlerin gitmemesi

Önlemler:

Randevu transaction içinde oluşturulmalı
Ödeme ve randevu status akışı net olmalı
Bildirim başarısız olsa bile sistem randevuyu kaybetmemeli
Kullanıcıya işlem sonucu net gösterilmeli

### 21.2 Berber Tarafı Operasyon Riski

Risk:

Berber uygulamayı aktif kullanmazsa müşteri mağdur olur.
Randevular unutulur.
Çalışma saatleri yanlış girilir.

Önlemler:

Berber paneli
SMS / push bildirim
Randevu onay mekanizması
Çalışma saati doğrulama
Pasif işletmeleri listede geri plana atma

### 21.3 İtibar Riski

Risk:

Veri sızıntısı
Sahte yorum
Ödeme sorunu
Sistem kesintisi

Önlemler:

Güvenlik testleri
Moderasyon
Şeffaf destek süreci
Loglama
Hızlı olay müdahale planı

## 22. Güvenlik Önceliklendirme Planı

### 22.1 MVP Öncesi Zorunlu
JWT authentication
Role based authorization
Object level authorization
Şifre hashleme
OTP rate limit
HTTPS
Input validation
Backend fiyat hesaplama
Payment webhook doğrulama
Admin audit log
Veritabanı yedeği
KVKK temel metinleri

### 22.2 Yayından Hemen Sonra
Sızma testi
WAF / CDN
Monitoring alarmları
Mobil obfuscation
Log merkezi sistemi
Gelişmiş rate limit
Admin MFA

### 22.3 Ölçeklenme Fazı
Risk scoring
Fraud detection
Device fingerprint
Anomali tespiti
SIEM entegrasyonu
Düzenli vulnerability scan
Düzenli backup restore testi

## 23. Geliştiriciye Verilecek Net Güvenlik Kuralları

Backend geliştirici aşağıdaki kuralları ihlal etmemelidir:

Frontend’den gelen fiyat kabul edilmeyecek.
Frontend’den gelen role bilgisi kabul edilmeyecek.
Her ID bazlı endpointte sahiplik kontrolü yapılacak.
Şifreler düz metin tutulmayacak.
OTP düz metin tutulmayacak.
Refresh token düz metin tutulmayacak.
Kart bilgisi veritabanında saklanmayacak.
Admin işlemleri logsuz yapılmayacak.
Production hata mesajında stack trace gösterilmeyecek.
Database public internete açılmayacak.
.env veya secret dosyaları Git’e atılmayacak.

## 24. Örnek Güvenli Randevu Oluşturma Kontrol Akışı
1. Kullanıcı token doğrulanır.
2. Kullanıcının telefon doğrulaması kontrol edilir.
3. Berber aktif ve onaylı mı kontrol edilir.
4. Hizmetler aktif mi kontrol edilir.
5. Personel aktif mi kontrol edilir.
6. Personel bu hizmetleri verebiliyor mu kontrol edilir.
7. Hizmetlerin toplam süresi backend’de hesaplanır.
8. Hizmetlerin toplam fiyatı backend’de hesaplanır.
9. Seçilen tarih geçmiş tarih mi kontrol edilir.
10. Çalışma saatleri kontrol edilir.
11. Mola saatleri kontrol edilir.
12. Mevcut randevularla çakışma kontrol edilir.
13. Randevu transaction içinde oluşturulur.
14. AppointmentServices snapshot olarak yazılır.
15. Bildirim kuyruğa alınır.
16. Kullanıcıya güvenli response dönülür.

## 25. Örnek Güvenli Ödeme Akışı
1. Kullanıcı randevu oluşturur.
2. Backend randevu fiyatını hesaplar.
3. Kullanıcı ödeme başlatır.
4. Backend payment provider session oluşturur.
5. Kullanıcı ödeme sağlayıcı üzerinden ödeme yapar.
6. Payment provider webhook gönderir.
7. Backend webhook signature doğrular.
8. Backend transaction ID daha önce işlendi mi kontrol eder.
9. Tutar, para birimi ve appointment eşleşmesi kontrol edilir.
10. Payment status Paid yapılır.
11. Appointment status Confirmed yapılır.
12. Kullanıcıya ve berbere bildirim gönderilir.

## 26. Sonuç

Berber Yanımda ticari olarak yayınlanacaksa güvenlik, ödeme ve veri koruma konuları en baştan sistemin içine yerleştirilmelidir. Sonradan eklenen güvenlik, genelde yamalı pantolon gibi durur; iş görür ama kimse gurur duymaz.

Bu doküman, projenin ilk ticari sürümü için minimum güvenlik ve risk hazırlık temelini oluşturur. Geliştirme başlamadan önce backend, mobil, admin panel ve altyapı tarafındaki tüm ekipler bu dokümanı referans almalıdır.
