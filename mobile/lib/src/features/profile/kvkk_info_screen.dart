import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class KvkkInfoScreen extends StatelessWidget {
  const KvkkInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KVKK Aydınlatma Metni'),
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
            '''KVKK Aydınlatma Metni

Değerli Kullanıcımız,

6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, kişisel verilerinizin hangi amaçla işleneceği, kimlere aktarılabileceği ve haklarınızın neler olduğu hakkında sizi bilgilendirmek isteriz.

1. Veri Sorumlusu
BerberYanimda olarak, KVKK kapsamında veri sorumlusu sıfatıyla kişisel verilerinizi korumakla yükümlüyüz.

2. İşlenen Kişisel Veriler
- Kimlik bilgileri (ad, soyad)
- İletişim bilgileri (telefon numarası, e-posta adresi)
- Konum bilgisi (yakındaki hizmet sağlayıcıları göstermek için)
- Randevu ve ödeme geçmişi
- Cihaz bilgisi (bildirim gönderimi için)

3. Verilerin İşlenme Amaçları
- Randevu oluşturma, yönetme ve hatırlatma
- Hizmet sağlayıcılar ile iletişim
- Kampanya, duyuru ve bildirim gönderimi
- Ödeme işlemleri
- Yasal yükümlülüklerin yerine getirilmesi

4. Veri Aktarımı
Kişisel verileriniz, yasal zorunluluklar dışında üçüncü taraflarla paylaşılmaz.

5. Haklarınız
KVKK'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:
- Kişisel verilerinizin işlenip işlenmediğini öğrenme
- Kişisel verileriniz işlenmişse buna ilişkin bilgi talep etme
- İşlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme
- Verilerinizin eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme
- Verilerinizin silinmesini veya yok edilmesini isteme
- İşlenen verilerinizin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme

6. İletişim
Haklarınızı kullanmak veya sorularınız için: destek@berberyanimda.com

Son güncelleme: Nisan 2026''',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ),
      ),
    );
  }
}
