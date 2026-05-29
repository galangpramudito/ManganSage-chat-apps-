import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user.dart';
import '../data/users_api.dart';

/// State global daftar user (Tab 2 — Pengguna).
/// Filter pencarian dilakukan client-side sesuai design-spec.md §8.
class UsersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    return ref.read(usersApiProvider).list();
  }

  /// Manual refresh (mis. pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(usersApiProvider).list());
  }
}

final usersNotifierProvider =
    AsyncNotifierProvider<UsersNotifier, List<User>>(UsersNotifier.new);
