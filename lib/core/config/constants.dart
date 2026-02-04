/// Core app constants
class AppConstants {
  // App Info
  static const String appName = 'MyReminder';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String remindersCollection = 'reminders';

  // Storage Paths
  static String userStoragePath(String uid) => 'users/$uid/reminders';

  // Notification Channels
  static const String notificationChannelId = 'reminder_channel';
  static const String notificationChannelName = 'Reminders';
  static const String notificationChannelDesc =
      'Reminder notifications with alarm sound';

  // Notification Actions
  static const String actionComplete = 'COMPLETE';
  static const String actionSnooze = 'SNOOZE';
  static const String actionOpen = 'OPEN';

  // Snooze Options (minutes)
  static const List<int> snoozeOptions = [10, 30, 60];
  static const int defaultSnoozeMinutes = 10;

  // Early Reminder Options (minutes)
  static const List<int> earlyReminderOptions = [5, 10, 30, 60];

  // Alarm Sounds
  static const Map<String, String> alarmSounds = {
    'default': 'Default',
    'bell': 'Bell',
    'chime': 'Chime',
    'radar': 'Radar',
  };

  // Date Format
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // Pagination
  static const int pageSize = 20;

  // UI Constants
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// Reminder Status Enums
enum ReminderStatus {
  upcoming,
  overdue,
  completed,
}

/// Priority Levels
enum Priority {
  normal(0),
  high(1);

  final int value;
  const Priority(this.value);

  static Priority fromValue(int value) {
    return Priority.values
        .firstWhere((p) => p.value == value, orElse: () => Priority.normal);
  }
}
