import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_updater_service.dart';
export 'app_updater_service.dart' show AppRelease;

/// Provider yang mengecek update saat pertama kali di-watch.
/// Return [AppRelease] jika ada update tersedia, `null` jika sudah terbaru.
///
/// Gunakan `ref.watch(appUpdateCheckerProvider)` di home screen.
/// Provider ini auto-dispose, jadi hanya jalan sekali per session.
final appUpdateCheckerProvider = FutureProvider.autoDispose<AppRelease?>((ref) async {
  return AppUpdaterService.checkForUpdate();
});
