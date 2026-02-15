import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/reminders/data/models/reminder_model.dart';
import '../../features/reminders/domain/entities/reminder_entity.dart';

/// Local Cache Service for storing reminders locally
class LocalCacheService {
  static const String _remindersKey = 'cached_reminders';
  static const String _pendingNotificationsKey = 'pending_notifications';
  static const String _lastSyncKey = 'last_sync_timestamp';

  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static Future<LocalCacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalCacheService(prefs);
  }

  // ========== REMINDERS CACHE ==========

  /// Save reminders to local cache
  Future<void> cacheReminders(List<ReminderEntity> reminders) async {
    final List<Map<String, dynamic>> jsonList = reminders
        .map((r) => ReminderModel.fromEntity(r).toLocalCache())
        .toList();
    await _prefs.setString(_remindersKey, jsonEncode(jsonList));
    await _updateLastSync();
  }

  /// Get all cached reminders
  List<ReminderEntity> getCachedReminders() {
    final String? jsonString = _prefs.getString(_remindersKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => ReminderModel.fromLocalCache(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Add or update a single reminder in cache
  Future<void> cacheReminder(ReminderEntity reminder) async {
    final reminders = getCachedReminders();
    final index = reminders.indexWhere((r) => r.reminderId == reminder.reminderId);

    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }

    await cacheReminders(reminders);
  }

  /// Remove a reminder from cache
  Future<void> removeReminderFromCache(String reminderId) async {
    final reminders = getCachedReminders();
    reminders.removeWhere((r) => r.reminderId == reminderId);
    await cacheReminders(reminders);
  }

  /// Get reminders for a specific date
  List<ReminderEntity> getRemindersForDate(DateTime date) {
    final reminders = getCachedReminders();
    return reminders.where((r) {
      return r.scheduledAt.year == date.year &&
          r.scheduledAt.month == date.month &&
          r.scheduledAt.day == date.day;
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get upcoming reminders (not completed, scheduled after now)
  List<ReminderEntity> getUpcomingReminders() {
    final now = DateTime.now();
    final reminders = getCachedReminders();
    return reminders
        .where((r) => !r.isCompleted && r.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get overdue reminders
  List<ReminderEntity> getOverdueReminders() {
    final now = DateTime.now();
    final reminders = getCachedReminders();
    return reminders
        .where((r) => !r.isCompleted && r.scheduledAt.isBefore(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get completed reminders
  List<ReminderEntity> getCompletedReminders() {
    final reminders = getCachedReminders();
    return reminders.where((r) => r.isCompleted).toList()
      ..sort((a, b) => (b.completedAt ?? b.scheduledAt)
          .compareTo(a.completedAt ?? a.scheduledAt));
  }

  // ========== PENDING NOTIFICATIONS ==========

  /// Save pending notification IDs for tracking
  Future<void> savePendingNotification(String reminderId, List<int> notificationIds) async {
    final String? jsonString = _prefs.getString(_pendingNotificationsKey);
    Map<String, dynamic> pending = {};

    if (jsonString != null) {
      pending = Map<String, dynamic>.from(jsonDecode(jsonString));
    }

    pending[reminderId] = notificationIds;
    await _prefs.setString(_pendingNotificationsKey, jsonEncode(pending));
  }

  /// Get pending notification IDs for a reminder
  List<int> getPendingNotificationIds(String reminderId) {
    final String? jsonString = _prefs.getString(_pendingNotificationsKey);
    if (jsonString == null) return [];

    final Map<String, dynamic> pending = jsonDecode(jsonString);
    final ids = pending[reminderId];
    if (ids == null) return [];

    return (ids as List<dynamic>).cast<int>();
  }

  /// Remove pending notification tracking
  Future<void> removePendingNotification(String reminderId) async {
    final String? jsonString = _prefs.getString(_pendingNotificationsKey);
    if (jsonString == null) return;

    final Map<String, dynamic> pending = jsonDecode(jsonString);
    pending.remove(reminderId);
    await _prefs.setString(_pendingNotificationsKey, jsonEncode(pending));
  }

  /// Get all pending notifications map
  Map<String, List<int>> getAllPendingNotifications() {
    final String? jsonString = _prefs.getString(_pendingNotificationsKey);
    if (jsonString == null) return {};

    final Map<String, dynamic> pending = jsonDecode(jsonString);
    return pending.map((key, value) => MapEntry(key, (value as List<dynamic>).cast<int>()));
  }

  // ========== SYNC TRACKING ==========

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _updateLastSync() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _prefs.remove(_remindersKey);
    await _prefs.remove(_pendingNotificationsKey);
    await _prefs.remove(_lastSyncKey);
  }
}

