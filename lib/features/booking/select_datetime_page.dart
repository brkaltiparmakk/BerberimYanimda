import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';

class SelectDateTimePage extends ConsumerStatefulWidget {
  const SelectDateTimePage({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<SelectDateTimePage> createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends ConsumerState<SelectDateTimePage> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(availabilityProvider(AvailabilityParams(businessId: widget.businessId, date: _selectedDate)));
    final locale = DateFormat.yMMMMEEEEd('tr_TR');

    return Scaffold(
      appBar: AppBar(title: const Text('Tarih & Saat Seçin')),
      body: Column(
        children: [
          CalendarDatePicker(
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            initialDate: _selectedDate,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Müsait Saatler', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(child: Text('Seçilen gün için uygunluk bulunamadı.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = _selectedSlot == slot;
                    final formatted = DateFormat.Hm('tr_TR').format(slot);
                    return ChoiceChip(
                      label: Text(formatted),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Uygunluk getirilemedi: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          onPressed: _selectedSlot == null
              ? null
              : () {
                  ref.read(bookingProvider.notifier).selectDateTime(_selectedSlot!);
                  context.go('/booking/confirm');
                },
          label: _selectedSlot == null ? 'Saat Seçiniz' : '${locale.format(_selectedSlot!)}',
        ),
      ),
    );
  }
}
