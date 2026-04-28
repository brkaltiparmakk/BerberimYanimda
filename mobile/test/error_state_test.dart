import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:berber_yanimda/src/core/widgets/feedback/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState renders message text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: EmptyState(message: 'Test empty message'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test empty message'), findsOneWidget);
  });

  testWidgets('EmptyState shows retry button when onRetry is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EmptyState(
            message: 'Error occurred',
            onRetry: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(EmptyState)))!;
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('EmptyState shows loading indicator when loading is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: EmptyState(message: 'Loading...', loading: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
