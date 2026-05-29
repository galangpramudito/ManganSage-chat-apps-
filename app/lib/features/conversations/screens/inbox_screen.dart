import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/conversation.dart';
import '../../../shared/widgets/conversation_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/conversations_notifier.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConvs = ref.watch(conversationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Obrolan')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conversationsNotifierProvider.notifier).refresh(),
        child: switch (asyncConvs) {
          AsyncData(:final value) when value.isEmpty => const _EmptyInbox(),
          AsyncData(:final value) => _InboxList(conversations: value),
          AsyncError(:final error, :final stackTrace) => _InboxError(
              message: error.toString(),
              stackTrace: stackTrace,
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList({required this.conversations});
  final List<Conversation> conversations;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Conversation conv,
  ) async {
    try {
      await ref
          .read(conversationsNotifierProvider.notifier)
          .remove(conv.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus percakapan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        thickness: 0.5,
        indent: 76, // align dgn end avatar
        color: Theme.of(context).dividerColor,
      ),
      itemBuilder: (context, i) {
        final conv = conversations[i];
        return Dismissible(
          key: ValueKey('conv-${conv.id}'),
          direction: DismissDirection.endToStart,
          background: const DeleteSwipeBackground(),
          onDismissed: (_) => _confirmDelete(context, ref, conv),
          child: ConversationTile(
            conversation: conv,
            onTap: () => context.push(
              '/chat/${conv.id}',
              extra: conv.participant,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    // ListView agar pull-to-refresh tetap berfungsi di empty state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Belum ada obrolan',
          subtitle: 'Mulai dari tab Pengguna.',
        ),
      ],
    );
  }
}

class _InboxError extends ConsumerWidget {
  const _InboxError({required this.message, this.stackTrace});
  final String message;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Print ke console untuk debug
    debugPrint('❌ Inbox Error: $message');
    if (stackTrace != null) debugPrint('Stack: $stackTrace');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        EmptyState(
          icon: Icons.error_outline,
          title: 'Gagal memuat',
          subtitle: message.length > 100 ? '${message.substring(0, 100)}...' : message,
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => ref.read(conversationsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }
}
