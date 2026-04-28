import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catalogProvider = NotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);

class CatalogState {
  const CatalogState({
    this.barbers = const [],
    this.selectedBarber,
    this.isBusy = false,
    this.errorMessage,
  });

  final List<Barber> barbers;
  final Barber? selectedBarber;
  final bool isBusy;
  final String? errorMessage;

  CatalogState copyWith({
    List<Barber>? barbers,
    Barber? selectedBarber,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      barbers: barbers ?? this.barbers,
      selectedBarber: selectedBarber ?? this.selectedBarber,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Barber? findById(String id) {
    for (final barber in barbers) {
      if (barber.id == id) return barber;
    }
    return null;
  }
}

class CatalogNotifier extends Notifier<CatalogState> {
  @override
  CatalogState build() => const CatalogState();

  CatalogRepository get _catalog => ref.read(catalogRepositoryProvider);

  Future<void> loadBarbers() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final barbers = await _catalog.getBarbers();
      var selectedBarber = state.selectedBarber;
      selectedBarber = selectedBarber != null
          ? barbers.firstWhere(
              (b) => b.id == selectedBarber!.id,
              orElse: () => barbers.first,
            )
          : barbers.isNotEmpty
              ? barbers.first
              : null;
      state = state.copyWith(barbers: barbers, selectedBarber: selectedBarber);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> loadBarberDetail(String id) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await _catalog.getBarber(id);
      _upsertBarber(detail);
      state = state.copyWith(selectedBarber: detail);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void selectBarber(Barber barber) {
    state = state.copyWith(selectedBarber: barber);
  }

  void syncFavorite(String barberId, bool isFavorite) {
    final updated = state.barbers.map((b) {
      if (b.id == barberId) return b.copyWith(isFavorite: isFavorite);
      return b;
    }).toList();
    var selected = state.selectedBarber;
    if (selected?.id == barberId) {
      selected = selected!.copyWith(isFavorite: isFavorite);
    }
    state = state.copyWith(barbers: updated, selectedBarber: selected);
  }

  void _upsertBarber(Barber barber) {
    final exists = state.barbers.any((b) => b.id == barber.id);
    final updated = exists
        ? state.barbers
            .map((b) => b.id == barber.id
                ? barber.copyWith(
                    isFavorite: b.isFavorite || barber.isFavorite)
                : b)
            .toList()
        : [barber, ...state.barbers];
    state = state.copyWith(barbers: updated);
  }
}
