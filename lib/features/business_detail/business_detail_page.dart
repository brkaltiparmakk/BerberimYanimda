import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/service.dart';
import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';
import '../../widgets/molecules/empty_state.dart';
import 'reviews_list.dart';
import 'services_list.dart';

class BusinessDetailPage extends ConsumerStatefulWidget {
  const BusinessDetailPage({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends ConsumerState<BusinessDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _business;
  List<ServiceModel> _services = const [];
  List<Map<String, dynamic>> _reviews = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final repo = ref.read(businessRepositoryProvider);
    final client = ref.read(supabaseClientProvider);

    try {
      final businessFuture = repo.getBusiness(widget.businessId);
      final servicesFuture = repo.fetchServices(widget.businessId);
      final reviewsFuture = client
          .from('reviews')
          .select<List<Map<String, dynamic>>>(
            'id, comment, rating, created_at, appointments(customer_id), customer_id, customer:profiles(full_name)',
          )
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: false)
          .limit(20);

      final business = await businessFuture;
      final services = await servicesFuture;
      final reviews = await reviewsFuture;

      if (!mounted) return;
      setState(() {
        _business = business == null
            ? null
            : {
                'id': business.id,
                'name': business.name,
                'description': business.description,
                'address': business.address,
                'cover_image_url': business.coverImageUrl,
                'open_hours': business.openHours,
                'average_rating': business.averageRating,
                'review_count': business.reviewCount,
              };
        _services = services;
        _reviews = reviews
            .map((item) => {
                  'id': item['id'],
                  'comment': item['comment'],
                  'rating': item['rating'],
                  'customer_name': (item['customer'] as Map?)?['full_name'] ?? 'Müşteri',
                })
            .toList();
        _loading = false;
      });
    } catch (error, _) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _business = null;
        _services = const [];
        _reviews = const [];
        _errorMessage = 'İşletme bilgileri yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  void _onSelectService(ServiceModel service) {
    ref.read(bookingProvider.notifier).selectBusiness(widget.businessId);
    ref.read(bookingProvider.notifier).toggleService(service.id);
    context.go('/booking/datetime/${widget.businessId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          message: _errorMessage!,
          action: PrimaryButton(
            onPressed: _load,
            label: 'Tekrar Dene',
            icon: Icons.refresh,
          ),
        ),
      );
    }

    if (_business == null) {
      return const Scaffold(body: EmptyState(icon: Icons.store_mall_directory, message: 'İşletme bulunamadı.'));
    }

    final openHours = (_business!['open_hours'] as Map<String, dynamic>? ?? {}).entries
        .map((entry) => '${entry.key}: ${(entry.value as List?)?.join(', ') ?? '-'}')
        .join('\n');

    return Scaffold(
      appBar: AppBar(title: Text(_business!['name'] as String)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_business!['cover_image_url'] != null)
              CachedNetworkImage(
                imageUrl: _business!['cover_image_url'] as String,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_business!['description'] as String? ?? '', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(openHours.isEmpty ? 'Çalışma saatleri yakında' : openHours)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_business!['address'] as String? ?? 'Adres eklenmemiş')),
                    ],
                  ),
                ],
              ),
            ),
            ServicesList(services: _services, onSelect: _onSelectService),
            ReviewsList(reviews: _reviews),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/booking/services/${widget.businessId}'),
        icon: const Icon(Icons.calendar_month),
        label: const Text('Randevu Al'),
      ),
    );
  }
}
