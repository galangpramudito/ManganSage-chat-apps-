import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user.dart';
import 'auth_exception.dart';

/// Hasil dari register/login: pasangan user + token Sanctum.
typedef AuthResult = ({User user, String token});

/// Wrapper raw API call untuk endpoint auth.
/// Semua error 4xx/5xx dipetakan ke [AuthException].
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      // Return email untuk step verifikasi
      return res.data?['email']?.toString() ?? email;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.verifyEmail,
        data: {'email': email, 'otp': otp},
      );
      return _parseAuthSuccess(res);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<String> resendVerification(String email) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.resendVerification,
        data: {'email': email},
      );
      return res.data?['message']?.toString() ?? 'OTP terkirim.';
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return _parseAuthSuccess(res);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  // ─── Password Reset (OTP via email) ─────────────────────────────────────

  /// POST /api/forgot-password — selalu balas sukses (anti enumeration).
  /// User akan dapat email dengan kode OTP 6-digit kalau emailnya terdaftar.
  Future<String> forgotPassword(String email) async {
    try {
      debugPrint('📤 POST ${ApiConstants.forgotPassword} with email: $email');
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      debugPrint('📥 Response: ${res.statusCode} - ${res.data}');
      return res.data?['message']?.toString() ?? 'OTP terkirim.';
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
      throw _toAuthException(e);
    } catch (e) {
      debugPrint('❌ Unknown error in forgotPassword: $e');
      rethrow;
    }
  }

  /// POST /api/verify-otp → return `reset_token` untuk langkah berikutnya.
  Future<String> verifyOtp({required String email, required String otp}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otp': otp},
      );
      final token = res.data?['reset_token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AuthException.message('Server tidak mengembalikan reset token.');
      }
      return token;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// POST /api/reset-password
  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.resetPassword,
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return res.data?['message']?.toString() ?? 'Password berhasil direset.';
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// GET /api/user — validasi token + ambil profil terkini.
  Future<User> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiConstants.currentUser);
      if (res.data != null) {
        return User.fromJson(res.data!);
      }
      throw const AuthException.message('Body kosong dari /api/user.');
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AuthResult _parseAuthSuccess(Response<Map<String, dynamic>> res) {
    final data = res.data!;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (user: user, token: token);
  }

  AuthException _toAuthException(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (status == 422 && body is Map) {
      return _parseValidation(Map<String, dynamic>.from(body));
    }

    final msg = _extractMessage(body) ?? e.message ?? 'Kesalahan jaringan.';
    return AuthException.message(msg);
  }

  AuthException _parseValidation(Map<String, dynamic> body) {
    final errors = <String, List<String>>{};
    final raw = body['errors'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is List) {
          errors[key.toString()] =
              value.map((e) => e.toString()).toList(growable: false);
        }
      });
    }
    return AuthException.validation(
      errors,
      message: body['message']?.toString(),
    );
  }

  String? _extractMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'];
      if (msg is String) return msg;
    }
    return null;
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
