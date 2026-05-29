import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user.dart';
import 'auth_notifier.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<void> build() async {
    // No initial state needed
  }

  /// Update nama dan/atau emoji avatar. Dikirim sebagai JSON biasa —
  /// tidak ada file/upload, jadi gratis (tanpa object storage).
  Future<void> updateProfile({
    String? name,
    String? avatar,
  }) async {
    state = const AsyncLoading();

    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (avatar != null) body['avatar'] = avatar;

      final res = await dio.put<Map<String, dynamic>>(
        ApiConstants.profile,
        data: body,
      );

      final updatedUser = User.fromJson(res.data!['user'] as Map<String, dynamic>);
      ref.read(authNotifierProvider.notifier).state = AsyncData(updatedUser);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
