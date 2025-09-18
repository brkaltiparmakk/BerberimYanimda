import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
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
    setState(() => _businessId = profile?['default_business_id'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.analytics, message: 'İşletme bulunamadı.'));
    }

    final metricsAsync = ref.watch(businessDashboardProvider(_businessId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: metricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return const EmptyState(icon: Icons.analytics, message: 'Veri bulunamadı.');
          }
          final revenue = (metrics['total_revenue'] as num? ?? 0).toDouble();
          final completed = metrics['completed_count'] as int? ?? 0;
          final upcoming = metrics['upcoming_count'] as int? ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gelir Dağılımı'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: (revenue / 1000).clamp(0, 1).toDouble()),
                      const SizedBox(height: 8),
                      Text('Toplam: ${revenue.toStringAsFixed(0)} ₺'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Randevu Durumu'),
                      const SizedBox(height: 12),
                      Text('Tamamlanan: $completed'),
                      Text('Yaklaşan: $upcoming'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Raporlar yüklenemedi: $error')),
      ),
    );
  }
}
