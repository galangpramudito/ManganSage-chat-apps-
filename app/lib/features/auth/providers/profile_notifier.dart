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
    // Ambil dependency dari `ref` SEBELUM await. Provider ini autoDispose;
    // kalau `ref`/`state` disentuh setelah await bisa kena "used after dispose".
    final dio = ref.read(dioProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;

    final res = await dio.put<Map<String, dynamic>>(
      ApiConstants.profile,
      data: body,
    );

    final updatedUser = User.fromJson(res.data!['user'] as Map<String, dynamic>);
    authNotifier.state = AsyncData(updatedUser);
  }
}
