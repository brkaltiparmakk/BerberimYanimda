import 'package:berberim_yanimda/state/availability_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateOccupiedSlots', () {
    test('returns at least one slot for durations shorter than 30 minutes', () {
      final start = DateTime(2024, 1, 1, 10, 0);

      final slots = generateOccupiedSlots(start, const Duration(minutes: 15));

      expect(slots, [start]);
    });

    test('rounds up durations to the next 30-minute block', () {
      final start = DateTime(2024, 1, 1, 10, 0);

      final slots = generateOccupiedSlots(start, const Duration(minutes: 45));

      expect(slots, [
        start,
        start.add(const Duration(minutes: 30)),
      ]);
    });
  });
}
