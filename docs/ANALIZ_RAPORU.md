# /docs Analiz Raporu

## 1. Genel Proje Özeti

**Berber Yanımda**, Flutter ile geliştirilen iOS/Android mobil uygulama ve .NET 8 Web API backend üzerine kurulu, konum bazlı berber randevu ve ödeme platformudur.

- **Hedef Kullanıcılar:** Müşteriler (Customer), Berber Sahipleri (BarberOwner), Personel (Staff), Sistem Yöneticileri (Admin)
- **Temel Modüller:** Kimlik doğrulama (Auth), Berber yönetimi, Hizmet/Personel yönetimi, Randevu oluşturma/iptal, Uygunluk/slot hesaplama, Ödeme (Online + Berberde Öde), Favoriler, Yorumlar, Bildirimler, Kupon, Destek talepleri, Admin panel backend'i
- **Genel Mimari:**
  - **Backend:** .NET 8 Web API, Entity Framework Core, Clean Architecture (Api / Application / Domain / Infrastructure katmanları), JWT Authentication, Rate Limiting, Global Exception Middleware, HealthChecks
  - **Veritabanı:** PostgreSQL / SQL Server destekli (Migrations mevcut)
  - **Mobil:** Flutter, premium koyu tema (siyah + altın), component bazlı yapı
  - **Ödeme:** iyzico/PayTR/Param entegrasyonu için altyapı hazır (PaymentProviderFactory pattern)

---

## 2. Mevcut Dokümanların Özeti

### 2.1 backend.md
- **Kapsam:** Backend mimarisi, veritabanı şeması, API endpoint tasarımı, güvenlik gereksinimleri, ödeme entegrasyonu, background jobs, cache, loglama, MVP kapsamı, .NET klasör yapısı, entity/enum listesi, test senaryoları ve production kontrol listesi.
- **Ana Konular:** JWT + Refresh Token, OTP (6 hane / 3 dk / 45 sn / 5 deneme), 18 tablo şeması, 14 modül, 50+ endpoint, randevu slot hesaplama mantığı, güvenli ödeme akışı, idempotent webhook.
- **Eksik Kalan Noktalar:**
  - `SupportTicketReply` tablosu dokümanda yok (kodda mevcut).
  - `PaymentMethod` enum değerleri kodla tam olarak uyuşmuyor.
  - `Coupon` tablo yapısı kodda farklı (`DiscountType`/`DiscountValue` yerine `DiscountAmount`/`DiscountPercentage`).
  - `AppointmentStatus.Upcoming` statüsüne geçiş mantığı (job/timer) anlatılmamış.
  - Admin MFA, IP kısıtı, WAF/CDN detayları yok.

### 2.2 dikkatedilecekler.md
- **Kapsam:** Siber güvenlik, API güvenliği, mobil uygulama güvenliği, KVKK/veri mahremiyeti, ödeme güvenliği, admin panel güvenliği, loglama/izleme, yedekleme/felaket kurtarma, CI/CD güvenliği, sızma testi hazırlığı, yayın öncesi güvenlik kontrol listesi.
- **Ana Konular:** OWASP referansları, Object Level Authorization, Rate Limiting, JWT güvenliği, şifre hashleme, root/jailbreak, obfuscation, KVKK metinleri, veri saklama süreleri, olay müdahale planı.
- **Eksik Kalan Noktalar:**
  - Rate limit tablosunda OTP için policy örneği yok (sadece login/register/appointment/genel).
  - Flutter içinde certificate pinning önerisi detaylı anlatılmamış.
  - Log merkezi sistem önerisi (Seq/ElasticSearch) kodda yok.

