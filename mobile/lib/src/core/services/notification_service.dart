import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global background message handler (must be top-level or static)
/// TODO: Implement local notification display for background messages.
/// Currently only logs to console — the user sees no visual alert for
/// messages received while the app is in the background/terminated.
/// Plan: Use flutter_local_notifications from a separate isolate-friendly
/// initialization path, or rely on FCM's auto-display on Android.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: id=${message.messageId}'
      ', type=${message.data['type']}, title=${message.notification?.title}');
}

class NotificationService {
  NotificationService();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  Function(String? token)? onTokenRefreshed;
  Function(Map<String, dynamic> payload)? onNotificationTapped;

  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    // Web platformunda FCM desteklenmez — graceful degradation
    if (kIsWeb) {
      debugPrint('NotificationService: Web platformu — push bildirimler devre dışı');
      _initialized = true;
      return true;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission (iOS & Android 13+)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground messages -> local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Message opened app (tapped)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Token refresh
      _messaging!.onTokenRefresh.listen((token) {
        _fcmToken = token;
        onTokenRefreshed?.call(token);
      });

      // Initialize local notifications
      await _initLocalNotifications();

      // Get initial token
      _fcmToken = await _messaging!.getToken();
      debugPrint('FCM token: $_fcmToken');

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
      // Graceful degradation: app works without push
      return false;
    }
  }

  String? get fcmToken => _fcmToken;

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTapped?.call(payload);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Notification payload decode failed: $e');
            }
            onNotificationTapped?.call({'payload': response.payload});
          }
        }
      },
    );

    // Android notification channel for foreground messages
    if (!kIsWeb) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Bildirimler',
        description: 'Randevu ve sistem bildirimleri',
        importance: Importance.high,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    if (notification == null) return;

    _showLocalNotification(
      id: message.hashCode,
      title: notification.title ?? 'BerberYanimda',
      body: notification.body ?? '',
      payload: data,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    onNotificationTapped?.call(message.data);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Bildirimler',
      channelDescription: 'Randevu ve sistem bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  Future<void> deleteToken() async {
    if (kIsWeb || _messaging == null) return;
    try {
      await _messaging!.deleteToken();
      _fcmToken = null;
    } catch (e) {
      debugPrint('FCM deleteToken failed: $e');
    }
  }
}
