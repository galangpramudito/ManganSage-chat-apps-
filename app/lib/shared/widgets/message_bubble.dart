import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../models/message.dart';
import '../utils/timestamp_format.dart';
import 'avatar_widget.dart';

/// Bubble pesan — design-spec.md §4 + §6 + §8 ChatRoom.
///
/// - Sent (mine):     align kanan, bg accent (sapphire), text putih
/// - Received:        align kiri, bg surface (putih) dengan border tipis
///                    + subtle shadow (light mode), avatar di pesan PERTAMA
/// - Tail:            sudut flat di sisi pengirim untuk pesan pertama group
/// - Spacing:         4px dalam group, 12px antar group beda pengirim
/// - Status (mine):   ⏱ sending → ✓ sent → ✓✓ delivered (muted) → ✓✓ read (putih)
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.startsNewGroup,
    this.participantName,
    this.participantAvatarUrl,
  });

  final Message message;
  final bool isMine;

  /// True kalau pesan ini PERTAMA dalam rangkaian (paling lama secara render —
  /// paling atas dalam group).
  final bool isFirstInGroup;

  /// True kalau pesan ini TERAKHIR dalam rangkaian (paling baru — paling
  /// bawah dalam group).
  final bool isLastInGroup;

  /// True kalau group sebelumnya berbeda pengirim — perlu margin atas 12.
  final bool startsNewGroup;

  /// Untuk Smart Avatar Display (received only). Avatar lawan hanya tampil
  /// di pesan pertama dari rangkaian — lihat design-spec §8 ChatRoom.
  final String? participantName;
  final String? participantAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bg = isMine
        ? AppColors.bubbleSent(brightness)
        : AppColors.bubbleReceived(brightness);
    final fg = isMine
        ? AppColors.bubbleSentText(brightness)
        : AppColors.bubbleReceivedText(brightness);

    final topMargin = startsNewGroup ? AppSpacing.md - 4 : 2.0;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _bubbleRadius(),
        border: !isMine
            ? Border.all(
                color: AppColors.bubbleReceivedBorder(brightness),
                width: 1,
              )
            : null,
        boxShadow: !isMine && !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        message.body,
        style: AppTypography.messageBody.copyWith(color: fg),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: topMargin,
        bottom: 2.0,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Smart Avatar Display: hanya pesan pertama group received yang
          // menampilkan avatar lawan. Pesan lain di group dapat spacer kosong
          // selebar avatar agar bubble tetap rata kiri.
          if (!isMine) ...[
            SizedBox(
              width: AvatarSize.small,
              child: isFirstInGroup
                  ? AvatarWidget(
                      name: participantName ?? '?',
                      photoUrl: participantAvatarUrl,
                      size: AvatarSize.small,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bubble,
                  if (isLastInGroup) ...[
                    const SizedBox(height: 3),
                    _MetaRow(
                      time: TimestampFormat.bubble(message.createdAt),
                      isMine: isMine,
                      isRead: message.isRead,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tail = sudut flat di sisi pengirim, HANYA untuk pesan pertama group.
  /// "Pertama" = paling atas (kronologis paling lama) dalam group.
  BorderRadius _bubbleRadius() {
    const r = AppRadius.bubble;
    const flat = Radius.circular(6);
    const round = Radius.circular(r);

    if (!isFirstInGroup) {
      return const BorderRadius.all(round);
    }

    if (isMine) {
      return const BorderRadius.only(
        topLeft: round,
        topRight: flat,
        bottomLeft: round,
        bottomRight: round,
      );
    }
    return const BorderRadius.only(
      topLeft: flat,
      topRight: round,
      bottomLeft: round,
      bottomRight: round,
    );
  }
}

/// Timestamp + status indicator (centang) — design-spec.md §6.
/// Variasi state lengkap (sending/sent/delivered/read/failed) butuh tracking
/// per-pesan yang belum dimodelkan. Sementara: 2-state simulasi via `isRead`.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.time,
    required this.isMine,
    required this.isRead,
  });

  final String time;
  final bool isMine;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: AppTypography.timestamp.copyWith(color: muted),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 13,
            // Read = putih (kontras di atas bubble biru sent).
            // Unread = muted.
            color: isRead ? Colors.white.withValues(alpha: 0.95) : muted,
          ),
        ],
      ],
    );
  }
}
