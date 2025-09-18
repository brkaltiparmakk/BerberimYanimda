# Berberim Yanimda

Modern şehir yaşamında berber/salon randevularını kolayca yönetmek için geliştirilen Flutter + Supabase tabanlı çift yüzlü (müşteri & işletme) uygulama.

## İçerik
- [Teknolojiler](#teknolojiler)
- [Supabase Kurulumu](#supabase-kurulumu)
- [Edge Functions](#edge-functions)
- [Flutter Uygulaması](#flutter-uygulaması)
- [Ortam Değişkenleri](#ortam-değişkenleri)
- [Depolama ve Realtime](#depolama-ve-realtime)
- [Bildirimler](#bildirimler)
- [Test & Analiz](#test--analiz)

## Teknolojiler
- Backend: Supabase (Postgres, Auth, Storage, Realtime, Edge Functions)
- Frontend: Flutter (go_router, Riverpod)
- Bildirim: Firebase Cloud Messaging + flutter_local_notifications
- Harita: Google Maps + Geolocator
- Ödeme: Stripe placeholder (payment_intents tablosu)

## Supabase Kurulumu
1. Supabase CLI kurulu olduğundan emin olun.
2. Projeyi başlatın ve veritabanını seed edin:
   ```bash
   supabase start
   supabase db reset
   ```
   `supabase/sql/schema.sql` şema, index, RLS ve seed verilerini içerir.
3. Gerekli ortam değişkenleri için `supabase/.env` veya `supabase/functions/.env.local` oluşturun (örnek aşağıda).
4. Edge fonksiyonlarını lokal çalıştırma:
   ```bash
   supabase functions serve book_appointment --env-file supabase/functions/.env.local
   ```
5. Dağıtım:
   ```bash
   supabase functions deploy book_appointment
   supabase functions deploy appointment_status_update
   supabase functions deploy rating_after_completion
   supabase functions schedule create rating-reminder \
     --function rating_after_completion \
     --cron "*/30 * * * *"
   ```

## Edge Functions
| Fonksiyon | Açıklama | Önemli Noktalar |
|-----------|----------|-----------------|
| `book_appointment` | Randevu oluşturma, uygunluk & çakışma kontrolü, ödeme intent kaydı | Transactional insert, realtime yayın, audit log |
| `appointment_status_update` | İşletme/staff tarafından durum güncelleme | FCM bildirimi, audit log, RLS uyumlu |
| `rating_after_completion` | Tamamlanan randevular için değerlendirme hatırlatıcısı | Cron uyumlu, bildirim ve realtime yayın |

Her fonksiyon klasöründe README ve curl örnekleri yer alır.

## Flutter Uygulaması
1. Gerekli paketleri indirin:
   ```bash
   flutter pub get
   ```
2. Çalıştırma sırasında Supabase ve Firebase değerlerini iletin:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<anon-key> \
     --dart-define=FCM_SENDER_ID=<firebase_sender_id>
   ```
3. Android
   - `android/app/google-services.json` ekleyin.
   - `android/app/src/main/AndroidManifest.xml` içine Google Maps API key ve FCM izinlerini yerleştirin.
   - `android/app/src/main/res/xml/network_security_config.xml` ile http ayarlarını güncelleyin (gerekiyorsa).
4. iOS
   - `ios/Runner/GoogleService-Info.plist` ekleyin.
   - `AppDelegate.swift` içerisinde `FirebaseApp.configure()` çağırın ve Google Maps key ekleyin.
   - Push bildirim yetkileri için APNs sertifikalarını tanımlayın.

### Proje Yapısı
- `lib/core` : tema, sabitler, yardımcılar
- `lib/app.dart` : go_router rotaları
- `lib/state` : Riverpod provider’ları
- `lib/features` : müşteri & işletme ekranları (auth, explore, booking, appointments, business dashboard, promosyon, raporlar vb.)
- `lib/data` : modeller, repository ve servis katmanı (Supabase, konum, bildirim, Stripe placeholder)
- `lib/widgets` : ortak atom/molekül bileşenleri

## Ortam Değişkenleri
Örnek `.env` içerikleri:
```env
# Supabase Functions
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<anon>
SUPABASE_SERVICE_ROLE_KEY=<service_role>
SUPABASE_DB_URL=postgresql://postgres:<password>@db.<project>.supabase.co:5432/postgres?sslmode=require
FCM_SERVER_KEY=<firebase_server_key>
STRIPE_SECRET_KEY=<opsiyonel>
CUSTOMER_CANCELLATION_LIMIT_HOURS=2
RATING_REMINDER_HOURS=1
```
Flutter tarafında `--dart-define` ile Supabase ve Firebase değerleri aktarılır.

## Depolama ve Realtime
- Storage bucket’ları: `business_photos` (public read), `service_photos` (public read), `user_avatars` (authenticated read).
- Flutter yükleme örnekleri `lib/data/repositories/storage_repository.dart` ve ilgili servislerde bulunur.
- Realtime yayın kanalı: `appointments:business_{id}`. `AppointmentRepository.watchAppointments` içinde kullanım örneği mevcuttur.

## Bildirimler
- `NotificationsService` (lib/data/services/notifications_service.dart) FCM token kaydı ve yerel bildirim kurulumu sağlar.
- Edge fonksiyonları FCM bildirimleri göndermek için `FCM_SERVER_KEY` kullanır.

## Test & Analiz
- Statik analiz: `dart analyze`
- Widget/unit testleri: `flutter test`

Geliştirme sırasında `analysis_options.yaml` kurallarına uyum sağlayın ve mock provider örneği `test/` klasöründe referans olarak kullanılabilir.
