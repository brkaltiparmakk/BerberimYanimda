import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Şartları'),
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
            '''BerberYanimda Kullanım Şartları

1. Hizmet Tanımı
BerberYanimda, kullanıcıların berber ve kuaför randevuları oluşturmasına, yönetmesine ve ödeme yapmasına olanak tanıyan bir dijital platformdur.

2. Üyelik
- 18 yaşından büyük olmanız gerekir.
- Doğru ve güncel bilgi vermekle yükümlüsünüz.
- Hesap güvenliğinizden siz sorumlusunuz.

3. Randevu ve İptal
- Randevular berber tarafından onaylanır.
- İptal politikası berberin belirlediği kurallara tabidir.
- Geç kalma durumunda randevu geçersiz sayılabilir.

4. Ödeme
- Platform üzerinden online ödeme yapılabilir.
- İade politikası her berberin kendi koşullarına tabidir.

5. Sorumluluk Reddi
- Berberlerin sunduğu hizmetlerin kalitesinden berberler sorumludur.
- Platform sadece aracıdır.

6. Fesih
Hizmet şartlarını ihlal eden hesaplar kapatılabilir.

Son güncelleme: Nisan 2026''',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ),
      ),
    );
  }
}
