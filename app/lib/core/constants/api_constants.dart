/// Konstanta endpoint & konfigurasi backend Mangan Group (MNG Group).
class ApiConstants {
  ApiConstants._();

  /// Base URL HTTP API Laravel.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String logout = '/logout';
  static const String currentUser = '/user';
  static const String ping = '/ping';

  // ─── Profile ─────────────────────────────────────────────────────────────
  static const String profile = '/profile';

  // ─── Squad & Leaderboard ─────────────────────────────────────────────────
  static const String squad = '/squad';
  static const String leaderboard = '/squad/leaderboard';

  // ─── Game Schedules (Jadwal Mabar/Scrim) ──────────────────────────────────
  static const String schedules = '/schedules';
  static const String activeSchedule = '/schedules/active';
  static String scheduleAttend(String scheduleId) => '/schedules/$scheduleId/attend';
  static String scheduleAttendances(String scheduleId) => '/schedules/$scheduleId/attendances';

  // ─── Attendance (Riwayat Presensi) ────────────────────────────────────────
  static const String myAttendanceHistory = '/attendances/my-history';

  // ─── FCM ─────────────────────────────────────────────────────────────────
  static const String fcmToken = '/user/fcm-token';
}

