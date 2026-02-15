import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          currentUser.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return _buildProfileSection(context, user.name, user.email);
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),

          // Theme Mode
          ListTile(
            leading: Icon(getThemeModeIcon(themeMode)),
            title: const Text('Theme'),
            subtitle: Text(getThemeModeName(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),

          // Alarm Permission (Android 12+)
          if (Platform.isAndroid)
            _AlarmPermissionTile(),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('Default Alarm Sound'),
            subtitle: const Text('Choose default tone for reminders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/alarm-tones');
            },
          ),

          const Divider(),

          // Account Section
          _buildSectionHeader(context, 'Account'),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to edit profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _showSignOutDialog(context, ref),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About MyReminder'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MyReminder',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.notifications_active, size: 48),
                applicationLegalese: '© 2026 MyReminder. All rights reserved.',
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String name, String email) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            final isSelected = mode == currentMode;
            return ListTile(
              leading: Icon(
                getThemeModeIcon(mode),
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              title: Text(
                getThemeModeName(mode),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Widget to check and toggle alarm permission (Android 12+)
class _AlarmPermissionTile extends StatefulWidget {
  @override
  State<_AlarmPermissionTile> createState() => _AlarmPermissionTileState();
}

class _AlarmPermissionTileState extends State<_AlarmPermissionTile> with WidgetsBindingObserver {
  final _notificationService = NotificationService();
  bool _canScheduleExactAlarms = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission when app resumes (user may have changed it in settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final canSchedule = await _notificationService.canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _canScheduleExactAlarms = canSchedule;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAlarmSettings() async {
    await _notificationService.openExactAlarmSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.alarm),
        title: Text('Alarm Permission'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return ListTile(
      leading: Icon(
        Icons.alarm,
        color: _canScheduleExactAlarms ? Colors.green : Colors.orange,
      ),
      title: const Text('Alarm Permission'),
      subtitle: Text(
        _canScheduleExactAlarms
            ? 'Exact alarms are enabled'
            : 'Tap to enable exact alarms',
      ),
      trailing: Switch(
        value: _canScheduleExactAlarms,
        onChanged: (value) async {
          // Always open settings - user needs to manually toggle
          await _openAlarmSettings();
        },
      ),
      onTap: _openAlarmSettings,
    );
  }
}


