import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/onboarding/screens/splash_screen.dart';
import '../../presentation/onboarding/screens/onboarding_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/signup_screen.dart';
import '../../presentation/dashboard/screens/dashboard_screen.dart';
import '../../presentation/shelf_detail/screens/shelf_detail_screen.dart';
import '../../presentation/shelf_detail/screens/add_edit_shelf_screen.dart';
import '../../presentation/shelf_detail/screens/item_history_screen.dart';
import '../../presentation/shelf_detail/screens/add_edit_item_screen.dart';
import '../../presentation/notifications/screens/notifications_screen.dart';
import '../../presentation/profile/screens/profile_screen.dart';
import 'route_transitions.dart';

// Route path constants
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const shelfDetail = '/shelf/:shelfId';
  static const addShelf = '/shelf/add';
  static const editShelf = '/shelf/:shelfId/edit';
  static const addItem = '/shelf/:shelfId/item/add';
  static const editItem = '/shelf/:shelfId/item/:itemId/edit';
  static const itemHistory = '/shelf/:shelfId/item/:itemId/history';
  static const notifications = '/notifications';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final path = state.fullPath;

      // Splash runs its own navigation logic — never redirect it.
      if (path == AppRoutes.splash) return null;

      final isAuthScreen = path == AppRoutes.onboarding ||
          path == AppRoutes.login ||
          path == AppRoutes.signup;

      // Logged-in users who somehow end up on auth screens go home.
      if (isLoggedIn && isAuthScreen) return AppRoutes.dashboard;

      // Guests trying to access protected screens go to login.
      if (!isLoggedIn && !isAuthScreen) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (ctx, state) => _slide(const SplashScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (ctx, state) => _fade(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (ctx, state) => _slide(const LoginScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (ctx, state) => _slide(const SignupScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (ctx, state) => _fade(const DashboardScreen(), state),
      ),
      GoRoute(
        path: '/shelf/add',
        pageBuilder: (ctx, state) =>
            _bottomSheet(const AddEditShelfScreen(), state),
      ),
      GoRoute(
        path: '/shelf/:shelfId',
        pageBuilder: (ctx, state) {
          final shelfId = state.pathParameters['shelfId']!;
          final shelfName =
              state.extra != null ? (state.extra as Map)['name'] as String? : null;
          return _slide(
            ShelfDetailScreen(shelfId: shelfId, shelfName: shelfName),
            state,
          );
        },
      ),
      GoRoute(
        path: '/shelf/:shelfId/edit',
        pageBuilder: (ctx, state) {
          final shelfId = state.pathParameters['shelfId']!;
          return _bottomSheet(
            AddEditShelfScreen(shelfId: shelfId),
            state,
          );
        },
      ),
      GoRoute(
        path: '/shelf/:shelfId/item/add',
        pageBuilder: (ctx, state) {
          final shelfId = state.pathParameters['shelfId']!;
          return _bottomSheet(AddEditItemScreen(shelfId: shelfId), state);
        },
      ),
      GoRoute(
        path: '/shelf/:shelfId/item/:itemId/edit',
        pageBuilder: (ctx, state) {
          final shelfId = state.pathParameters['shelfId']!;
          final itemId = state.pathParameters['itemId']!;
          return _bottomSheet(
            AddEditItemScreen(shelfId: shelfId, itemId: itemId),
            state,
          );
        },
      ),
      GoRoute(
        path: '/shelf/:shelfId/item/:itemId/history',
        pageBuilder: (ctx, state) {
          final itemId = state.pathParameters['itemId']!;
          final itemName =
              state.extra != null ? (state.extra as Map)['name'] as String? : null;
          return _slide(
            ItemHistoryScreen(itemId: itemId, itemName: itemName),
            state,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (ctx, state) =>
            _slide(const NotificationsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (ctx, state) => _slide(const ProfileScreen(), state),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found\n${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});

Page<void> _slide(Widget child, GoRouterState state) =>
    RouteTransitions.slide(child: child, key: state.pageKey);

Page<void> _fade(Widget child, GoRouterState state) =>
    RouteTransitions.fade(child: child, key: state.pageKey);

Page<void> _bottomSheet(Widget child, GoRouterState state) =>
    RouteTransitions.bottomSheet(child: child, key: state.pageKey);
