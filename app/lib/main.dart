import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/websocket/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  runApp(const ProviderScope(child: MangansageApp()));
}

class MangansageApp extends ConsumerWidget {
  const MangansageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager-watch realtime + fcm provider supaya keduanya ter-init sejak awal.
    // Listener internal di tiap provider akan auto-connect saat user login.
    ref.watch(realtimeServiceProvider);
    ref.watch(fcmServiceProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mangansage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
