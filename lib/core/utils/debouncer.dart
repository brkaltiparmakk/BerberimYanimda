import 'dart:async';

/// Basit bir debounce yardımcı sınıfı.
///
/// Kullanıcı etkileşimlerinde (ör. arama alanı) gereksiz ağ
/// isteklerini azaltmak için kullanılır.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 350)});

  final Duration delay;
  Timer? _timer;

  /// [action] çağrısını [delay] süresince erteleyerek sadece
  /// son tetiklenen çağrının çalışmasını sağlar.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
