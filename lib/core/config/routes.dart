import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/reminders/presentation/screens/home_screen.dart';
import '../../features/reminders/presentation/screens/add_edit_reminder_screen.dart';
import '../../features/reminders/presentation/screens/reminder_detail_screen.dart';

/// App Routes Configuration using GoRouter
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String addReminder = '/add-reminder';
  static const String editReminder = '/edit-reminder/:id';
  static const String reminderDetail = '/reminder/:id';

  static GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      // Auth Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home Route
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Add Reminder Route
      GoRoute(
        path: addReminder,
        name: 'addReminder',
        builder: (context, state) => const AddEditReminderScreen(),
      ),

      // Edit Reminder Route
      GoRoute(
        path: editReminder,
        name: 'editReminder',
        builder: (context, state) {
          final reminderId = state.pathParameters['id']!;
          return AddEditReminderScreen(reminderId: reminderId);
        },
      ),

      // Reminder Detail Route (for deep linking from notifications/widgets)
      GoRoute(
        path: reminderDetail,
        name: 'reminderDetail',
        builder: (context, state) {
          final reminderId = state.pathParameters['id']!;
          return ReminderDetailScreen(reminderId: reminderId);
        },
      ),
    ],

    // Redirect logic for authentication
    redirect: (context, state) {
      // TODO: Implement auth state check
      // For now, allow all routes
      return null;
    },

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
