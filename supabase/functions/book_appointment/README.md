# book_appointment

Edge Function randevu rezervasyonu için tüm kuralları uygular.

## Ortam Değişkenleri
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_URL` (postgres bağlantı dizesi, örn. `postgresql://postgres:[password]@db.supabase.co:5432/postgres?sslmode=require`)
- `STRIPE_SECRET_KEY` (opsiyonel – varsa payment_intents kaydı oluşturur)

## HTTP
- **URL**: `https://<project>.functions.supabase.co/book_appointment`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "customer_id": "11111111-1111-1111-1111-111111111111",
    "business_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "staff_id": "33333333-3333-3333-3333-333333333333",
    "services": ["77777777-7777-7777-7777-777777777770"],
    "scheduled_at": "2024-06-01T12:00:00Z",
    "notes": "Yanımda arkadaşım olacak"
  }
  ```

## curl Örneği
```bash
curl -X POST "https://<project>.functions.supabase.co/book_appointment" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "11111111-1111-1111-1111-111111111111",
    "business_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "services": [
      {"id": "77777777-7777-7777-7777-777777777770", "quantity": 1},
      "77777777-7777-7777-7777-777777777771"
    ],
    "scheduled_at": "2024-06-01T12:00:00Z"
  }'
```

Function RLS gerektiren tablolarda servis rolü (service_role key) ile çalışır.
