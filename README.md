# Berber Yanımda

Berber Yanımda, berber dükkanları için randevu yönetimi ve müşteri deneyimi platformu.

**Repo yapısı:**

- `backend/`: .NET 8 REST API, EF Core, JWT auth, OTP, randevu slot hesaplama, favoriler, bildirimler, admin berber onayı, MFA, audit log, KVKK uyumluluğu.
- `mobile/`: Flutter mobil uygulama, Riverpod, go_router, premium koyu tema, MVP randevu akışı, berber paneli, push bildirimler, kupon ve sandbox ödeme.
- `docs/`: teknik, güvenlik ve tasarım referansları.

**Tamamlanan fazlar:**

- **Faz 1**: Randevu lifecycle API (onayla/tamamla/reddet) + Berber mobil panel (Dashboard & Randevular)
- **Faz 2**: Yorum/review sistemi (transaction-safe, otomatik rating) + Berber yönetim ekranları (Çalışma Saatleri, Hizmetler, Personel)
- **Faz 3**: Admin MFA (TOTP + AES-256), merkezi audit log, KVKK uyumluluk ekranları, hesap silme anonymizasyonu
- **Faz 4**: Push bildirimler (FCM + local notifications), kupon UI, online ödeme sandbox (test modu)

## Backend

Geliştirme ortamında API varsayılan olarak in-memory veritabanı ve seed data ile çalışır.

```powershell
dotnet run --project .\backend\src\BerberYanimda.Api --urls http://localhost:5000
```

Swagger: `http://localhost:5000/swagger`

SQL Server kullanmak için `backend/src/BerberYanimda.Api/appsettings.Development.json` içinde `Database:Provider` değerini `SqlServer` yapıp connection string verin. PostgreSQL için `Postgres` yapın.

**Seed kullanıcıları:**

| Rol | Telefon | Şifre |
|---|---|---|
| Customer | `+905551112233` | `Test1234!` |
| Admin | `+905550000000` | `Admin123!` |
| BarberOwner | `+905552223344` | `Owner123!` |
| Staff | `+905553334455` | `Staff123!` |

**Ödeme sandbox:** `Payments:UseSandbox=true` yapıldığında online ödeme test modunda çalışır. `POST /api/v1/payments/sandbox/complete` ile test başarı/başarısız webhook simüle edilir.

## API contract examples

Tum endpointler `ApiResponse<T>` doner: `{ "success": true, "message": null, "data": ... }`.

