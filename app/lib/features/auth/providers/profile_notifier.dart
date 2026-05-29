import 'dart:io';

import 'package:dio/dio.dart';
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

  Future<void> updateProfile({
    String? name,
    File? avatarFile,
  }) async {
    state = const AsyncLoading();

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData();

      if (name != null) formData.fields.add(MapEntry('name', name));
      if (avatarFile != null) {
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatarFile.path),
        ));
      }

      final res = await dio.put<Map<String, dynamic>>(
        ApiConstants.profile,
        data: formData,
      );

      // Update user di auth state
      final updatedUser = User.fromJson(res.data!['user'] as Map<String, dynamic>);
      ref.read(authNotifierProvider.notifier).state = AsyncData(updatedUser);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    state = const AsyncLoading();

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.delete<Map<String, dynamic>>(
        ApiConstants.profileAvatar,
      );

      // Update user di auth state
      final updatedUser = User.fromJson(res.data!['user'] as Map<String, dynamic>);
      ref.read(authNotifierProvider.notifier).state = AsyncData(updatedUser);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
