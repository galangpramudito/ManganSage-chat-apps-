import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

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
      final client = supa.Supabase.instance.client;
      final cleanNama = nama.trim();

      // 1. Resolve email (if user typed codename, get email from RPC or direct email)
      String? email;
      if (cleanNama.contains('@')) {
        email = cleanNama;
      } else {
        try {
          email = await client.rpc(
            'get_member_email',
            params: {'p_nama': cleanNama},
          );
        } catch (e) {
          debugPrint('[Auth] get_member_email rpc error: $e');
        }
      }

      if (email == null || email.isEmpty) {
        throw const AuthException.message('Codename atau Username tidak ditemukan.');
      }

      // 2. Sign in directly with Supabase Auth
      final supa.AuthResponse authRes;
      try {
        authRes = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on supa.AuthException catch (e) {
        if (e.message.toLowerCase().contains('invalid login credentials') ||
            e.message.toLowerCase().contains('invalid_grant')) {
          throw const AuthException.message('Codename atau Passcode salah.');
        }
        if (e.message.toLowerCase().contains('email not confirmed') ||
            e.message.toLowerCase().contains('email_not_confirmed')) {
          throw const AuthException.message('Email belum dikonfirmasi. Harap periksa inbox atau spam di Gmail Anda dan klik link verifikasi.');
        }
        throw AuthException.message(e.message);
      }

      final authUser = authRes.user;
      if (authUser == null) {
        throw const AuthException.message('Gagal melakukan autentikasi akun.');
      }

      // 3. Fetch SquadMember profile
      final memberData = await client
          .from('squad_members')
          .select()
          .ilike('nama', cleanNama)
          .maybeSingle();

      if (memberData == null) {
        throw const AuthException.message('Profil member tidak ditemukan di sistem.');
      }

      final user = SquadMember.fromJson(memberData);
      final token = authRes.session?.accessToken ?? 'mng_session_${user.id}';
      return (user: user, token: token);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.message(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<String?> getMemberEmail(String nama) async {
    try {
      final client = supa.Supabase.instance.client;
      final cleanNama = nama.trim();
      final String? email = await client.rpc(
        'get_member_email',
        params: {'p_nama': cleanNama},
      );
      return (email != null && email.isNotEmpty) ? email : null;
    } catch (e) {
      debugPrint('[Auth] getMemberEmail error: $e');
      return null;
    }
  }

  Future<bool> checkMemberExists(String nama) async {
    try {
      final client = supa.Supabase.instance.client;
      final cleanNama = nama.trim();
      final bool? exists = await client.rpc(
        'check_member_exists',
        params: {'p_nama': cleanNama},
      );
      if (exists != null) return exists;

      final res = await client
          .from('squad_members')
          .select('id')
          .ilike('nama', cleanNama)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('[Auth] checkMemberExists error: $e');
      return false;
    }
  }

  Future<AuthResult> registerAndLinkEmail({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final client = supa.Supabase.instance.client;
      final cleanNama = nama.trim();
      final cleanEmail = email.trim();

      // 1. Sign up user in Supabase Auth
      supa.AuthResponse signUpRes;
      try {
        signUpRes = await client.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'nama': cleanNama,
            'display_name': cleanNama,
          },
        );
      } on supa.AuthException catch (e) {
        if (e.message.toLowerCase().contains('already registered') ||
            e.message.toLowerCase().contains('already exists')) {
          // User already registered in Auth, try sign in directly
          return await login(nama: cleanNama, password: password);
        }
        throw AuthException.message(e.message);
      }

      final authUser = signUpRes.user;
      final session = signUpRes.session;

      // 2. Link email and user_id to squad_members
      if (authUser != null) {
        try {
          await client.rpc(
            'link_member_email',
            params: {
              'p_nama': cleanNama,
              'p_email': cleanEmail,
              'p_user_id': authUser.id,
            },
          );
        } catch (e) {
          debugPrint('[Auth] link_member_email RPC error: $e');
        }
      }

      // 3. If email confirmation is required (session is null)
      if (session == null) {
        throw AuthException.message(
          'VERIFICATION_SENT:Link verifikasi telah dikirim ke $cleanEmail. Buka Gmail Anda dan klik link konfirmasi untuk mengaktifkan akun.',
        );
      }

      // 4. Fetch SquadMember profile if session immediately active
      final memberData = await client
          .from('squad_members')
          .select()
          .ilike('nama', cleanNama)
          .maybeSingle();

      if (memberData == null) {
        throw const AuthException.message('Profil member tidak ditemukan di sistem.');
      }

      final user = SquadMember.fromJson(memberData);
      final token = session.accessToken;
      return (user: user, token: token);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.message(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    try {
      await supa.Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});


