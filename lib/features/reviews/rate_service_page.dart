import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class RateServicePage extends ConsumerStatefulWidget {
  const RateServicePage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<RateServicePage> createState() => _RateServicePageState();
}

class _RateServicePageState extends ConsumerState<RateServicePage> {
  double _rating = 4;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final appointment = await client
        .from('appointments')
        .select<Map<String, dynamic>>('business_id')
        .eq('id', widget.appointmentId)
        .maybeSingle();
    if (appointment == null) {
      setState(() => _submitting = false);
      return;
    }

    await client.from('reviews').insert({
      'appointment_id': widget.appointmentId,
      'business_id': appointment['business_id'],
      'customer_id': userId,
      'rating': _rating.round(),
      'comment': _commentCtrl.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Değerlendirmeniz için teşekkürler.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hizmeti Değerlendir')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingBar.builder(
              initialRating: _rating,
              allowHalfRating: true,
              minRating: 1,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Yorumunuzu Yazın...',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            PrimaryButton(
              onPressed: _submitting ? null : _submit,
              label: _submitting ? 'Gönderiliyor...' : 'Gönder',
            ),
          ],
        ),
      ),
    );
  }
}
