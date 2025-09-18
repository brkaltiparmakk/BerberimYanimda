import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  NotificationsService(this._client);

  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localPlugin.initialize(initSettings);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Bildirim izni verilmedi');
      return;
    }

    final token = await messaging.getToken();
    if (token != null && _client.auth.currentUser != null) {
      await _client.from('profiles').update({'fcm_token': token}).eq('id', _client.auth.currentUser!.id);
    }

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails('appointments', 'Randevu Bildirimleri'),
          ),
        );
      }
    });
  }
}
