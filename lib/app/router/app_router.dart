import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/messages/messages_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/tasks/tasks_page.dart';
import '../../features/splash/splash_page.dart';
import 'route_guard.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final guard = ref.watch(routeGuardProvider);
  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) => guard.redirect(state.matchedLocation),
    routes: [
      GoRoute(path: RouteNames.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: RouteNames.auth, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: RouteNames.register,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(path: RouteNames.home, builder: (_, _) => const HomePage()),
      GoRoute(path: RouteNames.tasks, builder: (_, _) => const TasksPage()),
      GoRoute(
        path: RouteNames.calendar,
        builder: (_, state) => CalendarPage(
          initialDate: DateTime.tryParse(
            state.uri.queryParameters['date'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.messages,
        builder: (_, _) => const MessagesPage(),
      ),
      GoRoute(path: RouteNames.profile, builder: (_, _) => const ProfilePage()),
    ],
  );
});
