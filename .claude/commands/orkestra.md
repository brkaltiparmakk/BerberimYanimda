---
description: Orchestrasyon pipeline'ını başlatır — Orchestrator tüm uzman ajanları sırayla yönetir
argument-hint: "[görev açıklaması]"
---

# Orchestrator Pipeline Başlat

Kullanıcı isteği: $ARGUMENTS

Bu isteği Orchestrator ajanına ilet. Orchestrator şu sırayla çalışacak:
1. İsteği analiz et
2. Gerekirse Solution Architect (tasarım)
3. Implementation Agent (kodlama)
4. Security Auditor (güvenlik kontrolü)
5. Test Engineer (test & doğrulama)
6. Documentation Agent (dokümantasyon)
7. Kullanıcıya özet rapor sun

Orchestrator'a şu prompt ile çalıştır:
```
Kullanıcı isteği: $ARGUMENTS

Lütfen bu isteği analiz et ve gerektiğinde uzman ajanları sırayla çalıştır:
- Eğer tasarım gerekiyorsa önce Solution Architect'i çalıştır
- Sonra Implementation Agent'i devreye sok
- Kod tamamlandığında Security Auditor ile kontrol et
- Ardından Test Engineer ile test et
- En son Documentation Agent ile dokümantasyonu güncelle
- Bana nihai özet rapor sun
```
