import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/auth/providers/auth_notifier.dart';
import '../../features/conversations/providers/conversations_notifier.dart';
import '../../features/messages/providers/messages_notifier.dart';
import '../../shared/models/message.dart';
import '../../shared/models/user.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Status koneksi WebSocket — dipakai UI untuk indikator "Menghubungkan ulang…".
enum RealtimeStatus { disconnected, connecting, connected, reconnecting, failed }

/// Service real-time chat — bicara langsung dengan Reverb pakai Pusher protocol
/// via [WebSocketChannel]. Tidak pakai `pusher_channels_flutter` karena package
/// itu tidak mengekspose `wsHost`/`wsPort` (limitasi untuk self-hosted Reverb).
///
/// Fitur:
/// - Auto reconnect dengan exponential backoff (1s..30s)
/// - Subscribe ke `private-user.{userId}` via Sanctum auth (`/api/broadcasting/auth`)
/// - Dispatch event `message.sent` → `messagesProvider` + `conversationsNotifierProvider`
/// - Dispatch event `message.read` → `messagesProvider.markOwnAsRead`
class RealtimeService {
  RealtimeService(this._ref);

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  String? _socketId;
  int? _userId;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  Future<void> connect(int userId) async {
    if (_userId == userId && _channel != null) return;
    await disconnect();

    if (!ApiConstants.reverbConfigured) {
      // Reverb belum dikonfigurasi (mis. belum di-deploy ke cloud).
      // Lewati silently — banner "Tidak tersambung" akan tampil di ChatRoom.
      debugPrint('[Realtime] dimatikan — REVERB_HOST/REVERB_APP_KEY kosong.');
      _setStatus(RealtimeStatus.disconnected);
      return;
    }

    _userId = userId;
    _reconnectAttempt = 0;
    _setStatus(RealtimeStatus.connecting);
    _open();
  }

  void _open() {
    if (_userId == null) return;

    final scheme = ApiConstants.reverbForceTLS ? 'wss' : 'ws';
    final uri = Uri.parse(
      '$scheme://${ApiConstants.reverbHost}:${ApiConstants.reverbPort}'
      '/app/${ApiConstants.reverbKey}'
      '?protocol=7&client=mangansage&version=1.0',
    );

    try {
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      _sub = ch.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[Realtime] connect exception: $e');
      _scheduleReconnect();
    }
  }

  // ─── Incoming frames ─────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = frame['event'] as String?;
    final channel = frame['channel'] as String?;
    final inner = _decodeData(frame['data']);

    if (event == null) return;

    if (event == 'pusher:connection_established') {
      _socketId = inner['socket_id']?.toString();
      _reconnectAttempt = 0;
      _setStatus(RealtimeStatus.connected);
      _subscribeUserChannel();
      return;
    }

    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }

    if (event == 'pusher:error') {
      debugPrint('[Realtime] server error: $inner');
      _setStatus(RealtimeStatus.failed);
      return;
    }

    if (event == 'pusher_internal:subscription_succeeded') {
      debugPrint('[Realtime] subscribed to $channel');
      return;
    }

    // Application events.
    if (channel != null && !event.startsWith('pusher')) {
      _dispatchAppEvent(event, channel, inner);
    }
  }

  Map<String, dynamic> _decodeData(dynamic data) {
    if (data is String) {
      try {
        final v = jsonDecode(data);
        if (v is Map) return Map<String, dynamic>.from(v);
      } catch (_) {/* fallthrough */}
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const {};
  }

  // ─── Subscribe ke user channel ──────────────────────────────────────────

  Future<void> _subscribeUserChannel() async {
    final socketId = _socketId;
    final userId = _userId;
    if (socketId == null || userId == null) return;

    final channelName = 'private-user.$userId';

    try {
      final res = await _ref.read(dioProvider).post<Map<String, dynamic>>(
        ApiConstants.broadcastingAuth,
        data: {'channel_name': channelName, 'socket_id': socketId},
      );
      final auth = res.data?['auth'] as String?;
      if (auth == null) {
        debugPrint('[Realtime] auth response missing `auth` field');
        return;
      }

      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': auth},
      });
    } catch (e) {
      debugPrint('[Realtime] subscribe failed: $e');
    }
  }

  // ─── App event handlers ─────────────────────────────────────────────────

  void _dispatchAppEvent(
    String event,
    String channel,
    Map<String, dynamic> data,
  ) {
    if (event == 'message.sent') {
      _handleMessageSent(data);
    } else if (event == 'message.read') {
      _handleMessageRead(data);
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      final convId = (data['conversation_id'] as num).toInt();
      final msgJson = Map<String, dynamic>.from(data['message'] as Map);
      final msg = Message.fromJson(msgJson);

      _ref.read(messagesProvider(convId).notifier).appendIncoming(msg);
      // ignore: unawaited_futures
      _ref.read(conversationsNotifierProvider.notifier).refresh();
    } catch (e, st) {
      debugPrint('[Realtime] handleMessageSent: $e\n$st');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final convId = (data['conversation_id'] as num).toInt();
      final currentUserId = switch (_ref.read(authNotifierProvider)) {
        AsyncData<User?>(:final value) => value?.id,
        _ => null,
      };
      if (currentUserId == null) return;

      _ref
          .read(messagesProvider(convId).notifier)
          .markOwnAsRead(currentUserId);
    } catch (e, st) {
      debugPrint('[Realtime] handleMessageRead: $e\n$st');
    }
  }

  // ─── Send + lifecycle ───────────────────────────────────────────────────

  void _send(Map<String, dynamic> payload) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[Realtime] send failed: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[Realtime] socket error: $error');
    _setStatus(RealtimeStatus.reconnecting);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[Realtime] socket closed');
    _setStatus(RealtimeStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_userId == null) return;

    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delaySec = 1 << (_reconnectAttempt - 1); // 1, 2, 4, 8, 16, 32
    final clamped = delaySec.clamp(1, 30);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: clamped), () {
      if (_userId == null) return;
      _open();
    });
  }

  Future<void> disconnect() async {
    final sub = _sub;
    final ch = _channel;

    _userId = null;
    _socketId = null;
    _channel = null;
    _sub = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _setStatus(RealtimeStatus.disconnected);

    try {
      await sub?.cancel();
    } catch (_) {/* ignore */}
    try {
      await ch?.sink.close(ws_status.normalClosure);
    } catch (_) {/* ignore */}
  }

  // ─── Status ─────────────────────────────────────────────────────────────

  void _setStatus(RealtimeStatus status) {
    try {
      _ref.read(realtimeStatusProvider.notifier).set(status);
    } catch (_) {
      // Ref bisa invalid jika kita dipanggil dari onDispose lifecycle.
      // Aman untuk diabaikan — UI banner akan ke-update di lifecycle berikutnya.
    }
  }
}

/// Status koneksi WebSocket terkini, untuk konsumsi UI (banner reconnect).
class RealtimeStatusNotifier extends Notifier<RealtimeStatus> {
  @override
  RealtimeStatus build() => RealtimeStatus.disconnected;

  void set(RealtimeStatus status) {
    state = status;
  }
}

final realtimeStatusProvider =
    NotifierProvider<RealtimeStatusNotifier, RealtimeStatus>(
  RealtimeStatusNotifier.new,
);

/// Singleton service. Listener auth → connect / disconnect terhadap perubahan login.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);

  ref.listen<AsyncValue<User?>>(
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
        service.connect(nextId);
      } else {
        // ignore: unawaited_futures
        service.disconnect();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    // ignore: unawaited_futures
    service.disconnect();
  });

  return service;
});
