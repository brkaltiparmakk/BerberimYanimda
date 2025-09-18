# Edge Functions

Bu klasör Supabase Edge Functions kaynaklarını içerir. Tüm fonksiyonlar servis rolü anahtarı ile çalışır ve Postgres bağlantısı için `SUPABASE_DB_URL` gerektirir.

## Kurulum
1. `supabase/functions/.env.local` dosyasına aşağıdaki değişkenleri ekleyin:
   ```env
   SUPABASE_URL=https://<project>.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=<service_role>
   SUPABASE_DB_URL=postgresql://postgres:<password>@db.<project>.supabase.co:5432/postgres?sslmode=require
   FCM_SERVER_KEY=<firebase_server_key>
   STRIPE_SECRET_KEY=<opsiyonel>
   CUSTOMER_CANCELLATION_LIMIT_HOURS=2
   RATING_REMINDER_HOURS=1
   ```
2. Lokal geliştirme için: `supabase functions serve book_appointment --env-file supabase/functions/.env.local`.
3. Dağıtım: `supabase functions deploy <function_name>`.

Her klasörde fonksiyonun kendi README’si ve curl örnekleri bulunmaktadır.
