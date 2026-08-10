import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_notifier.dart';
import '../../shared/models/supabase_models.dart';
import '../router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background handler — HARUS top-level function dengan `@pragma('vm:entry-point')`.
/// Dipanggil oleh sistem saat app di background/terminated dan FCM masuk.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Sistem otomatis menampilkan notifikasi (notification payload).
  // Tidak perlu lakukan apa-apa di sini untuk skenario standar.
}

/// FCM service — menangani init Firebase, token register, foreground/background/tap.
/// Mengikuti technical-spec.md §5.
///
/// Graceful degradation: jika `Firebase.initializeApp()` gagal (mis. tidak ada
/// `google-services.json`), service no-op dan app tetap jalan tanpa push.
class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'mng_group_broadcast',
    'MNG Group Notifications',
    description: 'Notifikasi operasional dan pengumuman resmi MNG Group',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Apakah Firebase boleh di-init.
  static const bool _firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: true,
  );

  /// Inisialisasi Firebase + FCM. Idempotent; aman dipanggil berulang kali.
  Future<void> init() async {
    if (_initialized) return;

    if (!_firebaseEnabled) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Firebase.initializeApp gagal: $e');
      return;
    }

    _initialized = true;

    // Background handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notifications setup (untuk foreground).
    await _initLocalNotifications();

    // Permission (iOS + Android 13+).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // Subscribe to squad broadcast topics for easy broadcast from Firebase/Supabase
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_members');
      await FirebaseMessaging.instance.subscribeToTopic('schedules');
      await FirebaseMessaging.instance.subscribeToTopic('announcements');
      debugPrint('[FCM] Subscribed to all_members, schedules, announcements topics');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic error: $e');
    }

    // Listener: pesan datang saat app foreground.
    FirebaseMessaging.onMessage.listen(_onForeground);

    // Listener: user tap notifikasi saat app background.
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    // Cek apakah app dibuka via tap notif saat sebelumnya terminated.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial);

    // Dengarkan auth state untuk auto-register/clear token.
    _ref.listen<AsyncValue<SquadMember?>>(
      authNotifierProvider,
      (prev, next) {
        final prevId = switch (prev) {
          AsyncData<SquadMember?>(:final value) => value?.id,
          _ => null,
        };
        final nextId = switch (next) {
          AsyncData<SquadMember?>(:final value) => value?.id,
          _ => null,
        };
        if (prevId == nextId) return;
        if (nextId != null) {
          // ignore: unawaited_futures
          _registerToken();
        }
      },
      fireImmediately: true,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // ignore: unawaited_futures
      _sendTokenToBackend(newToken);
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        _ref.read(routerProvider).go('/schedules');
      },
    );

    // Buat channel di Android (no-op di iOS).
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[FCM] Cannot save token: user not authenticated');
        return;
      }

      final platformStr = defaultTargetPlatform == TargetPlatform.android
          ? 'android'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown');
      final deviceInfo = {
        'sdk': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 1. Try secure RPC function
      try {
        await client.rpc('save_fcm_token', params: {
          'p_token': token,
          'p_platform': platformStr,
          'p_device_info': deviceInfo,
        });
        debugPrint('[FCM] token registered to Supabase via RPC');
        return;
      } catch (rpcError) {
        debugPrint('[FCM] RPC save failed: $rpcError, falling back to direct table upsert...');
      }

      // 2. Fallback to direct table upsert
      await client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platformStr,
        'device_info': deviceInfo,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      debugPrint('[FCM] token registered to Supabase via table upsert');
    } catch (e) {
      debugPrint('[FCM] token register failed: $e');
    }
  }

  /// Foreground: tampilkan notifikasi jadwal match atau pengumuman squad
  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _localNotif.show(
      id: message.hashCode,
      title: n.title ?? 'MNG GROUP',
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _onTap(RemoteMessage message) {
    try {
      _ref.read(routerProvider).go('/schedules');
    } catch (_) {}
  }
}

/// Singleton service. Dipanggil eager dari `MangansageApp.build`.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(ref);
  // Kick off init secara async — tidak block UI.
  // ignore: unawaited_futures
  service.init();
  return service;
});
