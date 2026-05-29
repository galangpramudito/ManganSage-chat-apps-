import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conversations_notifier.dart';

/// Total unread count di seluruh conversation user — derived dari
/// `conversationsNotifierProvider`. Dipakai untuk badge tab "Obrolan".
///
/// Mengikuti technical-spec.md §6 (Provider Map): `unreadCountProvider`.
final totalUnreadProvider = Provider<int>((ref) {
  final state = ref.watch(conversationsNotifierProvider);
  return switch (state) {
    AsyncData(:final value) => value.fold(0, (sum, c) => sum + c.unreadCount),
    _ => 0,
  };
});
