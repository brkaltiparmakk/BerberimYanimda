import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ödeme Yöntemi Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            RadioListTile<String>(
              value: 'card',
              groupValue: 'card',
              onChanged: (_) {},
              title: const Text('Kredi/Banka Kartı (Stripe placeholder)'),
              subtitle: const Text('Güvenli ödeme için yönlendirileceksiniz.'),
            ),
            RadioListTile<String>(
              value: 'mobile',
              groupValue: 'card',
              onChanged: (_) {},
              title: const Text('Mobil Ödeme'),
            ),
            RadioListTile<String>(
              value: 'onsite',
              groupValue: 'card',
              onChanged: (_) {},
              title: const Text('Salonda Öde'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stripe entegrasyonu yakında.')));
              },
              child: const Text('Ödemeyi Tamamla'),
            ),
          ],
        ),
      ),
    );
  }
}
