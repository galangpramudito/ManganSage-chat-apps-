import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/profile_notifier.dart';

/// Pilihan emoji avatar — buat lucu-lucuan antar teman.
const _avatarEmojis = [
  '😀', '😎', '🤓', '🥳', '😜', '🤪', '🥶', '🤠',
  '👻', '🤖', '👽', '🐱', '🐶', '🦊', '🐼', '🐸',
  '🦁', '🐯', '🐵', '🦄', '🐧', '🐙', '🍕', '🌮',
  '🔥', '⚡', '🌈', '💀', '👑', '🎮', '🚀', '⚽',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _selectedEmoji;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _selectedEmoji = user?.avatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(profileProvider.notifier).updateProfile(
            name: _nameCtrl.text.trim(),
            avatar: _selectedEmoji,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diupdate')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Preview avatar emoji terpilih.
            Center(
              child: AvatarWidget(
                name: user?.name ?? '',
                emoji: _selectedEmoji,
                size: 100,
                ringColor: theme.colorScheme.primary,
                ringWidth: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Grid emoji picker.
            Text('Pilih avatar', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in _avatarEmojis)
                  _EmojiChip(
                    emoji: e,
                    selected: _selectedEmoji == e,
                    onTap: () => setState(() => _selectedEmoji = e),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Nama
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Email (read-only)
            TextFormField(
              initialValue: user?.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabled: false,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
