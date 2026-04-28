import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/core/widgets/cards/featured_barber_card.dart';
import 'package:berber_yanimda/src/core/widgets/cards/popular_services_row.dart';
import 'package:berber_yanimda/src/data/mock_data.dart';
import 'package:berber_yanimda/src/features/main/widgets/barber_list_content.dart';
import 'package:berber_yanimda/src/features/main/widgets/chip_row.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_inputs.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final catalog = ref.watch(catalogProvider);
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          HomeHeader(
            userName: auth.userName,
            location: l10n.exploreNearby,
            unreadCount: 0,
            profileImageUrl: auth.profile?.profileImageUrl,
            onNotificationTap: auth.isLoggedIn
                ? () => context.push('/notifications')
                : () => context.go('/login'),
          ),
          const SizedBox(height: 18),
          const SearchInput(),
          const SizedBox(height: 14),
          ChipRow(
            items: [l10n.all, l10n.popular, l10n.maleBarber, l10n.beard, l10n.skinCare],
          ),
          if (catalog.barbers.isNotEmpty) ...[
            const SizedBox(height: 16),
            FeaturedBarberCard(
              barber: catalog.barbers.first,
              onTap: () {
                ref.read(catalogProvider.notifier).selectBarber(catalog.barbers.first);
                context.push('/barber/${catalog.barbers.first.id}');
              },
            ),
          ],
          const SizedBox(height: 18),
          SectionHeader(
            title: l10n.nearbyBarbers,
            actionText: l10n.viewAll,
            onAction: () => context.go('/barbers'),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 18),
          PopularServicesRow(services: MockData.services),
        ],
      ),
    );
  }
}
