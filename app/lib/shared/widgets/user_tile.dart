import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../models/user.dart';
import '../utils/presence_format.dart';
import 'avatar_widget.dart';

/// Tile pengguna di Tab 2 — design-spec.md §8.
/// Avatar 48 + nama + dot online (8px) + email muted.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.isStartingChat = false,
  });

  final User user;
  final VoidCallback onTap;

  /// Saat user di-tap dan kita sedang membuat conversation, tampilkan
  /// spinner di sisi kanan agar feedback proses jelas.
  final bool isStartingChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: isStartingChat ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarWidget(name: user.name, photoUrl: user.avatar),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.onlineDot(brightness),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surfaceContainerHigh,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTypography.contactName.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (user.isOnline) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.onlineDot(theme.brightness),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: AppTypography.messagePreview.copyWith(
                              color: AppColors.onlineDot(theme.brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else
                          Text(
                            PresenceFormat.describe(
                              isOnline: false,
                              lastSeen: user.lastSeen,
                            ),
                            style: AppTypography.messagePreview.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isStartingChat)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
