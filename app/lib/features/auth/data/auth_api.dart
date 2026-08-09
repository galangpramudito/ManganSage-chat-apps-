import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:bcrypt/bcrypt.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';
import 'auth_exception.dart';

/// Hasil login: SquadMember model dari Supabase
typedef AuthResult = ({SquadMember user, String token});

class AuthApi {
  AuthApi();

  Future<AuthResult> login({
    required String nama,
    required String password,
  }) async {
    try {
      final client = Supabase.instance.client;

      final cleanNama = nama.trim();
      final res = await client
          .from('squad_members')
          .select()
          .ilike('nama', cleanNama)
          .maybeSingle();

      if (res == null) {
        throw const AuthException.message('Nama tidak ditemukan di Squad MNG.');
      }

      final hashedPassword = res['password'] as String?;
      if (hashedPassword == null) {
        throw const AuthException.message('Password salah.');
      }

      bool isMatch = false;
      try {
        if (hashedPassword.startsWith(r'$2')) {
          isMatch = BCrypt.checkpw(password, hashedPassword);
        } else {
          isMatch = (password == hashedPassword);
        }
      } catch (e) {
        isMatch = (password == hashedPassword);
      }

      if (!isMatch) {
        throw const AuthException.message('Password salah.');
      }

      final user = SquadMember.fromJson(res);

      // Token simulasi session Supabase
      final token = 'mng_session_${user.id}';
      return (user: user, token: token);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.message('Gagal login: $e');
    }
  }

  Future<void> logout() async {}
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});


