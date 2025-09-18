import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class BusinessDashboardPage extends ConsumerStatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  ConsumerState<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends ConsumerState<BusinessDashboardPage> {
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(supabaseClientProvider)
        .from('profiles')
        .select<Map<String, dynamic>>('default_business_id')
        .maybeSingle();
    setState(() {
      _businessId = profile?['default_business_id'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.store, message: 'İşletme bilgisi bulunamadı.'));
    }

    final metricsAsync = ref.watch(businessDashboardProvider(_businessId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Kontrol Paneli')),
      body: metricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return const EmptyState(icon: Icons.dashboard_customize, message: 'Gösterilecek veri bulunamadı.');
          }
          final upcoming = metrics['upcoming_count'] ?? 0;
          final completed = metrics['completed_count'] ?? 0;
          final revenue = metrics['total_revenue'] ?? 0;
          final popular = (metrics['popular_services'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _KpiCard(title: 'Yaklaşan', value: '$upcoming'),
                  _KpiCard(title: 'Tamamlanan', value: '$completed'),
                  _KpiCard(title: 'Gelir (₺)', value: revenue.toString()),
                ],
              ),
              const SizedBox(height: 24),
              Text('Popüler Hizmetler', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...popular.map((item) => ListTile(
                    title: Text(item['name'] as String? ?? '-'),
                    trailing: Text('x${item['usage_count']}'),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Panel yüklenemedi: $error')),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
