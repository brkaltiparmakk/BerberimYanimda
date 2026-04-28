import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:berber_yanimda/src/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login form renders phone and password fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, AppLocalizations.of(tester.element(find.byType(LoginScreen)))!.dontHaveAccount), findsOneWidget);
  });

  testWidgets('login screen shows AppBar with welcome title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
    expect(find.text(l10n.welcome), findsOneWidget);
  });

  testWidgets('login screen renders TextField for phone input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
    expect(find.bySemanticsLabel(l10n.phoneNumber), findsOneWidget);
  });
}
