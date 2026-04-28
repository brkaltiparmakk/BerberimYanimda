import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/main/widgets/barber_list_content.dart';
import 'package:berber_yanimda/src/features/main/widgets/chip_row.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BarberListScreen extends ConsumerWidget {
  const BarberListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      currentIndex: 1,
      title: l10n.explore,
      actions: [
        IconButton(
          tooltip: l10n.map,
          icon: const Icon(Icons.map_outlined),
          onPressed: () => context.push('/map'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const SearchInput(),
          const SizedBox(height: 14),
          ChipRow(
            items: [
              l10n.nearMe,
              l10n.highestRated,
              l10n.availableNow,
              l10n.bestPrice,
              l10n.favorites,
            ],
          ),
          const SizedBox(height: 16),
          BarberListContent(
            barbers: catalog.barbers,
            isBusy: catalog.isBusy,
            errorMessage: catalog.errorMessage,
            onRetry: () => ref.read(catalogProvider.notifier).loadBarbers(),
            onTap: (barber) {
              ref.read(catalogProvider.notifier).selectBarber(barber);
              context.push('/barber/${barber.id}');
            },
            onFavorite: (barber) =>
                ref.read(favoritesProvider.notifier).toggleFavorite(barber.id),
            onBook: (barber) {
              ref.read(catalogProvider.notifier).selectBarber(barber);
              context.push('/booking/services');
            },
          ),
        ],
      ),
    );
  }
}
