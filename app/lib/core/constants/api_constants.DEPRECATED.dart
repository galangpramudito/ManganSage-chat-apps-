// DEPRECATED - TIDAK DIGUNAKAN
// File ini adalah sisa dari arsitektur Laravel API yang sudah tidak digunakan.
// Backend sekarang menggunakan Next.js + Supabase langsung.
// 
// File akan dihapus di versi berikutnya.
// Jangan import file ini di kode baru!
//
// Migration: 2026-08-10
// Reason: Laravel backend replaced with Next.js + Supabase direct connection

/// Konstanta endpoint Laravel API (DEPRECATED - NOT USED)
@Deprecated('Use Supabase direct connection instead')
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // ─── Auth ────────────────────────────────────────────────────────────────
  @Deprecated('Use Supabase Auth instead')
  static const String login = '/login';
  
  @Deprecated('Use Supabase Auth instead')
  static const String logout = '/logout';
  
  @Deprecated('Use Supabase Auth instead')
  static const String currentUser = '/user';
  
  static const String ping = '/ping';

  // ─── Profile ─────────────────────────────────────────────────────────────
  @Deprecated('Use Supabase direct query instead')
  static const String profile = '/profile';

  // ─── Squad & Leaderboard ─────────────────────────────────────────────────
  @Deprecated('Use Supabase direct query instead')
  static const String squad = '/squad';
  
  @Deprecated('Use Supabase direct query instead')
  static const String leaderboard = '/squad/leaderboard';

  // ─── Game Schedules ──────────────────────────────────────────────────────
  @Deprecated('Use Supabase direct query instead')
  static const String schedules = '/schedules';
  
  @Deprecated('Use Supabase direct query instead')
  static const String activeSchedule = '/schedules/active';

  // ─── Attendance ──────────────────────────────────────────────────────────
  @Deprecated('Use Supabase direct query instead')
  static const String myAttendanceHistory = '/attendances/my-history';

  // ─── FCM ─────────────────────────────────────────────────────────────────
  @Deprecated('Save directly to Supabase fcm_tokens table')
  static const String fcmToken = '/user/fcm-token';
}
