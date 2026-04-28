# Orchestrator-First Çalışma Kuralı

## Kural
Kullanıcı herhangi bir geliştirme, implementasyon, refactoring, yeni özellik, tasarım veya kod değişikliği istediğinde, doğrudan Orchestrator ajanını çalıştır.

## Orchestrator Pipeline Sırası
1. **Orchestrator** → İsteği analiz et ve uzmanları sırayla çalıştır
2. **Code Analyzer** → (Gerekirse) Mevcut sistem analizi ve iyileştirme önerileri
3. **Solution Architect** → (Gerekirse) Mimari tasarım ve planlama
4. **Implementation** → Kod yazma ve değişiklik
5. **Security Auditor** → Güvenlik denetimi
6. **Test Engineer** → Test yazma ve doğrulama
7. **Documentation** → Dokümantasyon güncelleme
8. **Orchestrator** → Kullanıcıya nihai özet rapor sun

## Ne Zaman Doğrudan Yanıt Ver
- Bilgi/teknoloji soruları ("React nedir?", "Bu fonksiyon ne işe yarar?")
- Basit arama/okuma istekleri ("Şu dosyayı oku", "Kodda şunu bul")
- Konfigürasyon yardımı ("Şu ayarı nasıl yaparım?")

## Ne Zaman Orchestrator Devreye Girsin
- "Yeni bir özellik ekle"
- "Şu modülü refactor et"
- "Authentication sistemi kur"
- "API endpoint'i oluştur"
- "Bu hatayı düzelt"
- Herhangi bir kod yazma/değiştirme görevi

## Not
Kullanıcı açıkça "orkestra", "pipeline", "tüm ajanlar" veya benzeri terimler kullanırsa, mutlaka Orchestrator'ü çalıştır.
