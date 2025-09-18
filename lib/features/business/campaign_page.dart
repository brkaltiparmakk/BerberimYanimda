import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/promotion.dart';
import '../../state/providers.dart';
import '../../widgets/molecules/empty_state.dart';

class CampaignPage extends ConsumerStatefulWidget {
  const CampaignPage({super.key});

  @override
  ConsumerState<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends ConsumerState<CampaignPage> {
  List<Promotion> _promotions = const [];
  bool _loading = true;
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
    final businessId = profile?['default_business_id'] as String?;
    if (businessId == null) {
      setState(() => _loading = false);
      return;
    }
    final promotions = await ref.read(supabaseClientProvider).from('promotions').select<List<Map<String, dynamic>>>()
      ..eq('business_id', businessId)
      ..order('created_at', ascending: false);
    setState(() {
      _businessId = businessId;
      _promotions = promotions
          .map(
            (json) => Promotion(
              id: json['id'] as String,
              businessId: json['business_id'] as String,
              title: json['title'] as String,
              discountRate: (json['discount_rate'] as num).toDouble(),
              startDate: DateTime.parse(json['start_date'] as String),
              endDate: DateTime.parse(json['end_date'] as String),
              active: json['active'] as bool? ?? true,
              description: json['description'] as String?,
            ),
          )
          .toList();
      _loading = false;
    });
  }

  Future<void> _savePromotion({Promotion? promotion}) async {
    final titleCtrl = TextEditingController(text: promotion?.title ?? '');
    final discountCtrl = TextEditingController(text: promotion?.discountRate.toString() ?? '');
    DateTimeRange range = DateTimeRange(
      start: promotion?.startDate ?? DateTime.now(),
      end: promotion?.endDate ?? DateTime.now().add(const Duration(days: 7)),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(promotion == null ? 'Kampanya Oluştur' : 'Kampanya Düzenle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
              const SizedBox(height: 12),
              TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'İndirim Oranı (%)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Geçerlilik: ${range.start.day}.${range.start.month} - ${range.end.day}.${range.end.month}'),
                trailing: const Icon(Icons.date_range),
                onTap: () async {
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: range,
                  );
                  if (result != null) {
                    setState(() => range = result);
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final client = ref.read(supabaseClientProvider);
                  if (promotion == null) {
                    await client.from('promotions').insert({
                      'business_id': _businessId,
                      'title': titleCtrl.text,
                      'discount_rate': double.tryParse(discountCtrl.text) ?? 0,
                      'start_date': range.start.toIso8601String(),
                      'end_date': range.end.toIso8601String(),
                      'active': true,
                    });
                  } else {
                    await client.from('promotions').update({
                      'title': titleCtrl.text,
                      'discount_rate': double.tryParse(discountCtrl.text) ?? promotion.discountRate,
                      'start_date': range.start.toIso8601String(),
                      'end_date': range.end.toIso8601String(),
                    }).eq('id', promotion.id);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    _load();
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_businessId == null) {
      return const Scaffold(body: EmptyState(icon: Icons.campaign, message: 'İşletme bulunamadı.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kampanyalarım'), actions: [
        IconButton(onPressed: () => _savePromotion(), icon: const Icon(Icons.add)),
      ]),
      body: _promotions.isEmpty
          ? const EmptyState(icon: Icons.campaign, message: 'Kampanya bulunamadı.')
          : ListView.builder(
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promo = _promotions[index];
                return SwitchListTile(
                  title: Text(promo.title),
                  subtitle: Text('${promo.discountRate.toStringAsFixed(0)}% • ${promo.startDate.day}.${promo.startDate.month} - ${promo.endDate.day}.${promo.endDate.month}'),
                  value: promo.active,
                  onChanged: (value) async {
                    await ref.read(supabaseClientProvider).from('promotions').update({'active': value}).eq('id', promo.id);
                    _load();
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _savePromotion(promotion: promo),
                  ),
                );
              },
            ),
    );
  }
}
