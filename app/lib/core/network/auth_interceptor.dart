import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_notifier.dart';
import 'secure_storage.dart';

/// Interceptor untuk:
/// 1. Menyisipkan `Authorization: Bearer <token>` di setiap request.
/// 2. Menangkap 401 → bersihkan storage + reset session lokal.
///
/// Source: technical-spec.md §7.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _ref.read(secureStorageProvider).getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Hanya bersihkan sesi kalau user MEMANG sedang authenticated.
      // Saat AuthNotifier.build() validasi token awal dan dapat 401,
      // ia akan handle sendiri — kita tak boleh menyentuh state-nya.
      final auth = _ref.read(authNotifierProvider);
      if (auth.hasValue && auth.value != null) {
        await _ref
            .read(authNotifierProvider.notifier)
            .clearSessionLocally();
      }
    }
    handler.next(err);
  }
}
