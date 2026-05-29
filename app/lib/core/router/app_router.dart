import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/conversations/screens/inbox_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/messages/screens/chat_room_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../shared/models/conversation.dart';

/// Listenable yang menotifikasi GoRouter saat auth state berubah,
/// supaya redirect ter-evaluasi ulang.
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
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);

      if (auth.isLoading || (!auth.hasValue && !auth.hasError)) {
        return null;
      }

      final isLoggedIn = auth.value != null;
      final loc = state.matchedLocation;
      final isOnAuth = loc == '/login' || loc == '/register';
      final isOnSplash = loc == '/';

      if (!isLoggedIn) {
        if (isOnAuth) return null;
        // Public password-reset & email verification routes — biarkan diakses tanpa login.
        if (loc.startsWith('/forgot-password') ||
            loc.startsWith('/verify-otp') ||
            loc.startsWith('/verify-email') ||
            loc.startsWith('/reset-password')) {
          return null;
        }
        return '/login';
      }

      // Sudah login — splash/auth → inbox.
      if (isOnAuth || isOnSplash) return '/inbox';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Email verification flow.
      GoRoute(
        path: '/verify-email',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email, isEmailVerification: true);
        },
      ),

      // Password reset flow.
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final token = state.extra as String? ?? '';
          return ResetPasswordScreen(resetToken: token);
        },
      ),

      // Bottom-tab shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),

      // Chat room — fullscreen di luar shell.
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final participant = state.extra as Participant?;
          if (participant == null) {
            return ChatRoomScreen(
              conversationId: id,
              participant: const Participant(id: 0, name: 'Chat'),
            );
          }
          return ChatRoomScreen(conversationId: id, participant: participant);
        },
      ),
    ],
  );
});
