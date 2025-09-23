import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/molecules/empty_state.dart';
import '../../state/providers.dart';

class CustomerHistoryPage extends ConsumerStatefulWidget {
  const CustomerHistoryPage({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends ConsumerState<CustomerHistoryPage> {
  List<Map<String, dynamic>> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('appointments')
        .select<List<Map<String, dynamic>>>(
          'id, scheduled_at, total_amount, status, services',
        )
        .eq('customer_id', widget.customerId)
        .order('scheduled_at', ascending: false);
    if (!mounted) {
      return;
    }
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_history.isEmpty) {
      return const Scaffold(body: EmptyState(icon: Icons.history, message: 'Müşteri için kayıt bulunamadı.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Geçmişi')),
      body: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final appointment = _history[index];
          final date = DateFormat.yMMMMEEEEd('tr_TR').add_Hm().format(DateTime.parse(appointment['scheduled_at'] as String).toLocal());
          final total = (appointment['total_amount'] as num).toStringAsFixed(0);
          return ListTile(
            title: Text(date),
            subtitle: Text('Durum: ${appointment['status']}'),
            trailing: Text('$total ₺'),
          );
        },
      ),
    );
  }
}
