import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/supabase_client.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: BerberimApp()));
}

class BerberimApp extends ConsumerWidget {
  const BerberimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Berberim Yanımda',
      theme: ref.watch(themeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
