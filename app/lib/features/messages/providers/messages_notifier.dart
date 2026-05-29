import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/message.dart';
import '../data/messages_api.dart';

part 'messages_notifier.g.dart';

/// State pesan untuk satu conversation tertentu.
class MessagesState {
  const MessagesState({
    required this.messages,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  /// Urut DESC by created_at — terbaru di index 0.
  /// Cocok untuk `ListView(reverse: true)`.
  final List<Message> messages;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  MessagesState copyWith({
    List<Message>? messages,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Per-conversation messages notifier — `family` by `conversationId`.
///
/// Mendukung:
/// - Initial load (page 1) di `build`.
/// - `loadMore` saat scroll ke atas.
/// - `sendMessage` — POST + append.
/// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).
@riverpod
class MessagesNotifier extends _$MessagesNotifier {
  static const _perPage = 20;

  @override
  Future<MessagesState> build(int conversationId) async {
    final page = await ref
        .read(messagesApiProvider)
        .page(conversationId, page: 1, perPage: _perPage);

    return MessagesState(
      messages: page.data,
      currentPage: 1,
      hasMore: page.meta.lastPage > 1,
    );
  }

  Future<void> loadMore() async {
    final current = _current();
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final result = await ref
          .read(messagesApiProvider)
          .page(conversationId, page: nextPage, perPage: _perPage);

      state = AsyncData(current.copyWith(
        messages: [...current.messages, ...result.data],
        currentPage: nextPage,
        hasMore: nextPage < result.meta.lastPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Kirim pesan + tambah ke state (di awal list — index 0 untuk DESC order).
  Future<Message> sendMessage(String body) async {
    final created =
        await ref.read(messagesApiProvider).send(conversationId, body);

    final current = _current();
    if (current != null) {
      state = AsyncData(current.copyWith(
        messages: [created, ...current.messages],
      ));
    }
    return created;
  }

  /// Tandai semua pesan dari lawan sebagai sudah dibaca (server + local).
  Future<void> markAllRead(int currentUserId) async {
    final current = _current();
    if (current == null) return;

    await ref.read(messagesApiProvider).markAllRead(conversationId);

    state = AsyncData(current.copyWith(
      messages: [
        for (final m in current.messages)
          m.senderId != currentUserId ? m.copyWith(isRead: true) : m,
      ],
    ));
  }

  /// Dipanggil saat menerima broadcast `message.read` dari lawan:
  /// pesan-pesan YANG SAYA KIRIM kini sudah dibaca penerima.
  /// Hanya update local state — server-side sudah dihandle oleh user lain.
  void markOwnAsRead(int currentUserId) {
    final current = _current();
    if (current == null) return;

    state = AsyncData(current.copyWith(
      messages: [
        for (final m in current.messages)
          m.senderId == currentUserId ? m.copyWith(isRead: true) : m,
      ],
    ));
  }

  /// Tambah pesan secara lokal (mis. dipanggil oleh listener WebSocket nanti).
  void appendIncoming(Message message) {
    final current = _current();
    if (current == null) return;
    if (current.messages.any((m) => m.id == message.id)) return;
    state = AsyncData(current.copyWith(
      messages: [message, ...current.messages],
    ));
  }

  MessagesState? _current() => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };
}
