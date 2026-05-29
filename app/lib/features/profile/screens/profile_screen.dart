import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../auth/screens/edit_profile_screen.dart';

/// Tab Profil — design-spec.md §8 Tab 3.
/// Hero atas dengan accent-soft, avatar 88 + ring accent, action list,
/// tombol logout outlined destructive.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(authNotifierProvider);
    final user = switch (asyncUser) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Hero section.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(brightness),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.card * 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      AvatarWidget(
                        name: user.name,
                        photoUrl: user.avatar,
                        size: AvatarSize.profile,
                        ringColor: theme.colorScheme.primary,
                        ringWidth: 3,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user.name,
                        style: AppTypography.profileName.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTypography.messagePreview.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action list — wrapped in card.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    children: [
                      _ProfileAction(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profil',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 56,
                        color: theme.dividerColor,
                      ),
                      _ProfileAction(
                        icon: Icons.notifications_outlined,
                        label: 'Edit Nama',
                        onTap: () => _notImplemented(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Logout — outlined destructive.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, ref),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: AppColors.destructive(brightness),
                      ),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.destructive(brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: AppColors.destructive(brightness),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur akan datang.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final brightness = Theme.of(context).brightness;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Kamu akan keluar dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.destructive(brightness)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.contactName.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.secondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
