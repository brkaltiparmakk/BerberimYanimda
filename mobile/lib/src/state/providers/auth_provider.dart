import 'dart:convert';
import 'dart:io';

import 'package:berber_yanimda/src/core/services/notification_service.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:berber_yanimda/src/data/repositories/fcm_token_repository.dart';
import 'package:berber_yanimda/src/state/providers/repositories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  const AuthState({
    this.isInitialized = false,
    this.isLoggedIn = false,
    this.isBusy = false,
    this.profile,
    this.userName = 'Misafir',
    this.errorMessage,
  });

  final bool isInitialized;
  final bool isLoggedIn;
  final bool isBusy;
  final UserProfile? profile;
  final String userName;
  final String? errorMessage;

  bool get isBarber {
    return profile?.role.toLowerCase() == 'barberowner' ||
        profile?.role.toLowerCase() == 'staff';
  }

  AuthState copyWith({
    bool? isInitialized,
    bool? isLoggedIn,
    bool? isBusy,
    UserProfile? profile,
    String? userName,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isBusy: isBusy ?? this.isBusy,
      profile: profile ?? this.profile,
      userName: userName ?? this.userName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);
  FcmTokenRepository get _fcmRepo => ref.read(fcmTokenRepositoryProvider);
  NotificationService get _notifService => ref.read(notificationServiceProvider);

  Future<void> initialize() async {
    if (state.isInitialized) return;
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await _notifService.initialize();
      _notifService.onTokenRefreshed = _onFcmTokenRefreshed;

      if (await _auth.hasSession()) {
        try {
          final user = await _profileRepo.me();
          state = state.copyWith(
            profile: user,
            isLoggedIn: true,
            userName: user.firstName.isEmpty ? user.fullName : user.firstName,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Session restore failed: $e');
          }
          await _auth.logout();
        }
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isBusy: false, isInitialized: true);
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final user = await _auth.login(phone, password);
      state = state.copyWith(
        isLoggedIn: true,
        profile: user,
        userName: user.firstName.isEmpty ? user.fullName : user.firstName,
      );
      await _registerFcmToken();
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> register(
    String fullName, String phone, String email, String password) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await _auth.register(fullName, phone, email, password);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> verifyOtp(String phone, String code, {String? password}) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await _auth.verifyOtp(phone, code);
      if (password != null && password.isNotEmpty) {
        final user = await _auth.login(phone, password);
        state = state.copyWith(
          isLoggedIn: true,
          profile: user,
          userName: user.firstName.isEmpty ? user.fullName : user.firstName,
        );
      }
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> logout() async {
    await _unregisterFcmToken();
    try {
      final rt = await _auth.getRefreshToken();
      if (rt != null && rt.isNotEmpty) {
        await _auth.logoutFromServer(rt);
      }
    } catch (_) {}
    await _auth.logout();
    state = const AuthState();
  }

  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  void setProfile(UserProfile profile) {
    state = state.copyWith(
      profile: profile,
      userName: profile.firstName.isEmpty ? profile.fullName : profile.firstName,
    );
  }

  Future<bool> updateProfile({required String fullName, String? email}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _profileRepo.update(fullName: fullName, email: email);
      setProfile(updated);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> uploadProfileImage(String filePath) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _profileRepo.uploadProfileImage(filePath);
      setProfile(updated);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> changePassword(String current, String newPass) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _profileRepo.changePassword(current, newPass);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _profileRepo.deleteAccount(password);
      await _auth.logout();
      state = const AuthState();
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> exportUserData() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final data = await _profileRepo.exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempDir = Directory.systemTemp;
      final fileName = 'berber_yanimda_verilerim_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BerberYanimda - Verilerim',
        text: 'Kullanici verileriniz JSON formatinda ekte sunulmustur.',
      );
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$runtimeType error: $error\n$stackTrace');
      }
      state = state.copyWith(errorMessage: error.toString());
      return false;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> _registerFcmToken() async {
    final token = _notifService.fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _fcmRepo.registerToken(token, platform);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token register failed: $e');
      }
    }
  }

  Future<void> _unregisterFcmToken() async {
    final token = _notifService.fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await _fcmRepo.unregisterToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token unregister failed: $e');
      }
    }
    await _notifService.deleteToken();
  }

  void _onFcmTokenRefreshed(String? token) {
    if (token == null || token.isEmpty || !state.isLoggedIn) return;
    _registerFcmToken();
  }
}
