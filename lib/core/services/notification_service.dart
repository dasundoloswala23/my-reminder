import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as android_notifications;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../features/reminders/domain/entities/reminder_entity.dart';
import '../config/constants.dart' as app_constants;

/// NOTIFICATION SERVICE
/// Handles scheduling and managing notifications for both Android and iOS.
///
/// ANDROID STRATEGY:
/// - Uses AlarmManager for exact alarm scheduling
/// - Full-screen intent for alarm-style notifications
/// - Custom notification actions: Complete, Snooze, Open
///
/// iOS STRATEGY:
/// - Uses UNUserNotificationCenter for scheduled notifications
/// - Custom sound support
/// - Notification category actions: Complete, Snooze, Open
/// - Note: iOS does not support true "ringing alarm" after app kill due to OS restrictions
/// - Best practice: Use Critical Alerts entitlement if available, custom sounds, and repeated notifications
///
/// LIMITATION NOTE (HARDWARE BUTTONS):
/// - Both iOS and Android restrict detecting hardware button presses (power/volume) in background
/// - This is an OS security feature and cannot be reliably bypassed
/// - Solution: Provide notification actions for user interaction

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'reminder_category',
          actions: [
            DarwinNotificationAction.plain(
              'complete',
              'Complete',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'snooze',
              'Snooze',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request exact alarm permission for Android 12+
        await androidPlugin.requestExactAlarmsPermission();

        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical:
              true, // Request critical alerts if available (requires entitlement)
        );
        return granted ?? false;
      }
      return false;
    }
    return true;
  }

  /// Schedule reminder notification
  /// Creates notifications for both main time and early reminder time (if set)
  Future<List<int>> scheduleReminder(ReminderEntity reminder) async {
    final notificationIds = <int>[];

    // Schedule main notification
    final mainId = await _scheduleNotification(
      id: reminder.reminderId.hashCode,
      title: reminder.title,
      body: reminder.description ?? 'Reminder scheduled',
      scheduledTime: reminder.scheduledAt,
      payload: reminder.reminderId,
      sound: reminder.alarmSound,
    );
    notificationIds.add(mainId);

    // Schedule early reminder notification if set
    if (reminder.earlyReminderMinutes != null &&
        reminder.earlyReminderMinutes! > 0) {
      final earlyTime = reminder.scheduledAt.subtract(
        Duration(minutes: reminder.earlyReminderMinutes!),
      );

      // Only schedule if early time is in the future
      if (earlyTime.isAfter(DateTime.now())) {
        final earlyId = await _scheduleNotification(
          id: (reminder.reminderId.hashCode + 1),
          title: '🔔 Upcoming: ${reminder.title}',
          body: 'Reminder in ${reminder.earlyReminderMinutes} minutes',
          scheduledTime: earlyTime,
          payload: reminder.reminderId,
          sound: 'default', // Use softer sound for early reminder
        );
        notificationIds.add(earlyId);
      }
    }

    return notificationIds;
  }

  /// Internal method to schedule a single notification
  Future<int> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String sound,
  }) async {
    // Convert to timezone-aware datetime
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      app_constants.AppConstants.notificationChannelId,
      app_constants.AppConstants.notificationChannelName,
      channelDescription: app_constants.AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: android_notifications.Priority.high,
      sound: RawResourceAndroidNotificationSound(_getSoundFileName(sound)),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFF6366F1),
      icon: '@mipmap/ic_launcher',
      // Full-screen intent for alarm-style notification (Android)
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        const AndroidNotificationAction(
          'complete',
          'Complete',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze',
          showsUserInterface: true,
        ),
      ],
    );

    // iOS notification details
    final iosDetails = DarwinNotificationDetails(
      sound: '$sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'reminder_category',
      threadIdentifier: payload,
      interruptionLevel: InterruptionLevel.critical, // iOS 15+ critical alerts
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule notification
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    return id;
  }

  /// Schedule snooze notification
  Future<int> scheduleSnooze({
    required String reminderId,
    required String title,
    required int snoozeMinutes,
  }) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));

    return await _scheduleNotification(
      id: reminderId.hashCode + DateTime.now().millisecondsSinceEpoch,
      title: '⏰ Snoozed: $title',
      body: 'Reminder snoozed for $snoozeMinutes minutes',
      scheduledTime: snoozeTime,
      payload: reminderId,
      sound: 'default',
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications for a reminder
  Future<void> cancelReminderNotifications(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await cancelNotification(id);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show immediate notification (for testing or instant alerts)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      app_constants.AppConstants.notificationChannelId,
      app_constants.AppConstants.notificationChannelName,
      channelDescription: app_constants.AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: android_notifications.Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, platformDetails,
        payload: payload);
  }

  // Handlers

  /// Handle notification tap (when app is in foreground/background)
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    // TODO: Handle navigation based on action
    // Navigate to reminder detail screen with reminderId = payload
    // print('Notification tapped: payload=$payload, action=$actionId');
  }

  /// Handle notification tap (when app is terminated)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    _onNotificationTapped(response);
  }

  /// Get sound file name without extension
  String _getSoundFileName(String sound) {
    final soundMap = {
      'default': 'default_sound',
      'bell': 'bell_sound',
      'chime': 'chime_sound',
      'radar': 'radar_sound',
    };
    return soundMap[sound] ?? 'default_sound';
  }
}
