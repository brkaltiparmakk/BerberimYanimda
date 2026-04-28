import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/features/main/widgets/inline_error.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';

class BarberListContent extends StatelessWidget {
  const BarberListContent({
    super.key,
    required this.barbers,
    required this.isBusy,
    required this.errorMessage,
    required this.onRetry,
    required this.onTap,
    required this.onFavorite,
    required this.onBook,
    this.emptyMessage,
  });

  final List<Barber> barbers;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<Barber> onTap;
  final ValueChanged<Barber> onFavorite;
  final ValueChanged<Barber> onBook;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (barbers.isEmpty) {
      return EmptyState(
        message: errorMessage ?? emptyMessage ?? l10n.noBarbersFound,
        loading: isBusy,
        onRetry: onRetry,
      );
    }

    return Column(
      children: [
        if (isBusy)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (errorMessage != null) ...[
          InlineError(message: errorMessage!, onRetry: onRetry),
          const SizedBox(height: 12),
        ],
        for (final barber in barbers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MergeSemantics(
              child: BarberCard(
                barber: barber,
                onTap: () => onTap(barber),
                onFavorite: () => onFavorite(barber),
                onBook: () => onBook(barber),
              ),
            ),
          ),
      ],
    );
  }
}
