import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/secure_storage.dart';
import '../../../shared/models/user.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../../messages/providers/active_conversation_provider.dart';
import '../../messages/providers/messages_notifier.dart';
import '../../users/providers/users_notifier.dart';
import '../data/auth_api.dart';
import '../data/auth_exception.dart';

/// Otoritas tunggal untuk state auth.
///
/// `AsyncValue<User?>`:
/// - `loading`     — sedang validasi token / submit form
/// - `data(null)`  — unauthenticated
/// - `data(User)`  — authenticated
/// - `error`       — gagal submit (login/register), pesan dipakai screen
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();

    // Jalankan validasi auth dan delay animasi splash secara paralel.
    // Animasi splash total memakan waktu 2.8 detik (2s draw + 0.8s text fade).
    final authFuture = () async {
      if (token == null) return null;

      // Token ada lokal — validasi ke /api/user.
      try {
        return await ref.read(authApiProvider).me();
      } on AuthException catch (_) {
        // Token tidak valid lagi → bersihkan. Jangan bocorkan error ke UI.
        await storage.clear();
        return null;
      }
    }();

    final results = await Future.wait([
      authFuture,
      Future.delayed(const Duration(milliseconds: 2800)),
    ]);

    return results[0] as User?;
  }

  Future<void> setAuthResult(({User user, String token}) result) async {
    await ref.read(secureStorageProvider).saveToken(result.token);
    state = AsyncData(result.user);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authApiProvider).login(
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
    // Tetap coba revoke ke server — tapi jangan blokir clear lokal kalau gagal.
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Sengaja diabaikan: kita tetap clear local state.
    }
    await ref.read(secureStorageProvider).clear();
    _resetUserScopedState();
    state = const AsyncData(null);
  }

  /// Dipanggil oleh AuthInterceptor saat menerima 401 mid-session.
  /// Tidak menghubungi server — hanya bersihkan local state.
  Future<void> clearSessionLocally() async {
    await ref.read(secureStorageProvider).clear();
    _resetUserScopedState();
    state = const AsyncData(null);
  }

  /// Bersihkan SEMUA cached state yang user-scoped.
  /// Tanpa ini, ganti akun akan menampilkan obrolan/data user sebelumnya
  /// untuk sekejap (atau bahkan permanen sampai pull-to-refresh).
  void _resetUserScopedState() {
    ref.read(activeConversationProvider.notifier).setActive(null);
    ref.invalidate(conversationsNotifierProvider);
    ref.invalidate(usersNotifierProvider);
    // `messagesProvider` adalah family — invalidate menghapus SEMUA
    // instance (per conversationId).
    ref.invalidate(messagesProvider);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