`GET /api/v1/barbers?page=1&pageSize=20`

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "f3c23f29-94f3-4e1f-a39a-ff2b4e7d4d9a",
        "name": "Modern Barber",
        "district": "Kadikoy",
        "city": "Istanbul",
        "rating": 4.8,
        "reviewCount": 124,
        "distanceKm": 1.2,
        "startingPrice": 250,
        "isAvailableToday": true,
        "coverImageUrl": "/uploads/barbers/modern.jpg",
        "isFavorite": false
      }
    ],
    "page": 1,
    "pageSize": 20,
    "totalCount": 1,
    "totalPages": 1
  }
}
```

`GET /api/v1/barbers/{id}` detail yaniti `services` ve `staff` listelerini icerir. `GET /api/v1/availability?barberShopId={id}&staffMemberId=&serviceIds={serviceId}&date=2026-04-27` icin `staffMemberId` bos veya tamamen eksik olabilir.

```json
{
  "success": true,
  "data": [
    { "startTime": "09:00", "endTime": "09:45", "isAvailable": true },
    { "startTime": "09:15", "endTime": "10:00", "isAvailable": false }
  ]
}
```

`POST /api/v1/appointments` backend toplam sure/fiyati kendisi hesaplar; frontend fiyat gondermez.

```json
{
  "barberShopId": "f3c23f29-94f3-4e1f-a39a-ff2b4e7d4d9a",
  "staffMemberId": null,
  "appointmentDate": "2026-04-27",
  "startTime": "09:00",
  "serviceIds": ["75c8f18e-a774-448d-a741-d097b24555c8"],
  "customerNote": null
}
```

### Randevu Lifecycle (Berber Tarafi)

- `PATCH /api/v1/appointments/{id}/confirm` — Onayla
- `PATCH /api/v1/appointments/{id}/complete` — Tamamla
- `PATCH /api/v1/appointments/{id}/reject` — Reddet (sebep opsiyonel)
- `GET /api/v1/appointments/shop` — Dükkan randevuları (sayfalı, tarih & durum filtresi)

**Durum geçişleri:** `Pending` → `Confirmed` | `Rejected` → `Completed` | `Cancelled`

**Push bildirimler:** Her durum değişikliğinde ilgili tarafa FCM push + in-app notification gönderilir. Cihaz token'ı `POST /api/v1/users/me/device-token` ile kaydedilir.

**Diğer endpointler:**

- `GET /api/v1/users/me` — Profil
- `GET /api/v1/appointments/my` — Müşteri randevuları
- `GET /api/v1/favorites` — Favoriler
- `GET /api/v1/notifications` — Bildirimler
- `POST /api/v1/coupons/validate` — Kupon doğrulama
- `POST /api/v1/payments/pay-at-barber` — Berberde öde
- `POST /api/v1/payments/create-session` — Online ödeme oturumu
- `POST /api/v1/payments/webhook/{provider}` — Ödeme webhook
- `POST /api/v1/reviews` — Yorum ekle (randevu sonrası)
- `GET /api/v1/barbers/{id}/reviews` — Yorumları görüntüle
- `GET /api/v1/barbers/{id}/reviews/summary` — Ortalama puan & sayı

**Güvenlik & Uyumluluk:**

- `POST /api/v1/auth/mfa/setup` — TOTP MFA kurulumu (Admin)
- `POST /api/v1/auth/mfa/verify` — MFA kod doğrulama
- `POST /api/v1/auth/mfa/disable` — MFA devre dışı bırakma
- `POST /api/v1/users/me/delete-account` — KVKK hesap silme (anonymizasyon)
- `GET /api/v1/users/me/export-data` — KVKK veri dışa aktarma

## Berber Paneli (Mobile)

BerberOwner ve Staff rolleri için mobil yönetim ekranları:

| Ekran | Route | Özellikler |
|---|---|---|
| **Panel** | `/barber/dashboard` | Günün özet kartları (bekleyen onay, bugünkü randevular, toplam randevu, kazanç) + hızlı erişim kartları |
| **Randevular** | `/barber/appointments` | Liste, tarih & durum filtresi, onayla/reddet/tamamla |
| **Çalışma Saatleri** | `/barber/working-hours` | Haftalık açılış/kapanış/kapalı yönetimi |
| **Hizmetler** | `/barber/services` | CRUD (isim, süre, fiyat) — soft delete |
| **Personel** | `/barber/staff` | CRUD, uzmanlık/bio, hizmet atama |

- **Bottom Navigation**: Role-aware; berber kullanıcılarında 3 sekme (Panel, Randevular, Profil)
- **Login yönlendirmesi**: Berber → Panel, Müşteri → Ana Sayfa

## Berber Owner API (Backend)

- `GET/PUT /api/v1/barber-owner/working-hours`
- `GET/POST/PUT/DELETE /api/v1/barber-owner/services`
- `GET/POST/PUT/DELETE /api/v1/barber-owner/staff`
- `PUT /api/v1/barber-owner/staff/{id}/services`

**Otomatik Rating**: Admin yorum onayladığında/sildiğinde `BarberShop` ve `StaffMember` rating/count otomatik güncellenir.

## Mobile

```powershell
cd .\mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Android emulator için `10.0.2.2`, fiziksel cihaz için bilgisayarın yerel IP adresi kullanılmalıdır.

**Mobil özellikler:**

- **Premium koyu tema**: Siyah + altın renk şeması
- **Randevu akışı**: Berber seçimi → Hizmet seçimi → Personel seçimi → Tarih/saat → Ödeme → Başarı
- **Ödeme yöntemleri**: Berberde öde (varsayılan) + Online ödeme sandbox (test modu)
- **Kupon**: Ödeme ekranından kupon kodu doğrulama ve indirim uygulama
- **Push bildirimler**: FCM + local notifications (randevu onay/iptal/tamamlama/reddetme)
- **KVKK uyumluluk**: Gizlilik Politikası, Kullanım Koşulları, KVKK Bilgilendirme ekranları
- **Yorum sistemi**: Randevu sonrası puanlama ve yorum

**Firebase yapılandırması (opsiyonel):**

Push bildirimler için `android/app/google-services.json` ve `ios/Runner/GoogleService-Info.plist` dosyalarını ekleyin. Firebase yapılandırılmamışsa uygulama bildirimsiz çalışmaya devam eder (graceful degradation).

## Verification

```powershell
dotnet test .\backend\BerberYanimda.sln
cd .\mobile
flutter analyze
flutter test
```

**Son durum:** Backend 49/49 test geçiyor, Flutter analyze temiz (0 hata).
