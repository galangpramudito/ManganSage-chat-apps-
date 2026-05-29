import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_notifier.dart';
import '../../features/messages/providers/active_conversation_provider.dart';
import '../../shared/models/user.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';

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
    'chat_messages',
    'Pesan Chat',
    description: 'Notifikasi pesan masuk dari pengguna lain',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Apakah Firebase boleh di-init. Default `false` untuk menghindari noise
  /// stacktrace di Android logcat saat `google-services.json` belum di-set up.
  /// Aktifkan lewat `--dart-define=FIREBASE_ENABLED=true` setelah Firebase config
  /// terpasang. Lihat README "Setup Firebase" untuk langkahnya.
  static const bool _firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  /// Inisialisasi Firebase + FCM. Idempotent; aman dipanggil berulang kali.
  Future<void> init() async {
    if (_initialized) return;

    if (!_firebaseEnabled) {
      debugPrint(
        '[FCM] dimatikan — pakai --dart-define=FIREBASE_ENABLED=true setelah '
        'google-services.json terpasang.',
      );
      return;
    }

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

    // Listener: pesan datang saat app foreground.
    FirebaseMessaging.onMessage.listen(_onForeground);

    // Listener: user tap notifikasi saat app background.
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    // Cek apakah app dibuka via tap notif saat sebelumnya terminated.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial);

    // Dengarkan auth state untuk auto-register/clear token.
    _ref.listen<AsyncValue<User?>>(
      authNotifierProvider,
      (prev, next) {
        final prevId = switch (prev) {
          AsyncData<User?>(:final value) => value?.id,
          _ => null,
        };
        final nextId = switch (next) {
          AsyncData<User?>(:final value) => value?.id,
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
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        // Ketuk lokal-notif (foreground) → buka chat.
        final convId = int.tryParse(resp.payload ?? '');
        if (convId != null) _navigateToChat(convId);
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
      await _ref.read(dioProvider).post(
        ApiConstants.fcmToken,
        data: {'fcm_token': token},
      );
      debugPrint('[FCM] token registered');
    } catch (e) {
      debugPrint('[FCM] token register failed: $e');
    }
  }

  /// Foreground: kalau user TIDAK sedang di chat tersebut, tampilkan banner.
  void _onForeground(RemoteMessage message) {
    final convIdStr = message.data['conversation_id']?.toString();
    final convId = int.tryParse(convIdStr ?? '');
    final activeId = _ref.read(activeConversationProvider);

    // Suppress kalau user sudah di conversation tersebut.
    if (convId != null && convId == activeId) return;

    final n = message.notification;
    if (n == null) return;

    _localNotif.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: convIdStr,
    );
  }

  void _onTap(RemoteMessage message) {
    final convId = int.tryParse(message.data['conversation_id']?.toString() ?? '');
    if (convId != null) _navigateToChat(convId);
  }

  void _navigateToChat(int convId) {
    try {
      _ref.read(routerProvider).push('/chat/$convId');
    } catch (e) {
      debugPrint('[FCM] navigate failed: $e');
    }
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
