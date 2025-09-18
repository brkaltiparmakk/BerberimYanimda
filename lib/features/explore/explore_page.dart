import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';
import 'barber_card.dart';
import 'filters_sheet.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(exploreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berber Keşfet'),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const FiltersSheet(),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Ara...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => ref.read(exploreFiltersProvider.notifier).updateQuery(value),
            ),
          ),
          Expanded(
            child: businessesAsync.when(
              data: (businesses) {
                if (businesses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'Yakınınızda işletme bulunamadı.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    return BarberCard(
                      business: business,
                      onTap: () => context.go('/business/${business.id}'),
                      onBookTap: () => context.go('/booking/services/${business.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Hata: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/explore/map'),
        label: const Text('Haritada Gör'),
        icon: const Icon(Icons.map_outlined),
      ),
    );
  }
}
