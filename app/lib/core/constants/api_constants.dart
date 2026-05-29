/// Konstanta endpoint & konfigurasi backend.
///
/// Default: production Fly.io (API + Reverb WebSocket aktif via TLS).
/// `flutter run`/`build` tanpa flag akan langsung connect ke server cloud.
///
/// Untuk dev lokal, override via `--dart-define`:
///
/// ```
/// --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
/// --dart-define=REVERB_HOST=10.0.2.2
/// --dart-define=REVERB_PORT=8080
/// --dart-define=REVERB_FORCE_TLS=false
/// --dart-define=REVERB_APP_KEY=COPY_FROM_BACKEND_ENV
/// ```
///
/// Catatan host-nya:
/// - Android emulator: `10.0.2.2` map ke host `localhost`
/// - iOS simulator: `localhost`
/// - Real device: pakai IP LAN host (mis. `192.168.x.x`)
class ApiConstants {
  ApiConstants._();

  /// Base URL HTTP API Laravel.
  ///
  /// Default: production Fly.io. Untuk dev lokal override saat build:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mangansage-api.fly.dev/api',
  );

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String resendVerification = '/resend-verification';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String currentUser = '/user';

  // ─── Profile ─────────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';

  // ─── Password Reset ──────────────────────────────────────────────────────
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // ─── Users ───────────────────────────────────────────────────────────────
  static const String users = '/users';

  // ─── Conversations ───────────────────────────────────────────────────────
  static const String conversations = '/conversations';
  static String conversation(int id) => '/conversations/$id';
  static String conversationMessages(int id) => '/conversations/$id/messages';
  static String conversationRead(int id) => '/conversations/$id/read';

  // ─── FCM ─────────────────────────────────────────────────────────────────
  static const String fcmToken = '/user/fcm-token';

  // ─── Broadcasting (Reverb auth) ─────────────────────────────────────────
  /// Sanctum-protected route untuk authorize subscribe ke private channel.
  static const String broadcastingAuth = '/broadcasting/auth';

  // ─── Reverb / WebSocket ──────────────────────────────────────────────────
  /// Default: production Reverb di Fly.io (TLS port 443).
  /// Override untuk dev lokal (lihat `RealtimeService`).
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: 'mangansage-reverb.fly.dev',
  );
  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 443,
  );
  /// Pusher *client* key (public — dikirim di URL `/app/{key}`, bukan secret).
  static const String reverbKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '85m3xr92ezs4ayj0hfl7utc1knvqdiog',
  );
  static const bool reverbForceTLS = bool.fromEnvironment(
    'REVERB_FORCE_TLS',
    defaultValue: true,
  );

  /// Kalau host atau key kosong → WebSocket layer skip init.
  /// Real-time fallback ke pull-to-refresh; UI tetap fungsional via REST.
  static bool get reverbConfigured =>
      reverbHost.isNotEmpty && reverbKey.isNotEmpty;
}
