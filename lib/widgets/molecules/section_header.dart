import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll, this.trailing});

  final String title;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          trailing ??
              TextButton(
                onPressed: onViewAll,
                child: const Text('Tümü'),
              ),
        ],
      ),
    );
  }
}
