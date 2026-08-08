import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../models/supabase_models.dart';
import 'avatar_widget.dart';

/// Tile pengguna di Tab 2 — design-spec.md §8.
/// Avatar 48 + nama + dot online (8px) + email muted.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final SquadMember user;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarWidget(nama: user.nama),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama,
                      style: AppTypography.contactName.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                        Text(
                          user.role,
                          style: AppTypography.messagePreview.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
