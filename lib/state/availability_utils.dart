import 'dart:math' as math;

List<DateTime> generateOccupiedSlots(DateTime start, Duration duration) {
  final slots = math.max(1, (duration.inMinutes + 29) ~/ 30);
  return List<DateTime>.generate(
    slots,
    (index) => start.add(Duration(minutes: 30 * index)),
  );
}
