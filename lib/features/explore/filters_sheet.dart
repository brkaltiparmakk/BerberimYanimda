import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

class FiltersSheet extends ConsumerWidget {
  const FiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exploreFiltersProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtreler', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Text('Puan', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: filters.minRating ?? 3,
            min: 1,
            max: 5,
            divisions: 8,
            label: (filters.minRating ?? 3).toStringAsFixed(1),
            onChanged: (value) => ref.read(exploreFiltersProvider.notifier).updateRating(value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.read(exploreFiltersProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: const Text('Sıfırla'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Uygula'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
