import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/auth/presentation/login_screen.dart';
import 'package:ciel_mobile/features/auth/presentation/signup_screen.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_screen.dart';
import 'package:ciel_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:ciel_mobile/features/post/presentation/create_post_screen.dart';
import 'package:ciel_mobile/features/post/presentation/post_detail_screen.dart';
import 'package:ciel_mobile/features/profile/presentation/profile_screen.dart';
import 'package:ciel_mobile/features/search/presentation/search_screen.dart';
import 'package:ciel_mobile/features/settings/presentation/invites_screen.dart';
import 'package:ciel_mobile/features/settings/presentation/settings_screen.dart';
import 'package:ciel_mobile/features/settings/presentation/trust_screen.dart';
import 'package:ciel_mobile/features/shell/presentation/main_shell_screen.dart';
import 'package:ciel_mobile/features/shell/presentation/splash_screen.dart';
import 'package:ciel_mobile/features/stories/presentation/create_story_screen.dart';
import 'package:ciel_mobile/features/stories/presentation/story_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen<AuthState>(authNotifierProvider, (previous, next) {
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
        if (path == '/auth' || path == '/signup') return null;
        return '/auth';
      }

      if (path == '/splash' || path == '/auth' || path == '/signup') {
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
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
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
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['postId']!;
          return PostDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['userId']!;
          return ProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/invites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InvitesScreen(),
      ),
      GoRoute(
        path: '/settings/trust',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TrustScreen(),
      ),
      GoRoute(
        path: '/stories/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/stories/view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! StoryViewerExtra) {
            return const Scaffold(
              body: Center(child: Text('Missing story data')),
            );
          }
          return StoryViewerScreen(extra: extra);
        },
      ),
    ],
  );
});
