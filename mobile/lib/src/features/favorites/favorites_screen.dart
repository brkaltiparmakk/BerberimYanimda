import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/features/main/widgets/barber_list_content.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(favoritesProvider.notifier).loadFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = ref.watch(favoritesProvider);
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      currentIndex: 3,
      title: l10n.myFavorites,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          BarberListContent(
            barbers: fav.favorites,
            isBusy: fav.isBusy,
            errorMessage: fav.errorMessage,
            emptyMessage: l10n.noFavorites,
            onRetry: () => ref.read(favoritesProvider.notifier).loadFavorites(),
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
