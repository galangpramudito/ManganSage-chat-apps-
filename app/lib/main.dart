import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notifications/alarm_service.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/env/env_validator.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Validate environment configuration sebelum start app
  SupabaseConfig.validate();

  // Inisialisasi Supabase resmi yang terhubung langsung ke web mngesports.my.id
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: MangansageApp()));
}

class MangansageApp extends ConsumerWidget {
  const MangansageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager-init FCM & Local Alarm Notification untuk match reminder
    ref.watch(fcmServiceProvider);
    ref.watch(alarmServiceProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MNG Group',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

