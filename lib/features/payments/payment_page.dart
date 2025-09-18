import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'card';

  void _updateSelection(String? value) {
    if (value == null) return;
    setState(() {
      _selectedMethod = value;
    });
  }

  void _completePayment(BuildContext context) {
    late final String message;

    switch (_selectedMethod) {
      case 'card':
        message = 'Stripe entegrasyonu yakında.';
        break;
      case 'mobile':
        message = 'Mobil ödeme seçeneği yakında kullanımda olacak.';
        break;
      case 'onsite':
        message = 'Ödemenizi randevu gününde salonda gerçekleştirebilirsiniz.';
        break;
      default:
        message = 'Ödeme yöntemi seçilemedi.';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
              groupValue: _selectedMethod,
              onChanged: _updateSelection,
              title: const Text('Kredi/Banka Kartı (Stripe placeholder)'),
              subtitle: const Text('Güvenli ödeme için yönlendirileceksiniz.'),
            ),
            RadioListTile<String>(
              value: 'mobile',
              groupValue: _selectedMethod,
              onChanged: _updateSelection,
              title: const Text('Mobil Ödeme'),
            ),
            RadioListTile<String>(
              value: 'onsite',
              groupValue: _selectedMethod,
              onChanged: _updateSelection,
              title: const Text('Salonda Öde'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _completePayment(context),
              child: const Text('Ödemeyi Tamamla'),
            ),
          ],
        ),
      ),
    );
  }
}
