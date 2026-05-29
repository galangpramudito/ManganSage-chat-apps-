import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/websocket/realtime_service.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/utils/presence_format.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/chat_input_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../providers/active_conversation_provider.dart';
import '../providers/messages_notifier.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.participant,
  });

  final int conversationId;
  final Participant participant;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasMarkedRead = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeConversationProvider.notifier)
          .setActive(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    ref.read(activeConversationProvider.notifier).setActive(null);
    super.dispose();
  }

  void _onScroll() {
    // Karena `reverse: true`, posisi MAX = pesan paling lama → trigger load more.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .loadMore();
    }
  }

  /// Auto-scroll ke bawah (= ListView reverse:true position 0).
  /// Dipanggil setelah send message ATAU saat data baru tiba lewat WS.
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _send(String body) async {
    setState(() => _isSending = true);
    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendMessage(body);
      // Refresh inbox di latar (last_message berubah).
      // ignore: unawaited_futures
      ref.read(conversationsNotifierProvider.notifier).refresh();
      // Auto-scroll ke pesan yang baru kita kirim.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pesan.')),
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markReadOnce(int currentUserId) async {
    if (_hasMarkedRead) return;
    _hasMarkedRead = true;
    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .markAllRead(currentUserId);
      ref
          .read(conversationsNotifierProvider.notifier)
          .clearUnread(widget.conversationId);
    } catch (_) {
      _hasMarkedRead = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(authNotifierProvider);
    final currentUserId = switch (asyncUser) {
      AsyncData(:final value) => value?.id,
      _ => null,
    };

    final asyncMessages =
        ref.watch(messagesProvider(widget.conversationId));
    final theme = Theme.of(context);

    // Auto-scroll saat ada pesan baru tiba (mis. dari WS) — bandingkan
    // jumlah dengan frame sebelumnya. Hanya saat user dekat bottom (di
    // posisi 0..200) supaya tidak mengganggu kalau user sedang baca lama.
    if (currentUserId != null) {
      final value = switch (asyncMessages) {
        AsyncData(:final value) => value,
        _ => null,
      };

      if (value != null) {
        final newCount = value.messages.length;
        if (newCount > _previousMessageCount && _previousMessageCount > 0) {
          final atBottom = _scrollController.hasClients &&
              _scrollController.position.pixels < 200;
          if (atBottom) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
          }
        }
        _previousMessageCount = newCount;

        // Auto mark-as-read saat ada pesan dari lawan yang belum dibaca.
        if (value.messages.any(
            (m) => m.senderId != currentUserId && !m.isRead)) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _markReadOnce(currentUserId));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(
              name: widget.participant.name,
              emoji: widget.participant.avatar,
              size: AvatarSize.small,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.participant.name,
                    style: AppTypography.contactName.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    PresenceFormat.describe(
                      isOnline: widget.participant.isOnline,
                      lastSeen: widget.participant.lastSeen,
                    ),
                    style: AppTypography.timestamp.copyWith(
                      color: widget.participant.isOnline
                          ? AppColors.onlineDot(theme.brightness)
                          : theme.colorScheme.secondary,
                      fontWeight: widget.participant.isOnline
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const _ReconnectBanner(),
          Expanded(
            child: switch (asyncMessages) {
              AsyncData(:final value) when value.messages.isEmpty =>
                const EmptyState(
                  icon: Icons.message_outlined,
                  title: 'Belum ada pesan',
                  subtitle: 'Mulai percakapan dengan mengirim pesan pertama.',
                ),
              AsyncData(:final value) => _MessagesList(
                  state: value,
                  scrollController: _scrollController,
                  currentUserId: currentUserId ?? -1,
                  participant: widget.participant,
                ),
              AsyncError(:final error) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat pesan',
                  subtitle: error.toString(),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          ChatInputBar(onSend: _send, isSending: _isSending),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.state,
    required this.scrollController,
    required this.currentUserId,
    required this.participant,
  });

  final MessagesState state;
  final ScrollController scrollController;
  final int currentUserId;
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final messages = state.messages; // DESC: index 0 = terbaru
    final itemCount = messages.length + (state.hasMore ? 1 : 0);

    return ListView.builder(
      reverse: true,
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (state.hasMore && i == messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msg = messages[i];

        // Tetangga di list (DESC index): i-1 = pesan SETELAH (lebih baru),
        // i+1 = pesan SEBELUM (lebih lama).
        final newer = i > 0 ? messages[i - 1] : null;
        final older = i + 1 < messages.length ? messages[i + 1] : null;

        final isMine = msg.senderId == currentUserId;
        final isFirstInGroup = older?.senderId != msg.senderId;
        final isLastInGroup = newer?.senderId != msg.senderId;
        final startsNewGroup = isLastInGroup;

        return MessageBubble(
          message: msg,
          isMine: isMine,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          startsNewGroup: startsNewGroup,
          // Smart Avatar Display (received only).
          participantName: participant.name,
          participantAvatarUrl: participant.avatar,
        );
      },
    );
  }
}

/// Banner kecil saat WS putus mid-session — ditampilkan HANYA saat
/// `reconnecting` (bukan saat awal disconnected karena Reverb belum
/// terkonfigurasi). Tujuan: ramah UX — kalau memang belum ada infrastruktur
/// realtime, tidak perlu user diberi peringatan terus-menerus. Status presence
/// pengguna terkait sekarang ditampilkan di header (Online / Aktif X menit lalu).
class _ReconnectBanner extends ConsumerWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    final brightness = Theme.of(context).brightness;
    final theme = Theme.of(context);

    // Hanya tampilkan saat sedang reconnecting (= sebelumnya pernah connected
    // tapi sekarang putus). Status `disconnected` murni dari ApiConstants
    // belum terkonfigurasi → silently no-op, biar user tidak bingung.
    final show = status == RealtimeStatus.reconnecting;
    final label = switch (status) {
      RealtimeStatus.reconnecting => 'Menghubungkan ulang…',
      _ => '',
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: show
            ? Container(
                key: const ValueKey('banner'),
                width: double.infinity,
                color: AppColors.accentSoft(brightness),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppSpacing.md,
                ),
                child: Text(
                  label,
                  style: AppTypography.timestamp.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
