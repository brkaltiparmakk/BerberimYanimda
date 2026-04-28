import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/data/repositories/coupon_repository.dart';
import 'package:berber_yanimda/src/data/repositories/support_repository.dart';
import 'package:berber_yanimda/src/state/providers/auth_provider.dart';
import 'package:berber_yanimda/src/state/providers/catalog_provider.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Favorites ────────────────────────────────────────────────────────────────

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

class FavoritesState {
  const FavoritesState({this.favorites = const [], this.isBusy = false, this.errorMessage});
  final List<Barber> favorites;
  final bool isBusy;
  final String? errorMessage;

  FavoritesState copyWith({
    List<Barber>? favorites, bool? isBusy, String? errorMessage, bool clearError = false,
  }) => FavoritesState(
    favorites: favorites ?? this.favorites,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => const FavoritesState();

  FavoriteRepository get _repo => ref.read(favoriteRepositoryProvider);
  bool get _isLoggedIn => ref.read(authProvider).isLoggedIn;

  Future<void> loadFavorites() async {
    if (!_isLoggedIn) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final favorites = await _repo.getFavorites();
      state = state.copyWith(favorites: favorites);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> toggleFavorite(String barberId) async {
    if (!_isLoggedIn) {
      state = state.copyWith(errorMessage: 'Favori eklemek icin giris yapmalisiniz.');
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final isFavorite = state.favorites.any((b) => b.id == barberId);
      if (isFavorite) {
        await _repo.remove(barberId);
      } else {
        await _repo.add(barberId);
      }
      await loadFavorites();
      ref.read(catalogProvider.notifier).syncFavorite(barberId, !isFavorite);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}

// ─── Notifications ────────────────────────────────────────────────────────────

final notificationProvider = NotifierProvider<NotifNotifier, NotifState>(
  NotifNotifier.new,
);

class NotifState {
  const NotifState({this.notifications = const [], this.isBusy = false, this.errorMessage});
  final List<AppNotification> notifications;
  final bool isBusy;
  final String? errorMessage;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotifState copyWith({
    List<AppNotification>? notifications, bool? isBusy, String? errorMessage, bool clearError = false,
  }) => NotifState(
    notifications: notifications ?? this.notifications,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class NotifNotifier extends Notifier<NotifState> {
  @override
  NotifState build() => const NotifState();

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);
  bool get _isLoggedIn => ref.read(authProvider).isLoggedIn;

  Future<void> loadNotifications() async {
    if (!_isLoggedIn) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final notifications = await _repo.getMine();
      state = state.copyWith(notifications: notifications);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> markRead(String id) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.markRead(id);
      await loadNotifications();
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> markAllRead() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.markAllRead();
      await loadNotifications();
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}

// ─── Reviews ──────────────────────────────────────────────────────────────────

final reviewProvider = NotifierProvider<ReviewNotifier, ReviewState>(
  ReviewNotifier.new,
);

class ReviewState {
  const ReviewState({this.reviews = const [], this.summary, this.isBusy = false, this.errorMessage});
  final List<Review> reviews;
  final ReviewSummary? summary;
  final bool isBusy;
  final String? errorMessage;

  ReviewState copyWith({
    List<Review>? reviews, ReviewSummary? summary, bool? isBusy, String? errorMessage, bool clearError = false,
  }) => ReviewState(
    reviews: reviews ?? this.reviews,
    summary: summary ?? this.summary,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class ReviewNotifier extends Notifier<ReviewState> {
  @override
  ReviewState build() => const ReviewState();

  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  Future<bool> createReview({required String appointmentId, required int rating, String? comment}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.create(appointmentId: appointmentId, rating: rating, comment: comment);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> loadReviews(String barberShopId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      state = state.copyWith(reviews: await _repo.getByBarberShop(barberShopId));
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> loadSummary(String barberShopId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      state = state.copyWith(summary: await _repo.getSummary(barberShopId));
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}

// ─── Coupon ───────────────────────────────────────────────────────────────────

final couponProvider = NotifierProvider<CouponNotifier, CouponState>(
  CouponNotifier.new,
);

class CouponState {
  const CouponState({this.code, this.result, this.isBusy = false, this.errorMessage});
  final String? code;
  final CouponValidationResult? result;
  final bool isBusy;
  final String? errorMessage;

  CouponState copyWith({
    String? code, CouponValidationResult? result, bool? isBusy, String? errorMessage, bool clearError = false, bool clearCode = false,
  }) => CouponState(
    code: clearCode ? null : (code ?? this.code),
    result: result ?? this.result,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class CouponNotifier extends Notifier<CouponState> {
  @override
  CouponState build() => const CouponState();

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  Future<bool> validate(String code, int orderAmount) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.validate(code: code, orderAmount: orderAmount);
      if (result.isValid) {
        state = state.copyWith(result: result, code: code);
      } else {
        state = state.copyWith(result: result);
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void clear() => state = const CouponState();
}

// ─── Support ──────────────────────────────────────────────────────────────────

final supportProvider = NotifierProvider<SupportNotifier, SupportState>(
  SupportNotifier.new,
);

class SupportState {
  const SupportState({this.isBusy = false, this.errorMessage});
  final bool isBusy;
  final String? errorMessage;

  SupportState copyWith({bool? isBusy, String? errorMessage, bool clearError = false}) => SupportState(
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class SupportNotifier extends Notifier<SupportState> {
  @override
  SupportState build() => const SupportState();

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  Future<bool> createTicket(String subject, String description) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.create(subject, description);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $e\n$s');
      }
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
