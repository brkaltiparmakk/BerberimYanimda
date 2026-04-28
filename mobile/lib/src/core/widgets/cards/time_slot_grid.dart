import 'package:berber_yanimda/src/core/theme/app_colors.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:flutter/material.dart';

class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final slot in slots)
          ChoiceChip(
            label: Text(slot.startTime),
            selected: selectedSlot?.startTime == slot.startTime,
            onSelected: slot.isAvailable
                ? (_) => onSlotSelected(slot)
                : null,
            selectedColor: AppColors.primaryGold,
            disabledColor: AppColors.backgroundSecondary,
            backgroundColor: AppColors.cardBackground,
            labelStyle: TextStyle(
              color: !slot.isAvailable
                  ? AppColors.textMuted
                  : selectedSlot?.startTime == slot.startTime
                      ? AppColors.backgroundPrimary
                      : AppColors.textPrimary,
            ),
            side: BorderSide(
              color: slot.isAvailable
                  ? AppColors.borderColor
                  : AppColors.backgroundSecondary,
            ),
          ),
      ],
    );
  }
}
