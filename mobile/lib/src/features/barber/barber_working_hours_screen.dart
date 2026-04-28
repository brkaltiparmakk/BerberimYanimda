import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/core/theme/app_text_styles.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:berber_yanimda/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BarberWorkingHoursScreen extends ConsumerStatefulWidget {
  const BarberWorkingHoursScreen({super.key});

  @override
  ConsumerState<BarberWorkingHoursScreen> createState() => _BarberWorkingHoursScreenState();
}

class _BarberWorkingHoursScreenState extends ConsumerState<BarberWorkingHoursScreen> {
  final List<String> _dayNames = const [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barberOwnerProvider.notifier).loadWorkingHours();
    });
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(barberOwnerProvider);
    final hours = owner.workingHours;

    return AppScaffold(
      currentIndex: 0,
      title: 'Çalışma Saatleri',
      actions: [
        IconButton(
          tooltip: 'Kaydet',
          icon: const Icon(Icons.save),
          onPressed: () => _save(context, owner),
        ),
      ],
      child: hours.isEmpty && owner.isBusy
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async { await ref.read(barberOwnerProvider.notifier).loadWorkingHours(); },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayOfWeek = index + 1;
                  final hour = hours.firstWhere(
                    (h) => h.dayOfWeek == dayOfWeek,
                    orElse: () => WorkingHour(
                      id: '',
                      dayOfWeek: dayOfWeek,
                      startTime: '09:00',
                      endTime: '20:00',
                      isClosed: false,
                    ),
                  );
                  return _WorkingHourTile(
                    dayName: _dayNames[index],
                    hour: hour,
                    onChanged: (updated) => _updateHour(dayOfWeek, updated),
                  );
                },
              ),
            ),
    );
  }

  void _updateHour(int dayOfWeek, WorkingHour updated) {
    ref.read(barberOwnerProvider.notifier).updateWorkingHourLocally(updated);
  }

  Future<void> _save(BuildContext context, BarberOwnerState state) async {
    final success = await ref.read(barberOwnerProvider.notifier).updateWorkingHours(state.workingHours);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kaydedildi.' : 'Hata: ${state.errorMessage}'),
        ),
      );
    }
  }
}

class _WorkingHourTile extends StatefulWidget {
  const _WorkingHourTile({
    required this.dayName,
    required this.hour,
    required this.onChanged,
  });

  final String dayName;
  final WorkingHour hour;
  final ValueChanged<WorkingHour> onChanged;

  @override
  State<_WorkingHourTile> createState() => _WorkingHourTileState();
}

class _WorkingHourTileState extends State<_WorkingHourTile> {
  late bool _isClosed;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _isClosed = widget.hour.isClosed;
    _start = _parseTime(widget.hour.startTime);
    _end = _parseTime(widget.hour.endTime);
  }

  @override
  void didUpdateWidget(covariant _WorkingHourTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isClosed = widget.hour.isClosed;
    _start = _parseTime(widget.hour.startTime);
    _end = _parseTime(widget.hour.endTime);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _notify() {
    widget.onChanged(WorkingHour(
      id: widget.hour.id,
      dayOfWeek: widget.hour.dayOfWeek,
      startTime: _formatTime(_start),
      endTime: _formatTime(_end),
      isClosed: _isClosed,
    ));
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.dayName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text('Kapalı', style: AppTextStyles.caption),
                    Switch(
                      value: _isClosed,
                      onChanged: (v) {
                        setState(() => _isClosed = v);
                        _notify();
                      },
                      activeTrackColor: AppColors.primaryGold,
                    ),
                  ],
                ),
              ],
            ),
            if (!_isClosed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('Açılış: ${_formatTime(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('Kapanış: ${_formatTime(_end)}'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
