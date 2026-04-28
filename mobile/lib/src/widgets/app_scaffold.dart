import 'package:berber_yanimda/src/core/widgets/navigation/app_bottom_nav_bar.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.title,
    this.actions,
  });

  final Widget child;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: false,
            ),
      body: SafeArea(child: child),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        isBarber: auth.isBarber,
      ),
    );
  }
}
