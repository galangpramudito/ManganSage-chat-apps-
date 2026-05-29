import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/conversation.dart';
import '../data/conversations_api.dart';

/// State global daftar conversation (Tab 1 — Inbox).
class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    return ref.read(conversationsApiProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(conversationsApiProvider).list(),
    );
  }

  /// Hapus sepihak: optimistic remove + API call.
  /// Kalau API gagal, kita restore dari snapshot.
  Future<void> remove(int conversationId) async {
    final current = _current();
    if (current == null) return;

    final snapshot = current;
    state = AsyncData(
      current.where((c) => c.id != conversationId).toList(growable: false),
    );

    try {
      await ref.read(conversationsApiProvider).delete(conversationId);
    } catch (_) {
      // Rollback kalau gagal.
      state = AsyncData(snapshot);
      rethrow;
    }
  }

  /// Reset unread untuk satu conversation (dipanggil setelah mark-as-read).
  void clearUnread(int conversationId) {
    final current = _current();
    if (current == null) return;

    state = AsyncData([
      for (final c in current)
        if (c.id == conversationId)
          c.copyWith(
            unreadCount: 0,
            lastMessage: c.lastMessage?.copyWith(isRead: true),
          )
        else
          c,
    ]);
  }

  List<Conversation>? _current() => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };
}

final conversationsNotifierProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);
