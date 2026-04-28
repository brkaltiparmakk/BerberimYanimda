import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Text(
            '''BerberYanimda Gizlilik Politikası

1. Veri Sorumlusu
BerberYanimda olarak, kişisel verilerinizin güvenliği bizim için önemlidir. 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında veri sorumlusu olarak hareket ediyoruz.

2. Toplanan Veriler
- Kimlik bilgileri (ad soyad)
- İletişim bilgileri (telefon numarası, e-posta)
- Lokasyon bilgisi (yakındaki berberleri listelemek için)
- Randevu geçmişi ve tercihleri
- Ödeme bilgileri (kredi kartı bilgisi sistemimizde saklanmaz)

3. Veri Kullanım Amaçları
- Randevu oluşturma ve yönetme
- Berber hizmetleri sunma
- Kampanya ve bildirim gönderme
- Kullanıcı deneyimini iyileştirme

4. Veri Saklama Süresi
Kişisel verileriniz, hesabınız aktif olduğu sürece veya yasal yükümlülüklerimizin gerektirdiği süre boyunca saklanır.

5. Haklarınız
KVKK kapsamında; verilerinize erişme, düzeltme, silme, işlemeye itiraz etme ve taşınabilirlik hakkına sahipsiniz.

6. İletişim
Gizlilik politikası ile ilgili sorularınız için: destek@berberyanimda.com

Son güncelleme: Nisan 2026''',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ),
      ),
    );
  }
}
