import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/schedules/screens/schedules_screen.dart';
import '../../features/squad/screens/squad_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable yang menotifikasi GoRouter saat auth state berubah.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);

      if (auth.isLoading || (!auth.hasValue && !auth.hasError)) {
        return null;
      }

      final isLoggedIn = auth.value != null;
      final loc = state.matchedLocation;
      final isOnAuth = loc == '/login';
      final isOnSplash = loc == '/';

      if (!isLoggedIn) {
        if (isOnAuth) return null;
        return '/login';
      }

      // Redirect everything to home after login
      if (isOnAuth || isOnSplash) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      // 5-Tab Bottom Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/squad', builder: (_, _) => const SquadScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/schedules', builder: (_, _) => const SchedulesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/attendance', builder: (_, _) => const AttendanceScreen()),
    ],
  );
});

