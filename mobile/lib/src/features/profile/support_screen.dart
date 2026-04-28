import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/core/widgets/buttons/primary_button.dart';
import 'package:berber_yanimda/src/core/widgets/inputs/app_text_field.dart';
import 'package:berber_yanimda/src/core/widgets/navigation/custom_app_bar.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _isLoading = false;

  bool _validate() {
    return _subject.text.trim().isNotEmpty && _description.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Yardım & Destek',
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Yeni Destek Talebi', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            AppTextField(
              controller: _subject,
              hintText: 'Konu',
              icon: Icons.subject,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _description,
              hintText: 'Açıklama',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: _isLoading ? 'Gönderiliyor...' : 'Gönder',
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (!_validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen konu ve açıklama alanlarını doldurun.'),
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final success = await ref.read(supportProvider.notifier).createTicket(
                        _subject.text.trim(),
                        _description.text.trim(),
                      );
                      setState(() => _isLoading = false);

                      if (success && context.mounted) {
                        _subject.clear();
                        _description.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Destek talebiniz alındı.')),
                        );
                      } else if (context.mounted) {
                        final error = ref.read(supportProvider).errorMessage ?? 'Bir hata oluştu.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
            ),
            const SizedBox(height: 24),
            Text('Sıkça Sorulan Sorular', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _FaqItem(
              question: 'Randevumu nasıl iptal edebilirim?',
              answer: 'Randevularım ekranından iptal edebilirsiniz.',
            ),
            _FaqItem(
              question: 'Ödeme yöntemleri nelerdir?',
              answer: 'Berberde ödeme ve online ödeme seçenekleri mevcuttur.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ExpansionTile(
        title: Text(question, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(answer, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}
