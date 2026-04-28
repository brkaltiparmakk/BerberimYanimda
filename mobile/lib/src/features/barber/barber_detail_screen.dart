import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/features/main/widgets/inline_error.dart';
import 'package:berber_yanimda/src/features/main/widgets/review_section.dart';
import 'package:berber_yanimda/src/features/main/widgets/round_icon.dart';
import 'package:berber_yanimda/src/features/main/widgets/state_message.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_buttons.dart';
import 'package:berber_yanimda/src/widgets/cards.dart';
import 'package:berber_yanimda/src/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BarberDetailScreen extends ConsumerStatefulWidget {
  const BarberDetailScreen({super.key, required this.barberId});

  final String barberId;

  @override
  ConsumerState<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends ConsumerState<BarberDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogProvider.notifier).loadBarberDetail(widget.barberId);
      ref.read(reviewProvider.notifier).loadReviews(widget.barberId);
      ref.read(reviewProvider.notifier).loadSummary(widget.barberId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final barber =
        _findBarber(catalog.barbers, widget.barberId) ?? catalog.selectedBarber;
    if (barber == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Berber Detay'),
          leading: IconButton(
            tooltip: 'Geri',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/barbers');
              }
            },
          ),
        ),
        body: StateMessage(
          message: catalog.errorMessage ?? 'Berber bulunamadı.',
          loading: catalog.isBusy,
          onRetry: () =>
              ref.read(catalogProvider.notifier).loadBarberDetail(widget.barberId),
        ),
      );
    }

    final booking = ref.watch(bookingProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    AppNetworkImage(
                      url: barber.imageUrl,
                      height: 260,
                      width: double.infinity,
                      borderRadius: 0,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: RoundIcon(
                        icon: Icons.arrow_back,
                        tooltip: 'Geri',
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/barbers');
                          }
                        },
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: RoundIcon(
                        icon: barber.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        tooltip: 'Favori',
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(barber.id),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (catalog.isBusy)
                        const LinearProgressIndicator(minHeight: 2),
                      if (catalog.errorMessage != null) ...[
                        InlineError(
                          message: catalog.errorMessage!,
                          onRetry: () => ref
                              .read(catalogProvider.notifier)
                              .loadBarberDetail(widget.barberId),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(barber.name, style: AppTextStyles.largeTitle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingView(
                            rating: barber.rating,
                            reviewCount: barber.reviewCount,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '${barber.distanceKm} km',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${barber.district}, ${barber.city}',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        barber.description.isEmpty
                            ? barber.address
                            : barber.description,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Yol Tarifi',
                              icon: Icons.navigation_outlined,
                              onPressed: () => _launchMapDirections(
                                barber.address,
                                lat: barber.latitude,
                                lng: barber.longitude,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SecondaryButton(
                              text: 'Ara',
                              icon: Icons.phone_outlined,
                              onPressed: () => _launchPhoneCall(barber.phoneNumber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SecondaryButton(
                              text: 'Paylaş',
                              icon: Icons.share_outlined,
                              onPressed: () => _shareBarberInfo(barber),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'Hizmetler'),
                      const SizedBox(height: 8),
                      if (barber.services.isEmpty)
                        const Text(
                          'Hizmet bilgisi yüklenmedi.',
                          style: AppTextStyles.caption,
                        )
                      else
                        for (final service in barber.services)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ServiceCard(
                              service: service,
                              selected: booking.selectedServiceIds.contains(service.id),
                              onTap: () {
                                ref.read(bookingProvider.notifier).toggleService(service.id);
                                context.push('/booking/services');
                              },
                            ),
                          ),
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'Çalışanlar'),
                      const SizedBox(height: 8),
                      if (barber.staff.isEmpty)
                        const Text(
                          'Personel bilgisi yüklenmedi.',
                          style: AppTextStyles.caption,
                        )
                      else
                        for (final staff in barber.staff)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: StaffCard(
                              staff: staff,
                              selected: booking.selectedStaff?.id == staff.id,
                              onTap: () {
                                ref.read(bookingProvider.notifier).selectStaff(staff);
                                context.push('/booking/staff');
                              },
                            ),
                          ),
                      const SizedBox(height: 22),
                      ReviewSection(barberId: widget.barberId),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: PrimaryButton(
                text: 'Randevu Al',
                onPressed: barber.services.isEmpty && catalog.isBusy
                    ? null
                    : () {
                        ref.read(bookingProvider.notifier).selectBarber(barber);
                        context.push('/booking/services');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Barber? _findBarber(List<Barber> barbers, String id) {
  for (final barber in barbers) {
    if (barber.id == id) return barber;
  }
  return null;
}

Future<void> _launchPhoneCall(String? phoneNumber) async {
  if (phoneNumber == null || phoneNumber.isEmpty) return;
  final cleaned = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _launchMapDirections(String? address, {double? lat, double? lng}) async {
  Uri uri;
  if (lat != null && lng != null) {
    uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  } else if (address != null && address.isNotEmpty) {
    final encoded = Uri.encodeComponent(address.trim());
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  } else {
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _shareBarberInfo(Barber barber) async {
  final text = '''${barber.name}
${barber.district}, ${barber.city}
${barber.address.isNotEmpty ? '\nAdres: ${barber.address}\n' : ''}Puan: ${barber.rating.toStringAsFixed(1)} / ${barber.reviewCount} değerlendirme
Berber Yanımda uygulaması ile keşfet!''';

  await Share.share(
    text,
    subject: barber.name,
  );
}
