# rating_after_completion

Tamamlanan randevulardan sonra değerlendirme hatırlatması gönderen Edge Function. Cron ile tetiklenir.

## Ortam Değişkenleri
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_URL`
- `FCM_SERVER_KEY`
- `RATING_REMINDER_HOURS` (varsayılan 1)

## HTTP
- **URL**: `https://<project>.functions.supabase.co/rating_after_completion`
- **Method**: `GET` veya `POST`
- **Query**: `limit` (opsiyonel, varsayılan 20, max 100)

## curl
```bash
curl "https://<project>.functions.supabase.co/rating_after_completion?limit=10" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

Supabase CLI cron örneği:
```bash
supabase functions deploy rating_after_completion
supabase functions schedule create rating-reminder \
  --function rating_after_completion \
  --cron "*/30 * * * *"
```
