import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isBarber = false,
  });

  final int currentIndex;
  final bool isBarber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isBarber) {
      return NavigationBar(
        height: 76,
        backgroundColor: AppColors.backgroundPrimary,
        indicatorColor: AppColors.primaryGold.withValues(alpha: 0.16),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              return context.go('/barber/dashboard');
            case 1:
              return context.go('/barber/appointments');
            case 2:
              return context.go('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.appointments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.myProfile,
          ),
        ],
      );
    }

    return NavigationBar(
      height: 76,
      backgroundColor: AppColors.backgroundPrimary,
      indicatorColor: AppColors.primaryGold.withValues(alpha: 0.16),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            return context.go('/home');
          case 1:
            return context.go('/barbers');
          case 2:
            return context.go('/appointments');
          case 3:
            return context.go('/favorites');
          case 4:
            return context.go('/profile');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: l10n.explore,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_today_outlined),
          selectedIcon: const Icon(Icons.calendar_today),
          label: l10n.appointments,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_border),
          selectedIcon: const Icon(Icons.favorite),
          label: l10n.myFavorites,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.myProfile,
        ),
      ],
    );
  }
}
