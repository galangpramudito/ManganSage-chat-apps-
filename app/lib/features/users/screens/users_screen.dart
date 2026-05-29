import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_tile.dart';
import '../../conversations/data/conversations_api.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../providers/users_notifier.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _startingChatWithUserId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startChat(User user) async {
    if (_startingChatWithUserId != null) return;
    setState(() => _startingChatWithUserId = user.id);

    try {
      final result = await ref.read(conversationsApiProvider).startWith(user.id);

      // ignore: unawaited_futures
      ref.read(conversationsNotifierProvider.notifier).refresh();

      if (!mounted) return;
      context.push('/chat/${result.id}', extra: result.participant);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memulai percakapan.')),
      );
    } finally {
      if (mounted) {
        setState(() => _startingChatWithUserId = null);
      }
    }
  }

  List<User> _filter(List<User> users) {
    if (_query.isEmpty) return users;
    final q = _query.toLowerCase();
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(usersNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
      body: Column(
        children: [
          // Search bar — selalu visible, surface-elevated background.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                hintText: 'Cari nama atau email…',
                hintStyle: TextStyle(color: theme.colorScheme.secondary),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(usersNotifierProvider.notifier).refresh(),
              child: switch (asyncUsers) {
                AsyncData(:final value) => _buildList(_filter(value)),
                AsyncError(:final error) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.error_outline,
                        title: 'Gagal memuat pengguna',
                        subtitle: error.toString(),
                      ),
                    ],
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<User> users) {
    if (users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada hasil',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        thickness: 0.5,
        indent: 76,
        color: Theme.of(context).dividerColor,
      ),
      itemBuilder: (_, i) {
        final u = users[i];
        return UserTile(
          user: u,
          isStartingChat: _startingChatWithUserId == u.id,
          onTap: () => _startChat(u),
        );
      },
    );
  }
}
