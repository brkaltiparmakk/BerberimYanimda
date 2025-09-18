# appointment_status_update

İşletme tarafının randevu durumlarını güncellemesi için Edge Function.

## Ortam Değişkenleri
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_URL`
- `FCM_SERVER_KEY` (push bildirimleri)
- `CUSTOMER_CANCELLATION_LIMIT_HOURS` (varsayılan 2)

## HTTP
- **URL**: `https://<project>.functions.supabase.co/appointment_status_update`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "appointment_id": "99999999-aaaa-bbbb-cccc-000000000001",
    "new_status": "approved",
    "actor_id": "22222222-2222-2222-2222-222222222222",
    "reason": "Bekliyoruz"
  }
  ```

## curl
```bash
curl -X POST "https://<project>.functions.supabase.co/appointment_status_update" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": "99999999-aaaa-bbbb-cccc-000000000001",
    "new_status": "approved",
    "actor_id": "22222222-2222-2222-2222-222222222222"
  }'
```

Servis rolü anahtarı, RLS kısıtlarını aşmak için gereklidir. Fonksiyon; bildirim, audit log ve realtime yayınları tetikler.
