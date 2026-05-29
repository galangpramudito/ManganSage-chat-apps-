import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID conversation yang sedang dibuka user (di ChatRoom).
/// Dipakai nanti oleh handler FCM untuk men-suppress notifikasi
/// kalau user sudah berada di chat tersebut.
class ActiveConversationNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setActive(int? id) {
    state = id;
  }
}

final activeConversationProvider =
    NotifierProvider<ActiveConversationNotifier, int?>(
  ActiveConversationNotifier.new,
);
