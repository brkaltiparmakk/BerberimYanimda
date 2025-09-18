import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(promotionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kampanyalar')),
      body: promotionsAsync.when(
        data: (promotions) {
          if (promotions.isEmpty) {
            return const EmptyState(icon: Icons.local_offer_outlined, message: 'Aktif kampanya bulunmuyor.');
          }
          return ListView.builder(
            itemCount: promotions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(promo.title),
                  subtitle: Text('${promo.discountRate.toStringAsFixed(0)}% • ${promo.startDate.day}.${promo.startDate.month} - ${promo.endDate.day}.${promo.endDate.month}'),
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Randevuya Uygula'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Kampanyalar yüklenemedi: $error')),
      ),
    );
  }
}