### 2.3 tasarım.md
- **Kapsam:** Flutter UI/UX tasarım dokümanı, renk paleti, tipografi, layout sistemi, buton/input/kart componentleri, ekran listesi, randevu akışı, animasyon kuralları, responsive kurallar, state management önerisi, klasör yapısı, teslim kriterleri.
- **Ana Konular:** Premium koyu tema (#0B0B0D + #D6A84F), 22+ ekran tanımı, component bazlı widget listesi, Riverpod/Bloc önerisi, randevu adım adım akışı.
- **Eksik Kalan Noktalar:**
  - Error state / empty state / loading state UI örnekleri eksik.
  - Offline mod / ağ hatası durumları için tasarım yok.
  - Accessibility (erişilebilirlik) kuralları yok.
  - Deep linking / universal linking tasarımı yok.
  - Tablet/landscape responsive kurallar yetersiz.

### 2.4 screens.png
- **Kapsam:** Figma benzeri tasarım örneği. Renk paleti, tipografi, butonlar, kartlar, chip'ler ve 5 ana ekran (Ana Sayfa, Berber Detay, Randevu Oluştur, Ödeme, Randevularım).
- **Eksik:** Statik görsel; etkileşimli prototip veya animasyon akışı yok.

---

## 3. Tespit Edilen Eksiklikler

| No | Eksiklik | Etki/Risk | Önerilen Çözüm | Öncelik |
|---|---|---|---|---|
| 1 | **Randevu onaylama (`confirm`) ve tamamlama (`complete`) API endpointleri kodda yok.** | Berber sahibi/personel randevuyu onaylayamaz/tamamlayamaz. Randevu akışı eksik kalır. İşletme operasyonu çöker. | `AppointmentsController`'a `POST {id}/confirm` ve `POST {id}/complete` endpointleri eklenmeli. Yetki: BarberOwner, Staff, Admin. | Kritik |
| 2 | **Randevu oluşturma transaction içinde değil.** | Aynı slot'a eşzamanlı iki kullanıcı randevu alabilir (race condition). Çakışma kontrolü yapılsa bile `SaveChangesAsync` arasında pencere oluşur. | `BookingService.CreateAsync` içinde `using var transaction = await db.Database.BeginTransactionAsync()` kullanılmalı. Slot kontrolü ve kayıt aynı transaction içinde olmalı. | Kritik |
| 3 | **AuditLog hiç kullanılmıyor.** | Admin işlemleri, kritik kullanıcı aksiyonları izlenemiyor. KVKK denetiminde ve güvenlik olaylarında kayıt yok. Sorumlu tutulamazsın. | `AuditLogService` oluştur. Admin işlemleri, ödeme durum değişiklikleri, berber onay/pasif, kullanıcı pasif alma işlemlerinde `AuditLog` tablosuna kayıt at. | Kritik |
| 4 | **Admin MFA (Multi-Factor Authentication) yok.** | Admin hesabı ele geçirilirse tüm sistem açık büfe. Tek şifre yeterli. | Admin girişinde OTP veya TOTP (Authenticator App) zorunlu tutulmalı. `AdminUsers` tablosuna `MfaEnabled`/`MfaSecret` kolonları eklenebilir. | Kritik |
| 5 | **Kupon yapısında `DiscountType` ve `DiscountValue` birleşimi kodda yok.** | Kodda `DiscountAmount` ve `DiscountPercentage` ayrı nullable kolonlar var. İkisi birden dolu olursa hesaplama hatası/istismar riski. | Tek bir `DiscountType` enum'u (`Percentage`, `FixedAmount`) ve tek `DiscountValue` kolonu tutulmalı. Ya da DB seviyesinde CHECK constraint eklenmeli: `CHECK ((DiscountAmount IS NULL) != (DiscountPercentage IS NULL))`. | Yüksek |
| 6 | **Payment tablosunda `ProviderTransactionId` üzerinde unique index yok.** | Aynı ödeme sağlayıcı transaction'ı iki kez işlenirse çift kayıt/kesinti riski. Webhook idempotency'si sadece aynı Payment kaydı üzerinde çalışır. | `CREATE UNIQUE INDEX IX_Payments_ProviderTransactionId ON Payments(ProviderTransactionId) WHERE ProviderTransactionId IS NOT NULL;` | Yüksek |
| 7 | **Swagger production'da sadece kapalı, korumalı değil.** | Yetkisiz kişi production API dokümantasyonunu göremez ama kapalı değilse görür. `Program.cs`'de `if (app.Environment.IsDevelopment())` bloğunda sadece kapalı. | Production'da Swagger'ı tamamen kapat veya `Basic Auth` / IP whitelist ile koru. `SwaggerUIOptions` üzerinden `SwaggerEndpoint` sadece admin erişimine açık yapılabilir. | Yüksek |
| 8 | **CORS development ve testing ortamında `AllowAnyOrigin`.** | Testing ortamına sızan bir kişi API'yi kendi domaininden çağırabilir. Development'ta bile ileride staging/production karışabilir. | Testing ortamında da `Cors:AllowedOrigins` config'den oku. `AllowAnyOrigin` sadece local geliştirici makinesinde (localhost) çalışsın. | Yüksek |
| 9 | **`AppointmentStatus.Upcoming` statüsüne geçiş job'ı yok.** | Randevu onaylandıktan sonra ne zaman `Upcoming` olacağı belirsiz. Bildirimler ve filtrelemeler karışır. | Background job (Hangfire/Quartz) ile randevu tarihine 24 saat kala `Confirmed` -> `Upcoming` geçişi yap. Veya statik bir computed property olarak döndür. | Yüksek |
| 10 | **Berber sahibi/personel için mobil ekran yok.** | Dokümanda sadece müşteri ekranları var. BarberOwner ve Staff rolleri için panel/ekran tanımlanmamış. İşletme sahibi uygulamayı kullanamaz. | Ayrı bir "Berber Paneli" veya "Personel Paneli" ekran seti tanımla. Bottom navigation farklı olabilir. Minimum: Randevularım (işletme bazlı), Onayla/Reddet, Çalışma saatlerim. | Yüksek |
| 11 | **Şifre politikasında özel karakter kontrolü yok.** | Doküman "en az 1 özel karakter önerilir" diyor. `AuthService` sadece büyük/küçük/rakam kontrol ediyor. | `AuthService.RegisterAsync` içine `!request.Password.Any(ch => !char.IsLetterOrDigit(ch))` kontrolü ekle. | Orta |
| 12 | **`BarberShop.AverageRating` ve `StaffMember.AverageRating` otomatik güncellenmiyor.** | Yorum yapıldığında ortalama puan değişmez. Kullanıcı eski puana göre karar verir. | `ReviewService.CreateAsync` içinde yorum onaylandıktan sonra ilgili `BarberShop` ve `StaffMember` için `AverageRating` ve `ReviewCount` güncellenmeli. | Orta |
| 13 | **Mobil uygulamada offline mod ve ağ hatası state'i eksik.** | Kullanıcı uçak modunda veya zayıf şebekede uygulamayı kullanamaz. Hata yönetimi yetersiz. | `ApiClient` içinde `SocketException`, `TimeoutException` yakalanmalı. `Connectivity_plus` paketi ile offline detection yapılmalı. Offline cache (Hive/sembast) eklenmeli. | Orta |
| 14 | **KVKK aydınlatma metni ve gizlilik politikası içerikleri eksik.** | Ticari yayında yasal risk. Mağaza reddi (App Store / Google Play) ve idari para cezası. | Mobil uygulamaya "Gizlilik Politikası" ve "Kullanım Şartları" ekranları eklenmeli. Kayıt öncesi kullanıcıdan açık rıza alınmalı (checkbox). | Orta |
| 15 | **Hesap silme (Right to Erasure / KVKK) endpointi eksik.** | Kullanıcı hesabını silemez. KVKK ihlali. | `DELETE /api/v1/users/me` endpointi eklenmeli. Soft delete (`DeletedAt = now`) yapılmalı. Kişisel veriler maskelenmeli veya anonimleştirilmeli. | Orta |
| 16 | **`PayAtBarber` akışında berber onayı kontrolü yok.** | Doküman "Berber onayı gerekiyorsa Pending kalır" diyor. Kodda direkt `Confirmed` yapılıyor. | Configürasyona bağlı olarak `BerberShops.RequireApproval` alanı eklenebilir. Veya varsayılan olarak `Pending` kalıp berber onaylasın. | Orta |
| 17 | **Loglarda hassas veri maskeleme yok.** | Telefon, e-mail, tokenlar loglanıyor olabilir. `GlobalExceptionMiddleware` ve `Serilog` yapılandırması incelenmeli. | `Serilog` için `PhoneNumber`, `Email`, `PasswordHash`, `Token` alanlarını maskeleyen `ILogEventEnricher` yaz. | Orta |
| 18 | **Rate limiting sadece Auth ve Appointment için tanımlı, OTP için ayrı policy yok.** | OTP brute force riski azaltılmış ama API katmanında ayrı rate limit yok. | `EnableRateLimiting("Auth")` OTP endpointine de uygulanabilir veya ayrı `"Otp"` policy tanımlanabilir. | Orta |
| 19 | **File Upload endpointi kodda eksik veya incelenmemiş.** | Dokümanda `POST /api/v1/files/upload` var. Kodda `FilesController` görülmedi. Dosya validasyonu, virus taraması, mime type kontrolü yapılmıyor olabilir. | `FilesController` oluştur. Maksimum 5MB, jpg/png/webp, dosya adı GUID, MIME type kontrolü (sadece image/*), imza kontrolü (magic bytes). | Orta |
| 20 | **SupportTicketReply tablosu dokümanda yok.** | Kodda mevcut ama backend.md'de `SupportTickets` altında bahsedilmemiş. Doküman bütünlüğü bozuk. | `backend.md` 6. bölümüne `SupportTicketReplies` tablosu eklenmeli. | Düşük |
| 21 | **PaymentMethod enum uyumsuzluğu (Kod vs Doküman).** | Doküman: `OnlineCard, PayAtBarber, Wallet`. Kod: `PayAtBarber, Online, OnlineCard, Wallet`. `Online` fazladan. API response/client uyumsuzluğu. | Enum değerleri tekilleştirilmeli. `Online` ve `OnlineCard` aynı şeyse birleştirilmeli. | Düşük |
| 22 | **Admin panel frontend'i yok.** | Backend admin endpointleri (`AdminBarbersController`) var ama admin UI yok. | Blazor / React / Vue ile ayrı admin frontend projesi oluşturulmalı. Veya mevcut mobil uygulamaya "Admin" rolü için gizli ekranlar eklenebilir (önerilmez). | Düşük |
| 23 | **Tablet/landscape responsive tasarım eksik.** | Doküman sadece portre mobil (360-390px) için. Tablet kullanıcı deneyimi bozuk olur. | `LayoutBuilder` ve `OrientationBuilder` kullanılarak tablet için 2-kolonlu grid veya genişletilmiş kart tasarımları eklenebilir. | Düşük |

---

## 4. Teknik Mimari Değerlendirme

### 4.1 Backend
- **Mimari:** Clean Architecture prensiplerine uygun 4 katmanlı yapı (Api / Application / Domain / Infrastructure). Dependency Inversion doğru uygulanmış.
- **Güçlü Yönler:** Entity Framework Core migrations, soft delete query filter'ları (`HasQueryFilter`), password hashing (BCrypt benzeri), JWT + Refresh Token, rate limiting, global exception middleware, health checks.
- **Zayıf Yönler:** Audit log mekanizması soyut, transaction yönetimi eksik, admin MFA yok, file upload controller yok, Swagger production kontrolü zayıf.

### 4.2 Frontend (Flutter)
- **Mimari:** `lib/src/core/`, `features/`, `data/` şeklinde modüler yapı. Component bazlı widgetlar (Button, Card, Input) oluşturulmuş.
- **Güçlü Yönler:** Tema sistemi (`AppColors`, `AppTextStyles`), `ApiClient` refresh token mekanizması, secure storage, release mod HTTP koruması, dummy data desteği.
- **Zayıf Yönler:** State management dosyası (`app_state.dart`) mevcut ama Riverpod/Bloc kullanılıp kullanılmadığı net değil. Offline destek yok. Error/empty state'ler tanımlı widget olarak var (`EmptyState`, `LoadingShimmer`) ama her ekranda kullanılıp kullanılmadığı belirsiz.

### 4.3 Veritabanı
- **Mimari:** PostgreSQL/SQL Server destekli. Migration'lar mevcut. Soft delete (`DeletedAt`) 7 entity'de var. Indexler çoğunlukla uygulanmış.
- **Güçlü Yönler:** Unique index'ler (telefon, favori, refresh token hash, staff-service, kupon kodu, cihaz token), precision tanımları (`decimal(18,2)`), foreign key delete behavior'ları dikkatli ayarlanmış.
- **Zayıf Yönler:** `ProviderTransactionId` unique değil, `SupportTicketReply` dokümanda yok, `Coupon` tablo yapısı dokümana uymuyor.

### 4.4 API
- **Versiyonlama:** `/api/v1/` prefix kullanılıyor. Standart `ApiResponse<T>` wrapper'ı var.
- **Güçlü Yönler:** Input validation `ApiBehaviorOptions` ile merkezi, JWT scheme, rate limiting attribute'ları.
- **Zayıf Yönler:** `Admin` endpointlerinde `[Authorize(Roles = "Admin")]` kullanılıyor mu net değil (incelediğim controller'lar customer odaklı). Object level authorization servis seviyesinde yapılıyor, bu iyi ama defence-in-depth için endpoint seviyesinde de ek kontroller eklenebilir.

### 4.5 Kimlik Doğrulama
- **JWT:** Access token + Refresh token. Refresh token veritabanında hashli (`SecureHasher`). Revoke mekanizması var (`LogoutAsync` tüm tokenları revoke ediyor).
- **OTP:** 6 hane, 3 dakika, 45 sn cooldown, 5 deneme, 10 dk kilit. `OtpCode` tablosunda `AttemptCount` ve `LockedUntil` var. Günlük 10 SMS limiti var.
- **Eksik:** Şifre özel karakter kontrolü, admin MFA.

### 4.6 Dosya Yönetimi
- Dokümanda CDN/Local storage seçenekleri var. Kodda `IStorageService` implementasyonu görülmedi. MVP için local storage kullanılabilir ama production'da object storage (AWS S3/Cloudflare R2) geçilmeli.

### 4.7 Bildirim Sistemi
- `PushNotificationService.cs` var. `DeviceToken` tablosu var. Kodda `Notification` entity'si doğrudan DB'ye yazılıyor (in-app notification). Push notification için Firebase Cloud Messaging entegrasyonu bekleniyor.

### 4.8 Ödeme Sistemi
- `PaymentProviderFactory` pattern ile iyzico/PayTR entegrasyonu hazır. Webhook signature doğrulama, idempotency, tutar/eşleşme kontrolü mevcut.
- **Eksik:** Webhook IP whitelist, `ProviderTransactionId` unique index, iade (refund) endpointi.

---

## 5. Backend İçin Yapılması Gerekenler

### 5.1 Randevu Onaylama / Tamamlama Endpointleri
- **Problem:** Berber sahibi ve personel randevuyu onaylayamaz/tamamlayamaz.
- **Neden gerekli:** İşletme operasyonu için temel akış.
- **Nasıl yapılmalı:**
```csharp
[HttpPost("{appointmentId:guid}/confirm")]
[Authorize(Roles = nameof(UserRole.BarberOwner) + "," + nameof(UserRole.Staff))]
public async Task<ActionResult<ApiResponse<AppointmentDto>>> Confirm(Guid appointmentId, CancellationToken ct)
{
    var result = await bookingService.ConfirmAsync(appointmentId, User.GetUserId(), User.GetRole(), ct);
    return Ok(ApiResponse<AppointmentDto>.Ok(result, "Randevu onaylandı."));
}
```
- **Servis:** `BookingService.ConfirmAsync` içinde `EnsureCanAccess` kontrolü, status `Pending` -> `Confirmed` güncellemesi, bildirim gönderimi.

### 5.2 Transaction Koruması (Race Condition Önlemi)
- **Problem:** Aynı saate iki kullanıcı eşzamanlı randevu alabilir.
- **Neden gerekli:** Veri tutarlılığı.
- **Nasıl yapılmalı:**
```csharp
public async Task<AppointmentDto> CreateAsync(...)
{
    await using var transaction = await db.Database.BeginTransactionAsync(ct);
    // ... slot kontrolü ...
    db.Appointments.Add(appointment);
    await db.SaveChangesAsync(ct);
    await transaction.CommitAsync(ct);
}
```

### 5.3 Audit Log Mekanizması
- **Problem:** Kritik işlemler izlenmiyor.
- **Neden gerekli:** KVKK, güvenlik, sorumluluk.
- **Nasıl yapılmalı:**
```csharp
public sealed class AuditLogService(IAppDbContext db)
{
    public async Task LogAsync(string action, Guid? userId, string? entityName, string? entityId, string? oldValue, string? newValue, string? ipAddress)
    {
        db.AuditLogs.Add(new AuditLog { ... });
        await db.SaveChangesAsync();
    }
}
```
- **Örnek kullanım:** Admin berber onayladığında, kullanıcı pasife alındığında, ödeme durumu değiştiğinde çağrılmalı.

### 5.4 Admin MFA
- **Problem:** Admin tek şifre ile giriş yapıyor.
- **Neden gerekli:** Hesap ele geçirme riski.
- **Nasıl yapılmalı:** `AdminAuthService` oluştur. Admin login'de şifre doğruysa TOTP kodu iste. `TwoFactorService` ile `TOTP` doğrulama. `Users` tablosuna `MfaSecret` (encrypted) ve `MfaEnabled` ekle.

### 5.5 Kupon Yapısı Düzeltme
- **Problem:** `DiscountAmount` ve `DiscountPercentage` aynı anda dolu olabilir.
- **Neden gerekli:** Hesaplama belirsizliği.
- **Nasıl yapılmalı:**
```sql
ALTER TABLE Coupons ADD CONSTRAINT CHK_Coupon_DiscountType CHECK (
    (DiscountAmount IS NOT NULL AND DiscountPercentage IS NULL) OR
    (DiscountAmount IS NULL AND DiscountPercentage IS NOT NULL)
);
```
Veya dokümana uygun `DiscountType` enum + `DiscountValue` tek kolon yapısına geç.

### 5.6 Payment Unique Index
- **Problem:** Çift ödeme kaydı.
- **Nasıl yapılmalı:**
```sql
CREATE UNIQUE INDEX IX_Payments_ProviderTransactionId 
ON Payments(ProviderTransactionId) 
WHERE ProviderTransactionId IS NOT NULL;
```

### 5.7 Dosya Yükleme Endpointi
- **Problem:** Güvenli dosya upload mekanizması yok.
- **Nasıl yapılmalı:** `FilesController` oluştur. `IFormFile` al. Boyut, uzantı, MIME type kontrolü yap. Dosya adı `Guid.NewGuid()` olacak şekilde kaydet. Imza kontrolü (magic bytes) ekle.

### 5.8 Şifre Politikası Güçlendirme
- **Problem:** Özel karakter zorunlu değil.
- **Nasıl yapılmalı:** `AuthService.RegisterAsync` içine:
```csharp
if (!request.Password.Any(ch => !char.IsLetterOrDigit(ch)))
    throw new AppException("Şifre en az 1 özel karakter içermelidir.", 422);
```

### 5.9 Rating Otomatik Güncelleme
- **Problem:** Yorum sonrası ortalama puan değişmiyor.
- **Nasıl yapılmalı:** `ReviewService` içinde:
```csharp
var shop = await db.BarberShops.FirstAsync(x => x.Id == review.BarberShopId);
shop.ReviewCount++;
shop.AverageRating = ((shop.AverageRating * (shop.ReviewCount - 1)) + review.Rating) / shop.ReviewCount;
```

### 5.10 KVKK Hesap Silme
- **Problem:** Kullanıcı hesabını silemiyor.
- **Nasıl yapılmalı:** `UsersController` içine `DELETE users/me` endpointi. Soft delete + kişisel verileri anonimleştir (`FullName` -> "Silinmiş Kullanıcı", `PhoneNumber` -> hashlenmiş maskeli değer, `Email` -> null).

---

## 6. Flutter Mobil Uygulama İçin Yapılması Gerekenler

### 6.1 Offline Mod ve Hata Yönetimi
- `Connectivity_plus` paketi ile internet bağlantısı dinlenmeli.
- `ApiClient` içinde `SocketException` ve `TimeoutException` yakalanıp kullanıcıya "Bağlantı hatası" mesajı gösterilmeli.
- Kritik veriler (berber listesi, randevular) için yerel cache (`Hive` veya `sembast`) kullanılmalı.

### 6.2 BarberOwner / Staff Ekranları
- Dokümanda sadece müşteri ekranları var. Ticari uygulama için berber tarafı şart.
- **Önerilen minimum ekranlar:**
  - `BarberDashboardScreen`: Günlük randevu özeti, kazanç.
  - `BarberAppointmentsScreen`: Gelen randevular, Onayla/Reddet butonları.
  - `BarberWorkingHoursScreen`: Çalışma saati düzenleme.
  - `StaffAppointmentsScreen`: Personele atanmış randevular.

### 6.3 State Management
- `app_state.dart` mevcut ama `Riverpod` veya `Bloc` kullanılıp kullanılmadığı net değil.
- **Öneri:** `flutter_riverpod` ile `StateNotifier` kullan. Her feature için ayrı `Provider`:
  - `barberListProvider`, `appointmentProvider`, `authProvider`, `favoriteProvider`.

### 6.4 Deep Linking
- Randevu onay bildirimine tıklayınca doğrudan randevu detayına gitmeli.
- `go_router` veya `flutter_deep_linking` ile `berberyanimda://appointment/{id}` yapılandırılmalı.

### 6.5 Accessibility
- Tüm butonlarda `Semantics` widget'ı kullanılmalı.
- `TextScaler` desteği (`MediaQuery.textScalerOf`) eklenmeli. Minimum %100, maksimum %200.

### 6.6 KVKK Ekranları
- Kayıt akışında "Gizlilik Politikası" ve "Kullanım Şartları" linkleri olmalı.
- "Hesabımı Sil" butonu Profil > Ayarlar altında olmalı.
- Push notification ve konum izni için açık rıza diyalogları tasarıma eklenmeli.

---

## 7. Veritabanı Değerlendirmesi

### 7.1 Eksik Soft Delete Alanları
Doküman `Users`, `BarberShops`, `StaffMembers`, `BarberServices`, `Appointments`, `Reviews`, `Coupons` için soft delete istiyor. Kodda bunlar mevcut.
**Ancak** aşağıdaki tablolarda da soft delete düşünülmeli:
- `BarberShopImages`: Görsel silindiğinde hard delete yerine `DeletedAt` eklenmeli.
- `StaffBreaks`: Mola iptal edildiğinde geçmiş kayıt kalmalı.
- `WorkingHours`: Çalışma saati değişikliklerinde geçmiş kalmalı.
- `Payments`: Ödeme kaydı asla silinmemeli. Zaten dokümanda soft delete önerilmiyor ama `CancelledAt`/`FailedReason` yeterli.

### 7.2 Eksik Index'ler
- `Payments.ProviderTransactionId` üzerinde unique index (Yüksek öncelik).
- `AuditLogs.CreatedAt` üzerinde index (log sorguları hızlı olsun).
- `Notifications(UserId, IsRead, CreatedAt)` composite index (okunmamış bildirim sayısı için).

### 7.3 Eksik Tablo/Entity
- `SupportTicketReply` kodda var ama dokümanda yok. Tablo yapısı dokümana eklenmeli.
- `AdminActionLog` veya `SecurityLog` ayrı tablosu düşünülebilir (brute force, başarısız girişler için).

### 7.4 Veri Bütünlüğü
- `Coupon` tablosunda `DiscountAmount` + `DiscountPercentage` aynı anda dolu olmamalı. CHECK constraint ekle.
- `Appointments.Status` geçişleri DB seviyesinde kısıtlanabilir (örn. `Cancelled` -> `Confirmed` olamaz). Bu business rule olarak kodda tutuluyor, yeterli.

---

## 8. API Değerlendirmesi

### 8.1 Eksik Endpointler

| Endpoint | Method | Amaç | Request Body | Response | Yetki |
|---|---|---|---|---|---|
| `/api/v1/appointments/{id}/confirm` | POST | Randevuyu onayla | `{}` | `AppointmentDto` | BarberOwner, Staff, Admin |
| `/api/v1/appointments/{id}/complete` | POST | Randevuyu tamamla | `{}` | `AppointmentDto` | BarberOwner, Staff, Admin |
| `/api/v1/appointments/{id}/reject` | POST | Randevuyu reddet | `{"reason": ""}` | `AppointmentDto` | BarberOwner, Staff, Admin |
| `/api/v1/users/me` | DELETE | Hesabı sil (KVKK) | `{}` | `{ success }` | Customer |
| `/api/v1/admin/reviews/{id}/approve` | POST | Yorum onayla | `{}` | `ReviewDto` | Admin |
| `/api/v1/admin/reviews/{id}/reject` | POST | Yorum reddet | `{}` | `ReviewDto` | Admin |
| `/api/v1/payments/refund` | POST | İade başlat | `{"appointmentId": ""}` | `PaymentDto` | Admin |
| `/api/v1/files/upload` | POST | Dosya yükle | `multipart/form-data` | `{ fileUrl }` | Authenticated |
| `/api/v1/admin/audit-logs` | GET | Audit log listele | Query: page, pageSize | `PagedResponse<AuditLogDto>` | Admin |

### 8.2 Mevcut Endpoint Düzeltmeleri
- `POST /api/v1/payments/webhook/{provider}`: `[AllowAnonymous]` olmalı (zaten öyle) ama IP whitelist değerlendirilmeli.
- `GET /api/v1/appointments/my`: `Take(100)` var ama pagination (`page`, `pageSize`) desteği yok. Doküman pagination istiyor.

---

## 9. Güvenlik ve Ticari Yayın Riskleri

### 9.1 Authentication
- **Durum:** JWT + Refresh Token + OTP uygulanmış. Şifreler hashlenmiş.
- **Risk:** Admin MFA yok. Şifre özel karakter kontrolü yok.
- **Çözüm:** Admin'e TOTP zorunluluğu getir. Şifre politikası güçlendir.

### 9.2 Authorization
- **Durum:** Object level authorization `BookingService.EnsureCanAccess` ile yapılıyor. `[Authorize]` attribute'ları mevcut.
- **Risk:** `[Authorize(Roles = ...)]` tüm endpointlerde tutarlı değil. `AppointmentsController`'da sadece `Create` için roller tanımlı.
- **Çözüm:** Her controller endpoint'inde roller netleştirilmeli. Admin endpoint'leri ayrı `[Authorize(Roles = "Admin")]` ile korunmalı.

### 9.3 Rate Limiting
- **Durum:** Auth (5/dk), Appointment (5/dk), Global (100/dk auth, 300/dk anonim).
- **Risk:** OTP endpointi için ayrı rate limit yok. Login brute force için IP bazlı limit var ama telefon bazlı limit eksik.
- **Çözüm:** OTP gönderim için ayrı policy (1/45sn + 10/gün). Login için telefon numarası bazlı da limit ekle.

### 9.4 Input Validation
- **Durum:** `ApiBehaviorOptions` ile merkezi validation var. `AuthService` içinde custom validasyon var.
- **Risk:** File upload validasyonu eksik. Dosya boyutu, MIME type, magic bytes kontrolü yok.
- **Çözüm:** `FilesController` + `IFormFile` validasyonu.

### 9.5 File Upload Güvenliği
- **Durum:** Endpoint dokümanda tanımlı ama kodda görülmedi.
- **Risk:** Zararlı dosya yükleme, path traversal, RCE.
- **Çözüm:** Dosya adı GUID, uzantı kontrolü (jpg/png/webp), MIME type + magic bytes kontrolü, maksimum 5MB, virus scan (opsiyonel).

### 9.6 Payment Security
- **Durum:** Webhook signature doğrulama, idempotency, tutar kontrolü var.
- **Risk:** Webhook IP whitelist yok. `ProviderTransactionId` unique değil. İade süreci tanımlı değil.
- **Çözüm:** Ödeme sağlayıcı IP'leri whitelist'e al. Unique index ekle. Refund endpointi ve akışı hazırla.

### 9.7 KVKK / GDPR
- **Durum:** Dokümanda gerekli metinler listelenmiş. Kodda `DeletedAt` mekanizması var.
- **Risk:** Aydınlatma metni uygulamada yok. Kullanıcı veri indirme/silme hakkı yok. Veri saklama süreleri DB seviyesinde uygulanmamış.
- **Çözüm:** Kayıt ekranına açık rıza checkbox'ı ekle. `DELETE /users/me` endpointi ekle. Veri saklama job'ları hazırla (eski OTP/log temizliği).

### 9.8 Logging
- **Durum:** `GlobalExceptionMiddleware` + `ILogger` kullanılıyor. `AuditLog` tablosu var ama kullanılmıyor.
- **Risk:** Hassas veri loglara düşebilir. Merkezi log sistemi yok.
- **Çözüm:** Serilog enricher ile maskeleme. Production için Seq/ElasticSearch kurulumu planla.

### 9.9 Audit Trail
- **Durum:** Tablo var, kayıt atan mekanizma yok.
- **Risk:** Kritik işlemlerin kimin ne zaman yaptığı bilinmiyor.
- **Çözüm:** `AuditLogService` oluştur ve admin işlemlerine entegre et.

### 9.10 Backup
- **Durum:** Dokümanda var, kodda/infra'da yok.
- **Risk:** Veri kaybı.
- **Çözüm:** PostgreSQL için `pg_dump` günlük otomasyonu. Yedekler şifreli (AES-256) saklansın. Aylık restore testi yap.

### 9.11 Monitoring
- **Durum:** HealthChecks (`/health`) var. `CleanupJobs` var.
- **Risk:** CPU/RAM/disk monitoring, alarm yok.
- **Çözüm:** Prometheus + Grafana veya Application Insights entegrasyonu. Kritik hata rate'i için alarm kur.

### 9.12 Error Handling
- **Durum:** Global exception middleware var. `AppException` ve `500` ayrımı var.
- **Risk:** Stack trace sızdırma riski yok görünüyor, doğru yapılandırılmış.

---

## 10. Öncelikli Yol Haritası

### Faz 1 - Kritik Eksikler (1-2 Hafta)
1. `BookingService.CreateAsync` transaction koruması ekle.
2. `AppointmentsController`'a `confirm`, `complete`, `reject` endpointleri ekle.
3. `AuditLogService` oluştur ve admin işlemlerine entegre et.
4. `Payments` tablosuna `ProviderTransactionId` unique index ekle.
5. Admin MFA (TOTP) mekanizmasını hazırla.
6. Kupon tablosuna CHECK constraint veya yapı düzeltmesi yap.

### Faz 2 - MVP Tamamlama (2-3 Hafta)
7. Flutter'da BarberOwner/Staff ekranlarını tasarla ve geliştir.
8. `DELETE /users/me` (hesap silme) endpointi + mobil ekranı.
9. KVKK aydınlatma metni ve kullanım şartları ekranlarını mobilde aktif et.
10. File Upload endpointi ve güvenli validasyonunu eklendi.
11. Randevu listeleme endpointlerine pagination ekle.
12. `AppointmentStatus.Upcoming` geçiş job'ını yaz.

### Faz 3 - Güvenlik ve Test (1-2 Hafta)
13. Swagger'ı production'da korumalı hale getir veya tamamen kapat.
14. CORS testing ortamını kısıtla.
15. Rate limiting OTP policy'sini ekle.
16. Şifre özel karakter kontrolünü aktif et.
17. Log maskeleme (Serilog enricher) uygula.
18. Birim ve entegrasyon testlerini yaz (özellikle randevu çakışması, yetki, ödeme webhook).
19. Sızma testi için hazırlık (test kullanıcıları, senaryolar).

### Faz 4 - Yayına Hazırlık (1 Hafta)
20. KVKK metinlerini hukuk danışmanına onaylat.
21. SSL/TLS sertifikası, DNS, CDN (Cloudflare) yapılandırması.
22. Veritabanı yedekleme otomasyonu (şifreli).
23. Monitoring ve alarm kurulumu (Prometheus/Grafana veya App Insights).
24. Production ortam değişkenlerini (JWT secret, DB connection, API keys) Secret Manager'a taşı.
25. Mobil obfuscation (`--obfuscate`) ve release build testi.
26. App Store / Google Play gizlilik politikası URL'lerini güncelle.

### Faz 5 - İyileştirme ve Ölçekleme (Sürekli)
27. Push notification (Firebase) entegrasyonunu tamamla.
28. Online ödeme sağlayıcı (iyzico/PayTR) canlı ortam entegrasyonu.
29. Redis cache (berber listeleme, detay) entegrasyonu.
30. Fraud detection (sahte randevu, kupon suiistimali) kuralları.
31. Admin panel frontend (Blazor/React) geliştirme.
32. Tablet responsive desteği.
33. SIEM entegrasyonu ve düzenli vulnerability taraması.

---

## 11. Sonuç

**En Riskli Noktalar:**
1. **Race condition ile randevu çakışması** (transaction yok) - Kritik.
2. **Audit log mekanizmasının olmayışı** - KVKK ve güvenlik olaylarında savunmasız.
3. **Randevu onaylama/tamamlama endpointlerinin eksikliği** - İşletme tarafı operasyonel olarak çalışmaz.
4. **Admin MFA eksikliği** - Yüksek yetkili hesap tek şifre ile korunuyor.
5. **Ödeme sisteminde `ProviderTransactionId` unique olmaması** - Çift ödeme/kesinti riski.

**En Acil Yapılması Gerekenler:**
- Randevu oluşturma işlemini transaction içine al.
- Randevu onaylama/tamamlama endpointlerini yaz.
- Audit log servisini aktif et.
- Admin MFA'yı devreye al.
- Payment tablosuna unique index ekle.

**Genel Yayınlanabilirlik Durumu:**
- **MVP seviyesinde:** Backend temel iskeleti ve müşteri mobil akışı büyük ölçüde tamamlanmış. Auth, randevu oluşturma, berber listeleme, ödeme altyapısı, notification, soft delete gibi temel yapılar kurulmuş.
- **Ticari yayın için:** **Henüz hazır değil.** Özellikle işletme tarafı (berber onaylama, personel yönetimi), güvenlik (transaction, audit log, admin MFA), KVKK uyumluluğu (hesap silme, aydınlatma metni) ve ödeme güvenliği (unique index, refund) alanlarında eksiklikler var. Faz 1 ve Faz 2 tamamlandıktan sonra kapalı beta yayını yapılabilir. Faz 3 sonrası ticari yayın önerilir.
