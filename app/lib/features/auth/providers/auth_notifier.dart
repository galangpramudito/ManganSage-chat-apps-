import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/secure_storage.dart';
import '../../../shared/models/supabase_models.dart';
import '../data/auth_api.dart';
import '../data/auth_exception.dart';

class AuthNotifier extends AsyncNotifier<SquadMember?> {
  @override
  Future<SquadMember?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();

    if (token == null) {
      await Future.delayed(const Duration(milliseconds: 1500));
      return null;
    }

    try {
      final userJson = await storage.getUserData();
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        await Future.delayed(const Duration(milliseconds: 1200));
        return SquadMember.fromJson(map);
      }
    } catch (_) {
      await storage.clear();
    }
    return null;
  }

  Future<void> setAuthResult(({SquadMember user, String token}) result) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveToken(result.token);
    await storage.saveUserData(jsonEncode(result.user.toJson()));
    state = AsyncData(result.user);
  }

  Future<void> login({
    required String nama,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authApiProvider).login(
            nama: nama,
            password: password,
          );
      await setAuthResult(result);
    } on AuthException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> registerAndLinkEmail({
    required String nama,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authApiProvider).registerAndLinkEmail(
            nama: nama,
            email: email,
            password: password,
          );
      await setAuthResult(result);
    } on AuthException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {}
    await ref.read(secureStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> clearSessionLocally() async {
    await ref.read(secureStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, SquadMember?>(
  AuthNotifier.new,
);

