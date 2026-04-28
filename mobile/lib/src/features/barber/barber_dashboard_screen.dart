import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  ConsumerState<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends ConsumerState<BarberDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barberOwnerProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(barberOwnerProvider);
    final auth = ref.watch(authProvider);
    final pendingCount = owner.pendingCount;
    final todayCount = owner.todayCount;
    final totalCount = owner.appointments.length;

    return AppScaffold(
      currentIndex: 0,
      title: 'Berber Paneli',
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(barberOwnerProvider.notifier).loadAll();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Merhaba, ${auth.userName}',
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.pending_actions,
                    label: 'Bekleyen Onay',
                    value: pendingCount.toString(),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.today,
                    label: 'Bugünkü Randevular',
                    value: todayCount.toString(),
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.calendar_month,
                    label: 'Toplam Randevu',
                    value: totalCount.toString(),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.attach_money,
                    label: 'Bugünkü Kazanç',
                    value: _calculateTodayRevenue(owner.appointments),
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Dükkan Yönetimi', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ManagementCard(
                    icon: Icons.access_time,
                    label: 'Çalışma Saatleri',
                    onTap: () => context.go('/barber/working-hours'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ManagementCard(
                    icon: Icons.content_cut,
                    label: 'Hizmetler',
                    onTap: () => context.go('/barber/services'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ManagementCard(
                    icon: Icons.people,
                    label: 'Personel',
                    onTap: () => context.go('/barber/staff'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bugünkü Randevular', style: AppTextStyles.sectionTitle),
                TextButton(
                  onPressed: () => context.go('/barber/appointments'),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TodayAppointmentsList(appointments: owner.appointments),
          ],
        ),
      ),
    );
  }

  String _calculateTodayRevenue(List<Appointment> appointments) {
    final now = DateTime.now();
    final todayAppointments = appointments.where((a) {
      return a.dateTime.year == now.year &&
          a.dateTime.month == now.month &&
          a.dateTime.day == now.day &&
          (a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.completed);
    });
    final total = todayAppointments.fold(0, (sum, a) => sum + a.totalPrice);
    return '₺$total';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _TodayAppointmentsList extends StatelessWidget {
  const _TodayAppointmentsList({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayAppointments = appointments
        .where((a) =>
            a.dateTime.year == now.year &&
            a.dateTime.month == now.month &&
            a.dateTime.day == now.day)
        .toList();

    if (todayAppointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Bugün için randevu bulunmuyor.'),
        ),
      );
    }

    return Column(
      children: todayAppointments.map((a) {
        return Card(
          color: AppColors.cardBackground,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _StatusBadge(status: a.status),
            title: Text(a.customerName ?? 'Müşteri', style: AppTextStyles.body),
            subtitle: Text(
              '${a.dateTime.hour.toString().padLeft(2, '0')}:${a.dateTime.minute.toString().padLeft(2, '0')} - ${a.services.join(', ')}',
              style: AppTextStyles.caption,
            ),
            trailing: Text('₺${a.totalPrice}', style: AppTextStyles.body),
          ),
        );
      }).toList(),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AppointmentStatus.pending => (AppColors.warning, 'Bekliyor'),
      AppointmentStatus.confirmed => (AppColors.info, 'Onaylı'),
      AppointmentStatus.completed => (AppColors.success, 'Tamamlandı'),
      AppointmentStatus.cancelled => (AppColors.textMuted, 'İptal'),
      AppointmentStatus.rejected => (AppColors.error, 'Reddedildi'),
      _ => (AppColors.textMuted, 'Bilinmiyor'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
