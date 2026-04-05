import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/login_screen.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_placeholder_screen.dart';
import 'package:ciel_mobile/features/notifications/presentation/notifications_placeholder_screen.dart';
import 'package:ciel_mobile/features/post/presentation/create_post_placeholder_screen.dart';
import 'package:ciel_mobile/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:ciel_mobile/features/shell/presentation/main_shell_screen.dart';
import 'package:ciel_mobile/features/shell/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    refresh.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final path = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      if (auth.status == AuthStatus.loading) {
        if (path == '/splash' || path == '/auth') return null;
        return '/splash';
      }

      if (!auth.isAuthenticated) {
        if (path == '/auth') return null;
        return '/auth';
      }

      if (path == '/splash' || path == '/auth') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostPlaceholderScreen(),
      ),
    ],
  );
});
