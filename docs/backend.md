# Berber Yanımda - Backend Teknik Dokümanı

## 1. Proje Özeti

**Proje Adı:** Berber Yanımda  
**Platformlar:** iOS, Android  
**Frontend:** Flutter  
**Backend:** REST API  
**Veritabanı:** PostgreSQL / SQL Server / MySQL  
**Amaç:** Kullanıcıların yakınındaki berberleri keşfetmesi, hizmet seçmesi, personel seçmesi, randevu oluşturması, ödeme yapması ve randevularını yönetmesi.

Berber Yanımda backend sistemi; kullanıcı yönetimi, berber yönetimi, hizmet yönetimi, personel yönetimi, randevu takibi, ödeme, favoriler, yorumlar, bildirimler ve admin panel altyapısını desteklemelidir.

---

# 2. Backend Teknoloji Önerisi

## 2.1 Önerilen Mimari

Backend REST API olarak geliştirilecektir.

Önerilen teknolojiler:

```text
Seçenek 1:
.NET 8 Web API
Entity Framework Core
PostgreSQL veya SQL Server
JWT Authentication
Redis Cache
Hangfire Background Jobs

Seçenek 2:
Node.js NestJS
PostgreSQL
Prisma ORM
JWT Authentication
Redis Cache
BullMQ Queue

Seçenek 3:
Laravel API
MySQL / PostgreSQL
Sanctum veya JWT
Redis Cache
Queue Jobs

Bu proje için en sağlam öneri:

.NET 8 Web API + PostgreSQL / SQL Server + Entity Framework Core

Sebep:

Kurumsal yapı için uygun
Yetkilendirme kolay
Admin panel entegrasyonu kolay
Uzun vadede bakımı rahat
Randevu, ödeme, bildirim gibi süreçler için güçlü yapı sağlar
İnsanlık bazen doğru teknoloji seçebiliyor, şaşırtıcı ama güzel
3. Genel Sistem Modülleri

Backend aşağıdaki ana modüllerden oluşmalıdır:

Auth Module
User Module
Barber Shop Module
Staff Module
Service Module
Appointment Module
Availability Module
Payment Module
Favorite Module
Review Module
Notification Module
Location Module
Campaign / Coupon Module
Admin Module
File / Image Module
Audit Log Module
4. Kullanıcı Rolleri

Sistemde en az 4 ana rol bulunmalıdır.

4.1 Customer

Mobil uygulamayı kullanan müşteridir.

Yetkileri:

Kayıt olabilir
Giriş yapabilir
Profilini güncelleyebilir
Berberleri listeleyebilir
Berber detayını görebilir
Hizmet seçebilir
Personel seçebilir
Randevu oluşturabilir
Randevusunu iptal edebilir
Ödeme yapabilir
Favorilere berber ekleyebilir
Yorum yapabilir
Bildirim alabilir
4.2 BarberOwner

Berber işletmesi sahibidir.

Yetkileri:

Kendi işletme profilini yönetebilir
Hizmet ekleyebilir / güncelleyebilir
Personel ekleyebilir / güncelleyebilir
Çalışma saatlerini belirleyebilir
Randevuları görüntüleyebilir
Randevu onaylayabilir / reddedebilir
Kazanç raporlarını görebilir
Yorumları görüntüleyebilir
4.3 Staff

Berber çalışanıdır.

Yetkileri:

Kendi randevularını görebilir
Müsaitlik durumunu görebilir
Randevu durumunu güncelleyebilir
Müşteri notlarını görebilir
4.4 Admin

Sistem yöneticisidir.

Yetkileri:

Tüm kullanıcıları yönetebilir
Tüm berberleri yönetebilir
Berber onay süreçlerini yönetebilir
Randevuları görüntüleyebilir
Ödeme kayıtlarını görüntüleyebilir
Şikayetleri ve destek taleplerini yönetebilir
Kampanya ve kupon oluşturabilir
Sistem loglarını görüntüleyebilir
5. Kimlik Doğrulama ve Yetkilendirme
5.1 Authentication Yöntemi

Backend JWT tabanlı authentication kullanmalıdır.

Giriş başarılı olduğunda kullanıcıya şu tokenlar verilmelidir:

{
  "accessToken": "jwt-access-token",
  "refreshToken": "refresh-token",
  "expiresIn": 3600
}
5.2 Login Yöntemleri

Sistem şu giriş yöntemlerini desteklemelidir:

Telefon numarası + şifre
E-posta + şifre
Google ile giriş
Apple ile giriş
OTP doğrulama

İlk MVP için zorunlu olanlar:

Telefon numarası + şifre
OTP doğrulama

İkinci faz:

Google Login
Apple Login
5.3 OTP Doğrulama

OTP kodu aşağıdaki durumlarda kullanılmalıdır:

Telefon doğrulama
Şifre sıfırlama
Hesap güvenliği
İlk kayıt doğrulaması

OTP kuralları:

Kod uzunluğu: 6 hane
Geçerlilik süresi: 3 dakika
Tekrar gönderme süresi: 45 saniye
Maksimum deneme hakkı: 5
Başarısız deneme sonrası geçici kilit: 10 dakika

OTP tablosu tutulmalıdır.

6. Veritabanı Tasarımı

Aşağıdaki tablo yapısı backend için temel şemadır.

6.1 Users

Kullanıcı hesaplarını tutar.

CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    PhoneNumber NVARCHAR(30) NOT NULL,
    Email NVARCHAR(150) NULL,
    PasswordHash NVARCHAR(MAX) NULL,
    Role NVARCHAR(50) NOT NULL,
    IsPhoneVerified BIT NOT NULL DEFAULT 0,
    IsEmailVerified BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    ProfileImageUrl NVARCHAR(MAX) NULL,
    BirthDate DATE NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL
);

Index önerileri:

CREATE UNIQUE INDEX IX_Users_PhoneNumber ON Users(PhoneNumber);
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Role ON Users(Role);
6.2 BarberShops

Berber işletmelerini tutar.

CREATE TABLE BarberShops (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    OwnerUserId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    PhoneNumber NVARCHAR(30) NULL,
    Email NVARCHAR(150) NULL,
    City NVARCHAR(100) NOT NULL,
    District NVARCHAR(100) NOT NULL,
    Address NVARCHAR(MAX) NOT NULL,
    Latitude DECIMAL(10, 7) NULL,
    Longitude DECIMAL(10, 7) NULL,
    CoverImageUrl NVARCHAR(MAX) NULL,
    LogoUrl NVARCHAR(MAX) NULL,
    AverageRating DECIMAL(3,2) NOT NULL DEFAULT 0,
    ReviewCount INT NOT NULL DEFAULT 0,
    StartingPrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    IsApproved BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,

    CONSTRAINT FK_BarberShops_Users 
        FOREIGN KEY (OwnerUserId) REFERENCES Users(Id)
);

Index önerileri:

CREATE INDEX IX_BarberShops_City_District ON BarberShops(City, District);
CREATE INDEX IX_BarberShops_IsApproved ON BarberShops(IsApproved);
CREATE INDEX IX_BarberShops_Rating ON BarberShops(AverageRating);
6.3 BarberShopImages

Berber galeri görsellerini tutar.

CREATE TABLE BarberShopImages (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    ImageUrl NVARCHAR(MAX) NOT NULL,
    SortOrder INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_BarberShopImages_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id)
);
6.4 BarberServices

Berberlerin sunduğu hizmetleri tutar.

CREATE TABLE BarberServices (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    DurationMinutes INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,

    CONSTRAINT FK_BarberServices_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id)
);

Örnek hizmetler:

Saç Kesimi
Sakal Tıraşı
Saç + Sakal
Damat Tıraşı
Cilt Bakımı
Saç Boyama
6.5 StaffMembers

Berber çalışanlarını tutar.

CREATE TABLE StaffMembers (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NULL,
    FullName NVARCHAR(150) NOT NULL,
    Expertise NVARCHAR(150) NULL,
    Bio NVARCHAR(MAX) NULL,
    AvatarUrl NVARCHAR(MAX) NULL,
    AverageRating DECIMAL(3,2) NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,

    CONSTRAINT FK_StaffMembers_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id),

    CONSTRAINT FK_StaffMembers_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id)
);
6.6 StaffServices

Personelin hangi hizmetleri verebildiğini tutar.

CREATE TABLE StaffServices (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    StaffMemberId UNIQUEIDENTIFIER NOT NULL,
    BarberServiceId UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT FK_StaffServices_StaffMembers 
        FOREIGN KEY (StaffMemberId) REFERENCES StaffMembers(Id),

    CONSTRAINT FK_StaffServices_BarberServices 
        FOREIGN KEY (BarberServiceId) REFERENCES BarberServices(Id)
);
6.7 WorkingHours

Berber veya personel çalışma saatlerini tutar.

CREATE TABLE WorkingHours (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    StaffMemberId UNIQUEIDENTIFIER NULL,
    DayOfWeek INT NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    IsClosed BIT NOT NULL DEFAULT 0,

    CONSTRAINT FK_WorkingHours_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id),

    CONSTRAINT FK_WorkingHours_StaffMembers 
        FOREIGN KEY (StaffMemberId) REFERENCES StaffMembers(Id)
);

DayOfWeek:

1 = Pazartesi
2 = Salı
3 = Çarşamba
4 = Perşembe
5 = Cuma
6 = Cumartesi
7 = Pazar
6.8 StaffBreaks

Personel mola veya kapalı saatlerini tutar.

CREATE TABLE StaffBreaks (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    StaffMemberId UNIQUEIDENTIFIER NOT NULL,
    BreakDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Reason NVARCHAR(250) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_StaffBreaks_StaffMembers 
        FOREIGN KEY (StaffMemberId) REFERENCES StaffMembers(Id)
);
6.9 Appointments

Randevuları tutar.

CREATE TABLE Appointments (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    CustomerUserId UNIQUEIDENTIFIER NOT NULL,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    StaffMemberId UNIQUEIDENTIFIER NULL,
    AppointmentDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    TotalDurationMinutes INT NOT NULL,
    TotalPrice DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CustomerNote NVARCHAR(MAX) NULL,
    CancellationReason NVARCHAR(MAX) NULL,
    CancelledAt DATETIME2 NULL,
    CompletedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,

    CONSTRAINT FK_Appointments_Users 
        FOREIGN KEY (CustomerUserId) REFERENCES Users(Id),

    CONSTRAINT FK_Appointments_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id),

    CONSTRAINT FK_Appointments_StaffMembers 
        FOREIGN KEY (StaffMemberId) REFERENCES StaffMembers(Id)
);

Status değerleri:

Pending
Confirmed
Upcoming
Completed
Cancelled
Rejected
NoShow

Index önerileri:

CREATE INDEX IX_Appointments_CustomerUserId ON Appointments(CustomerUserId);
CREATE INDEX IX_Appointments_BarberShopId ON Appointments(BarberShopId);
CREATE INDEX IX_Appointments_StaffMemberId_Date ON Appointments(StaffMemberId, AppointmentDate);
CREATE INDEX IX_Appointments_Status ON Appointments(Status);
6.10 AppointmentServices

Randevuya bağlı hizmetleri tutar.

CREATE TABLE AppointmentServices (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    AppointmentId UNIQUEIDENTIFIER NOT NULL,
    BarberServiceId UNIQUEIDENTIFIER NOT NULL,
    ServiceName NVARCHAR(150) NOT NULL,
    DurationMinutes INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_AppointmentServices_Appointments 
        FOREIGN KEY (AppointmentId) REFERENCES Appointments(Id),

    CONSTRAINT FK_AppointmentServices_BarberServices 
        FOREIGN KEY (BarberServiceId) REFERENCES BarberServices(Id)
);

Önemli:

Randevu oluşturulduğunda hizmet adı, süre ve fiyat snapshot olarak bu tabloya yazılmalıdır. Çünkü ileride berber hizmet fiyatını değiştirirse eski randevular bozulmamalıdır. Evet, veri geçmişini korumak gerekir; zaman makinesi henüz production’a çıkmadı.

6.11 Payments

Ödeme kayıtlarını tutar.

CREATE TABLE Payments (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    AppointmentId UNIQUEIDENTIFIER NOT NULL,
    CustomerUserId UNIQUEIDENTIFIER NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    PaymentProvider NVARCHAR(50) NULL,
    ProviderTransactionId NVARCHAR(150) NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Currency NVARCHAR(10) NOT NULL DEFAULT 'TRY',
    Status NVARCHAR(50) NOT NULL,
    PaidAt DATETIME2 NULL,
    FailedReason NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Payments_Appointments 
        FOREIGN KEY (AppointmentId) REFERENCES Appointments(Id),

    CONSTRAINT FK_Payments_Users 
        FOREIGN KEY (CustomerUserId) REFERENCES Users(Id)
);

PaymentMethod:

OnlineCard
PayAtBarber
Wallet

PaymentStatus:

Pending
Paid
Failed
Refunded
Cancelled
6.12 FavoriteBarberShops

Favori berberleri tutar.

CREATE TABLE FavoriteBarberShops (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_FavoriteBarberShops_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id),

    CONSTRAINT FK_FavoriteBarberShops_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id)
);

Index:

CREATE UNIQUE INDEX IX_Favorites_User_Barber 
ON FavoriteBarberShops(UserId, BarberShopId);
6.13 Reviews

Yorumları tutar.

CREATE TABLE Reviews (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    AppointmentId UNIQUEIDENTIFIER NOT NULL,
    CustomerUserId UNIQUEIDENTIFIER NOT NULL,
    BarberShopId UNIQUEIDENTIFIER NOT NULL,
    StaffMemberId UNIQUEIDENTIFIER NULL,
    Rating INT NOT NULL,
    Comment NVARCHAR(MAX) NULL,
    IsApproved BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Reviews_Appointments 
        FOREIGN KEY (AppointmentId) REFERENCES Appointments(Id),

    CONSTRAINT FK_Reviews_Users 
        FOREIGN KEY (CustomerUserId) REFERENCES Users(Id),

    CONSTRAINT FK_Reviews_BarberShops 
        FOREIGN KEY (BarberShopId) REFERENCES BarberShops(Id),

    CONSTRAINT FK_Reviews_StaffMembers 
        FOREIGN KEY (StaffMemberId) REFERENCES StaffMembers(Id)
);

Kural:

Sadece tamamlanmış randevuya yorum yapılabilir.
Aynı randevuya birden fazla yorum yapılamaz.
Rating 1 ile 5 arasında olmalıdır.
6.14 Notifications

Bildirimleri tutar.

CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    DataJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Notifications_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id)
);

Notification Type:

AppointmentConfirmed
AppointmentReminder
AppointmentCancelled
PaymentSuccess
PaymentFailed
Campaign
System
6.15 Coupons

Kupon kodlarını tutar.

CREATE TABLE Coupons (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL,
    Description NVARCHAR(250) NULL,
    DiscountType NVARCHAR(50) NOT NULL,
    DiscountValue DECIMAL(18,2) NOT NULL,
    MinimumAmount DECIMAL(18,2) NULL,
    MaxDiscountAmount DECIMAL(18,2) NULL,
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2 NOT NULL,
    UsageLimit INT NULL,
    UsedCount INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);

DiscountType:

Percentage
FixedAmount
6.16 CouponUsages

Kupon kullanım kayıtlarını tutar.

CREATE TABLE CouponUsages (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    CouponId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    AppointmentId UNIQUEIDENTIFIER NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL,
    UsedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_CouponUsages_Coupons 
        FOREIGN KEY (CouponId) REFERENCES Coupons(Id),

    CONSTRAINT FK_CouponUsages_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id),

    CONSTRAINT FK_CouponUsages_Appointments 
        FOREIGN KEY (AppointmentId) REFERENCES Appointments(Id)
);
6.17 SupportTickets

Yardım ve destek taleplerini tutar.

CREATE TABLE SupportTickets (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Subject NVARCHAR(200) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Open',
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,

    CONSTRAINT FK_SupportTickets_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id)
);
6.18 AuditLogs

Önemli işlemleri loglamak için kullanılır.

CREATE TABLE AuditLogs (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NULL,
    Action NVARCHAR(150) NOT NULL,
    EntityName NVARCHAR(100) NULL,
    EntityId NVARCHAR(100) NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    IpAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);
7. API Endpoint Tasarımı

API versiyonlu olmalıdır.

Base URL:
https://api.berberyanimda.com/api/v1
7.1 Auth Endpoints
Register
POST /api/v1/auth/register

Request:

{
  "fullName": "Burak Altıparmak",
  "phoneNumber": "+905551112233",
  "email": "burak@example.com",
  "password": "Test1234!"
}

Response:

{
  "success": true,
  "message": "Kayıt başarılı. Telefon doğrulama kodu gönderildi."
}
Login
POST /api/v1/auth/login

Request:

{
  "phoneNumber": "+905551112233",
  "password": "Test1234!"
}

Response:

{
  "accessToken": "jwt-token",
  "refreshToken": "refresh-token",
  "expiresIn": 3600,
  "user": {
    "id": "user-id",
    "fullName": "Burak Altıparmak",
    "role": "Customer"
  }
}
Verify OTP
POST /api/v1/auth/verify-otp

Request:

{
  "phoneNumber": "+905551112233",
  "code": "123456"
}
Refresh Token
POST /api/v1/auth/refresh-token
Logout
POST /api/v1/auth/logout
7.2 User Endpoints
Profil Bilgisi
GET /api/v1/users/me
Profil Güncelleme
PUT /api/v1/users/me

Request:

{
  "fullName": "Burak Altıparmak",
  "email": "burak@example.com",
  "birthDate": "1998-01-01"
}
Profil Fotoğrafı Yükleme
POST /api/v1/users/me/profile-image
7.3 Barber Shop Endpoints
Berber Listeleme
GET /api/v1/barbers

Query parametreleri:

search
city
district
latitude
longitude
sortBy
isAvailableToday
minRating
page
pageSize

Örnek:

GET /api/v1/barbers?city=İstanbul&district=Kadıköy&sortBy=distance&page=1&pageSize=20

Response:

{
  "items": [
    {
      "id": "barber-id",
      "name": "Modern Barber",
      "district": "Kadıköy",
      "city": "İstanbul",
      "rating": 4.8,
      "reviewCount": 120,
      "distanceKm": 1.2,
      "startingPrice": 250,
      "isAvailableToday": true,
      "coverImageUrl": "https://cdn.example.com/barber.jpg",
      "isFavorite": false
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 100
}
Berber Detay
GET /api/v1/barbers/{barberShopId}

Response:

{
  "id": "barber-id",
  "name": "Modern Barber",
  "description": "Profesyonel erkek kuaförü.",
  "phoneNumber": "+902161112233",
  "city": "İstanbul",
  "district": "Kadıköy",
  "address": "Caferağa Mah. Kadıköy",
  "latitude": 40.987,
  "longitude": 29.025,
  "averageRating": 4.8,
  "reviewCount": 120,
  "startingPrice": 250,
  "isOpenNow": true,
  "coverImageUrl": "https://cdn.example.com/cover.jpg",
  "images": [],
  "services": [],
  "staffMembers": []
}
Berber Oluşturma
POST /api/v1/barbers

Yetki:

BarberOwner
Admin
Berber Güncelleme
PUT /api/v1/barbers/{barberShopId}

Yetki:

BarberOwner
Admin
7.4 Service Endpoints
Berbere Ait Hizmetleri Listele
GET /api/v1/barbers/{barberShopId}/services
Hizmet Ekle
POST /api/v1/barbers/{barberShopId}/services

Request:

{
  "name": "Saç Kesimi",
  "description": "Profesyonel saç kesimi",
  "durationMinutes": 30,
  "price": 250
}
Hizmet Güncelle
PUT /api/v1/services/{serviceId}
Hizmet Sil / Pasife Al
DELETE /api/v1/services/{serviceId}

Not:

Silme işlemi hard delete olmamalıdır.
IsActive = false yapılmalıdır.
7.5 Staff Endpoints
Personel Listeleme
GET /api/v1/barbers/{barberShopId}/staff
Personel Detay
GET /api/v1/staff/{staffMemberId}
Personel Ekle
POST /api/v1/barbers/{barberShopId}/staff

Request:

{
  "fullName": "Mehmet Usta",
  "expertise": "Saç Kesimi Uzmanı",
  "bio": "15 yıllık deneyim.",
  "serviceIds": [
    "service-id-1",
    "service-id-2"
  ]
}
Personel Güncelle
PUT /api/v1/staff/{staffMemberId}
Personel Pasife Al
DELETE /api/v1/staff/{staffMemberId}
7.6 Availability Endpoints
Uygun Tarihleri Listele
GET /api/v1/availability/dates

Query:

barberShopId
staffMemberId
serviceIds
startDate
endDate
Uygun Saatleri Listele
GET /api/v1/availability/time-slots

Query:

barberShopId
staffMemberId
serviceIds
date

Örnek:

GET /api/v1/availability/time-slots?barberShopId=1&staffMemberId=2&serviceIds=3,4&date=2026-04-24

Response:

{
  "date": "2026-04-24",
  "slots": [
    {
      "startTime": "09:00",
      "endTime": "09:45",
      "isAvailable": true
    },
    {
      "startTime": "10:00",
      "endTime": "10:45",
      "isAvailable": false
    }
  ]
}
7.7 Appointment Endpoints
Randevu Oluştur
POST /api/v1/appointments

Request:

{
  "barberShopId": "barber-id",
  "staffMemberId": "staff-id",
  "serviceIds": [
    "service-id-1",
    "service-id-2"
  ],
  "appointmentDate": "2026-04-24",
  "startTime": "14:30",
  "customerNote": "Saç çok kısa olmasın."
}

Backend kuralları:

Seçilen hizmetler aktif olmalı
Berber aktif ve onaylı olmalı
Personel aktif olmalı
Personel seçilen hizmetleri verebilmeli
Tarih/saat çalışma saatleri içinde olmalı
Aynı personelde çakışan randevu olmamalı
Toplam süre hizmet sürelerinden hesaplanmalı
Toplam fiyat hizmet fiyatlarından hesaplanmalı
Randevu başlangıç ve bitiş saati backend tarafından hesaplanmalı

Response:

{
  "id": "appointment-id",
  "status": "Pending",
  "totalDurationMinutes": 50,
  "totalPrice": 400,
  "appointmentDate": "2026-04-24",
  "startTime": "14:30",
  "endTime": "15:20"
}
Randevularım
GET /api/v1/appointments/my

Query:

status
page
pageSize
Randevu Detay
GET /api/v1/appointments/{appointmentId}
Randevu İptal Et
POST /api/v1/appointments/{appointmentId}/cancel

Request:

{
  "reason": "Planım değişti."
}

Kurallar:

Randevu başlangıcına belirli süreden az kaldıysa iptal engellenebilir
Online ödeme yapıldıysa iade süreci başlatılmalıdır
İptal edilen randevunun status değeri Cancelled olmalıdır
Berbere ve müşteriye bildirim gönderilmelidir
Randevu Onayla
POST /api/v1/appointments/{appointmentId}/confirm

Yetki:

BarberOwner
Staff
Admin
Randevu Tamamla
POST /api/v1/appointments/{appointmentId}/complete

Yetki:

BarberOwner
Staff
Admin
7.8 Payment Endpoints
Ödeme Başlat
POST /api/v1/payments/start

Request:

{
  "appointmentId": "appointment-id",
  "paymentMethod": "OnlineCard",
  "couponCode": "HOSGELDIN15"
}

Response:

{
  "paymentId": "payment-id",
  "amount": 340,
  "currency": "TRY",
  "paymentPageUrl": "https://payment-provider.com/pay/xxx"
}
Berberde Öde Seç
POST /api/v1/payments/pay-at-barber

Request:

{
  "appointmentId": "appointment-id"
}
Ödeme Callback / Webhook
POST /api/v1/payments/webhook

Bu endpoint ödeme sağlayıcısı tarafından çağrılır.

Kurallar:

Webhook signature doğrulanmalıdır
Aynı işlem iki kez işlenmemelidir
Payment status güncellenmelidir
Appointment status uygun şekilde güncellenmelidir
Müşteriye bildirim gönderilmelidir
7.9 Favorite Endpoints
Favorilerim
GET /api/v1/favorites
Favoriye Ekle
POST /api/v1/favorites/{barberShopId}
Favoriden Çıkar
DELETE /api/v1/favorites/{barberShopId}
7.10 Review Endpoints
Berber Yorumları
GET /api/v1/barbers/{barberShopId}/reviews
Yorum Oluştur
POST /api/v1/reviews

Request:

{
  "appointmentId": "appointment-id",
  "rating": 5,
  "comment": "Çok memnun kaldım."
}

Kurallar:

Sadece tamamlanmış randevuya yorum yapılabilir
Kullanıcı sadece kendi randevusuna yorum yapabilir
Aynı randevuya ikinci yorum yapılamaz
Rating 1-5 arasında olmalıdır
7.11 Notification Endpoints
Bildirimlerim
GET /api/v1/notifications
Bildirimi Okundu Yap
POST /api/v1/notifications/{notificationId}/read
Tüm Bildirimleri Okundu Yap
POST /api/v1/notifications/read-all
7.12 Coupon Endpoints
Kupon Kontrol
POST /api/v1/coupons/validate

Request:

{
  "code": "HOSGELDIN15",
  "amount": 400
}

Response:

{
  "isValid": true,
  "discountAmount": 60,
  "finalAmount": 340
}
8. Randevu Slot Hesaplama Mantığı

Randevu slot hesaplama backend tarafında yapılmalıdır. Frontend sadece backend’den dönen uygun saatleri göstermelidir. Yoksa herkes kendi kafasına göre saat üretir, sonra 14:30’da üç kişi aynı koltuğa oturur. Medeniyet dediğimiz şey bunu engellemektir.

8.1 Slot Hesaplama Adımları
1. Seçilen hizmetlerin toplam süresi hesaplanır.
2. Berberin çalışma saatleri alınır.
3. Personel seçildiyse personelin çalışma saatleri alınır.
4. Personelin mola/kapanış saatleri çıkarılır.
5. Aynı tarihteki mevcut randevular alınır.
6. Çakışan saatler çıkarılır.
7. Geriye kalan uygun slotlar döndürülür.
8.2 Çakışma Kontrolü

Yeni randevu:

StartTime = 14:00
EndTime = 14:45

Mevcut randevu:

StartTime = 14:30
EndTime = 15:00

Bu durumda çakışma vardır.

SQL mantığı:

WHERE AppointmentDate = @Date
AND StaffMemberId = @StaffMemberId
AND Status IN ('Pending', 'Confirmed', 'Upcoming')
AND (
    @NewStartTime < EndTime
    AND @NewEndTime > StartTime
)
9. Bildirim Sistemi

Bildirimler iki şekilde olmalıdır:

In-app notification
Push notification
9.1 Bildirim Senaryoları
Randevu oluşturuldu
Randevu onaylandı
Randevu iptal edildi
Randevuya 1 saat kaldı
Ödeme başarılı
Ödeme başarısız
Yeni kampanya
Yorum isteği
9.2 Push Notification

Mobil uygulama için Firebase Cloud Messaging önerilir.

Backend tarafında kullanıcı cihaz tokenları tutulmalıdır.

Tablo:

CREATE TABLE UserDeviceTokens (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    DeviceToken NVARCHAR(MAX) NOT NULL,
    Platform NVARCHAR(20) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_UserDeviceTokens_Users 
        FOREIGN KEY (UserId) REFERENCES Users(Id)
);
10. Dosya ve Görsel Yönetimi

Görseller backend üzerinden veya CDN/object storage üzerinden yönetilmelidir.

Önerilen seçenekler:

AWS S3
Azure Blob Storage
Cloudflare R2
MinIO
Sunucu local storage

MVP için:

Local storage kullanılabilir

Production için:

Object storage önerilir
10.1 Görsel Tipleri
Kullanıcı profil fotoğrafı
Berber kapak fotoğrafı
Berber logo
Berber galeri görselleri
Personel avatar
10.2 Upload Endpointleri
POST /api/v1/files/upload
POST /api/v1/barbers/{barberShopId}/images
POST /api/v1/users/me/profile-image
POST /api/v1/staff/{staffMemberId}/avatar

Dosya kuralları:

Maksimum dosya boyutu: 5 MB
İzin verilen formatlar: jpg, jpeg, png, webp
Dosya adı random GUID olmalı
Orijinal dosya adı direkt kullanılmamalı
11. Admin Panel Backend İhtiyaçları

Admin panel ayrı bir frontend olabilir. Backend aynı API üzerinden admin endpointleri sunabilir.

11.1 Admin Endpoint Grupları
/admin/users
/admin/barbers
/admin/appointments
/admin/payments
/admin/reviews
/admin/coupons
/admin/support-tickets
/admin/reports
11.2 Admin İşlevleri
Kullanıcı listeleme
Kullanıcı pasife alma
Berber onaylama
Berber pasife alma
Randevu takip
Ödeme takip
Yorum moderasyonu
Kupon oluşturma
Destek taleplerini yönetme
Raporlama
12. Güvenlik Gereksinimleri
12.1 Temel Güvenlik
JWT access token kısa ömürlü olmalı
Refresh token veritabanında saklanmalı
Şifreler BCrypt / Argon2 ile hashlenmeli
OTP hashli veya süreli şekilde saklanmalı
Rate limit uygulanmalı
Login brute force engellenmeli
Admin endpointleri role bazlı korunmalı
Kullanıcı sadece kendi verisine erişebilmeli
12.2 Rate Limit

Önerilen limitler:

Login: Dakikada 5 istek
OTP gönderimi: Dakikada 1 istek
OTP doğrulama: Dakikada 5 istek
Randevu oluşturma: Dakikada 5 istek
Genel API: Dakikada 100 istek
12.3 Veri Yetki Kontrolü

Örnek:

Customer sadece kendi randevusunu görebilir.
BarberOwner sadece kendi işletmesine ait randevuları görebilir.
Staff sadece kendisine atanmış randevuları görebilir.
Admin tüm verileri görebilir.
13. Hata Yönetimi

API tüm hatalarda standart response dönmelidir.

13.1 Başarılı Response
{
  "success": true,
  "data": {},
  "message": "İşlem başarılı."
}
13.2 Hatalı Response
{
  "success": false,
  "message": "Seçilen saat uygun değil.",
  "errors": [
    {
      "field": "startTime",
      "message": "Bu saat için başka bir randevu bulunmaktadır."
    }
  ]
}
13.3 HTTP Status Kodları
200 OK
201 Created
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Validation Error
500 Internal Server Error
14. Validation Kuralları
14.1 Kullanıcı
FullName zorunlu
PhoneNumber zorunlu ve benzersiz
Email opsiyonel ama girildiyse geçerli formatta olmalı
Password minimum 8 karakter olmalı
14.2 Berber
Name zorunlu
City zorunlu
District zorunlu
Address zorunlu
Latitude/Longitude opsiyonel
Berber aktif olmadan listede görünmemeli
Admin onayı olmayan berber public listede görünmemeli
14.3 Hizmet
Name zorunlu
DurationMinutes minimum 5 olmalı
Price 0'dan büyük olmalı
Pasif hizmet randevuda seçilememeli
14.4 Randevu
AppointmentDate geçmiş tarih olamaz
StartTime çalışma saatleri dışında olamaz
Seçilen hizmetler aktif olmalı
Personel aktif olmalı
Çakışan randevu olmamalı
Toplam fiyat frontend’den değil backend’den hesaplanmalı
15. Background Jobs

Backend tarafında zamanlanmış işler kullanılmalıdır.

Önerilen teknoloji:

.NET için Hangfire
Node.js için BullMQ
Laravel için Queue + Scheduler
15.1 Job Senaryoları
Randevuya 1 saat kala bildirim gönder
Randevu sonrası yorum isteği gönder
Süresi geçmiş pending ödemeleri iptal et
Günlük rapor oluştur
Kullanılmayan OTP kayıtlarını temizle
Pasif refresh tokenları temizle
16. Loglama

Backend’de merkezi loglama yapılmalıdır.

Loglanacak işlemler:

Login denemeleri
Başarılı girişler
Başarısız girişler
Randevu oluşturma
Randevu iptal
Ödeme sonucu
Admin işlemleri
Yetkisiz erişim denemeleri
API hataları

Önerilen araçlar:

Serilog
ElasticSearch + Kibana
Seq
Application Insights
Grafana Loki

MVP için:

Serilog + dosya log

Production için:

Serilog + merkezi log sistemi
17. Cache Kullanımı

Yoğun okunan veriler cache’e alınabilir.

Cache adayları:

Berber listeleme
Berber detay
Hizmet listesi
Kategori listesi
Çalışma saatleri

Dikkat:

Randevu uygunluk slotları dikkatli cachelenmelidir.
Yanlış cache, aynı saate iki randevu gibi felaketlere yol açabilir.

Önerilen cache:

Redis
18. Ödeme Entegrasyonu

Türkiye için kullanılabilecek ödeme sağlayıcıları:

iyzico
PayTR
Param
Paynet
Stripe, Türkiye desteği sınırlı olabilir

MVP için iki ödeme seçeneği yeterlidir:

Online ödeme
Berberde öde
18.1 Ödeme Akışı
1. Kullanıcı randevu oluşturur.
2. Appointment status Pending olur.
3. Kullanıcı ödeme yöntemini seçer.
4. Online ödeme ise payment provider session başlatılır.
5. Ödeme başarılı olursa Payment status Paid olur.
6. Appointment status Confirmed olur.
7. Kullanıcıya ve berbere bildirim gönderilir.
18.2 Berberde Öde Akışı
1. Kullanıcı randevu oluşturur.
2. Berberde öde seçilir.
3. Payment status Pending kalabilir veya PayAtBarber olarak işaretlenir.
4. Appointment status Confirmed veya Pending olabilir.
5. Berber onayı gerekiyorsa Pending kalır.
19. MVP Kapsamı

İlk versiyonda aşağıdaki backend özellikleri yeterlidir.

Kullanıcı kayıt / giriş
OTP doğrulama
Profil görüntüleme / güncelleme
Berber listeleme
Berber detay
Hizmet listeleme
Personel listeleme
Uygun saat listeleme
Randevu oluşturma
Randevularım
Randevu iptal
Berberde öde
Favoriler
Bildirim listesi
Admin berber onaylama

İlk MVP’de ertelenebilecek özellikler:

Online ödeme
Google / Apple login
Canlı destek
Gelişmiş raporlama
Kupon sistemi
Harita bazlı detaylı arama
Yorum moderasyonu
Personel paneli
20. Backend Proje Klasör Yapısı - .NET 8 Önerisi
src/
│
├── BerberYanimda.Api/
│   ├── Controllers/
│   ├── Middlewares/
│   ├── Filters/
│   ├── Extensions/
│   └── Program.cs
│
├── BerberYanimda.Application/
│   ├── Features/
│   │   ├── Auth/
│   │   ├── Users/
│   │   ├── BarberShops/
│   │   ├── Services/
│   │   ├── Staff/
│   │   ├── Appointments/
│   │   ├── Payments/
│   │   ├── Favorites/
│   │   ├── Reviews/
│   │   └── Notifications/
│   │
│   ├── Common/
│   ├── Interfaces/
│   └── DTOs/
│
├── BerberYanimda.Domain/
│   ├── Entities/
│   ├── Enums/
│   ├── ValueObjects/
│   └── Events/
│
├── BerberYanimda.Infrastructure/
│   ├── Persistence/
│   ├── Repositories/
│   ├── Services/
│   ├── Storage/
│   ├── Sms/
│   ├── Payment/
│   └── Notifications/
│
└── BerberYanimda.Tests/
    ├── UnitTests/
    └── IntegrationTests/
21. Önerilen Entity Listesi
User
RefreshToken
OtpCode
BarberShop
BarberShopImage
BarberService
StaffMember
StaffService
WorkingHour
StaffBreak
Appointment
AppointmentService
Payment
FavoriteBarberShop
Review
Notification
UserDeviceToken
Coupon
CouponUsage
SupportTicket
AuditLog
22. Önerilen Enum Listesi
public enum UserRole
{
    Customer,
    BarberOwner,
    Staff,
    Admin
}

public enum AppointmentStatus
{
    Pending,
    Confirmed,
    Upcoming,
    Completed,
    Cancelled,
    Rejected,
    NoShow
}

public enum PaymentStatus
{
    Pending,
    Paid,
    Failed,
    Refunded,
    Cancelled
}

public enum PaymentMethod
{
    OnlineCard,
    PayAtBarber,
    Wallet
}

public enum NotificationType
{
    AppointmentConfirmed,
    AppointmentReminder,
    AppointmentCancelled,
    PaymentSuccess,
    PaymentFailed,
    Campaign,
    System
}
23. API Response Standardı

Tüm endpointler ortak response model kullanmalıdır.

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public List<ApiError>? Errors { get; set; }
}

public class ApiError
{
    public string? Field { get; set; }
    public string Message { get; set; }
}

Sayfalı response:

public class PagedResponse<T>
{
    public List<T> Items { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages { get; set; }
}
24. Örnek Randevu Oluşturma Servis Mantığı
CreateAppointment işlemi şu sırayla çalışmalıdır:

1. Kullanıcı doğrulanır.
2. Berber bulunur.
3. Berber aktif ve onaylı mı kontrol edilir.
4. Seçilen hizmetler bulunur.
5. Hizmetler aktif mi kontrol edilir.
6. Personel seçildiyse personel bulunur.
7. Personel bu hizmetleri verebiliyor mu kontrol edilir.
8. Toplam süre hesaplanır.
9. Toplam fiyat hesaplanır.
10. Başlangıç saatine göre bitiş saati hesaplanır.
11. Çalışma saatleri kontrol edilir.
12. Mola/kapanış saatleri kontrol edilir.
13. Mevcut randevularla çakışma kontrol edilir.
14. Appointment kaydı oluşturulur.
15. AppointmentServices kayıtları oluşturulur.
16. Bildirim oluşturulur.
17. Response döndürülür.
25. Test Senaryoları
25.1 Auth Testleri
Geçerli telefon ve şifre ile giriş yapılmalı
Hatalı şifre ile giriş engellenmeli
Pasif kullanıcı giriş yapamamalı
OTP süresi dolduysa doğrulama başarısız olmalı
OTP yanlışsa deneme sayısı artmalı
25.2 Randevu Testleri
Geçmiş tarihe randevu oluşturulamamalı
Çalışma saati dışında randevu oluşturulamamalı
Aynı personele aynı saatte iki randevu oluşturulamamalı
Pasif hizmet ile randevu oluşturulamamalı
Pasif personele randevu oluşturulamamalı
Toplam fiyat backend tarafından doğru hesaplanmalı
Randevu iptal edildiğinde status Cancelled olmalı
25.3 Ödeme Testleri
Ödeme başlatılınca Payment Pending olmalı
Başarılı webhook sonrası Payment Paid olmalı
Başarılı ödeme sonrası Appointment Confirmed olmalı
Aynı webhook iki kez gelirse tekrar işlem yapılmamalı
25.4 Yetki Testleri
Customer başka kullanıcının randevusunu görememeli
BarberOwner başka berberin randevusunu görememeli
Staff sadece kendi randevularını görebilmeli
Admin tüm randevuları görebilmeli
26. Production Hazırlık Kontrol Listesi
HTTPS aktif
JWT secret güvenli ortam değişkeninde
Connection string güvenli ortam değişkeninde
Database migration sistemi hazır
Loglama aktif
Global exception middleware aktif
Rate limiting aktif
CORS doğru yapılandırılmış
Swagger production’da kapalı veya korumalı
Admin endpointleri role bazlı korunuyor
Dosya upload validasyonu yapılıyor
Payment webhook signature doğrulanıyor
Backup planı mevcut
Monitoring aktif
27. Ortam Değişkenleri
ASPNETCORE_ENVIRONMENT=Production

ConnectionStrings__DefaultConnection=Server=...;Database=BerberYanimdaDb;User Id=...;Password=...;

Jwt__Issuer=BerberYanimda
Jwt__Audience=BerberYanimdaMobile
Jwt__Secret=SUPER_SECRET_KEY
Jwt__AccessTokenMinutes=60
Jwt__RefreshTokenDays=30

Sms__Provider=NetGsm
Sms__Username=
Sms__Password=
Sms__Header=

Payment__Provider=Iyzico
Payment__ApiKey=
Payment__SecretKey=
Payment__CallbackUrl=

Storage__Provider=Local
Storage__BaseUrl=https://cdn.berberyanimda.com

Firebase__ServerKey=
28. Genel Notlar

Bu backend dokümanı, Berber Yanımda mobil uygulamasının ilk ve orta seviye geliştirme ihtiyaçlarını karşılayacak şekilde hazırlanmıştır.

Backend geliştirici şu konulara özellikle dikkat etmelidir:

Randevu saat çakışması engellenmeli
Toplam fiyat frontend’den alınmamalı, backend hesaplamalı
Yetki kontrolleri endpoint bazında yapılmalı
Online ödeme webhook güvenliği sağlanmalı
Berber ve personel pasif kayıtları randevu akışında kullanılmamalı
Geçmiş randevular fiyat/hizmet değişikliklerinden etkilenmemeli
Bildirim sistemi event bazlı kurgulanmalı

Bu sistem doğru kurulursa proje büyüdüğünde admin panel, berber paneli, personel paneli, online ödeme, kampanya sistemi ve raporlama kolayca eklenebilir. Yanlış kurulursa da her yeni özellikte backend’in duvarına kafa atılır. O yüzden bu doküman şaka değil, temel iskelet.