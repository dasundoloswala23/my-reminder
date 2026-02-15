import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/reminder_model.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/notification_service.dart';

/// Abstract Reminder Repository interface
abstract class ReminderRepository {
  Future<List<ReminderEntity>> getReminders(String userId);
  Future<ReminderEntity?> getReminderById(String userId, String reminderId);
  Future<ReminderEntity> createReminder(ReminderEntity reminder);
  Future<ReminderEntity> updateReminder(ReminderEntity reminder);
  Future<void> deleteReminder(String userId, String reminderId);
  Future<void> markAsCompleted(String userId, String reminderId);
  Future<void> snoozeReminder(String userId, String reminderId, int minutes);
  Future<void> rescheduleReminder(String userId, String reminderId, DateTime newDateTime);
  Future<List<ReminderEntity>> getRemindersForDate(String userId, DateTime date);
  Future<void> syncFromFirebase(String userId);
  Stream<List<ReminderEntity>> watchReminders(String userId);
  List<ReminderEntity> getCachedRemindersForDate(DateTime date);
}

/// Reminder Repository Implementation
class ReminderRepositoryImpl implements ReminderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LocalCacheService _cacheService;
  final NotificationService _notificationService;

  ReminderRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required LocalCacheService cacheService,
    required NotificationService notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _cacheService = cacheService,
        _notificationService = notificationService;

  CollectionReference<Map<String, dynamic>> _remindersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  @override
  Future<List<ReminderEntity>> getReminders(String userId) async {
    final snapshot = await _remindersCollection(userId)
        .orderBy('scheduledAt', descending: false)
        .get();

    final reminders = snapshot.docs
        .map((doc) => ReminderModel.fromFirestore(doc).toEntity())
        .toList();

    // Cache reminders locally
    await _cacheService.cacheReminders(reminders);

    return reminders;
  }

  @override
  Future<ReminderEntity?> getReminderById(String userId, String reminderId) async {
    final doc = await _remindersCollection(userId).doc(reminderId).get();
    if (!doc.exists) return null;
    return ReminderModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<ReminderEntity> createReminder(ReminderEntity reminder) async {
    final model = ReminderModel.fromEntity(reminder);

    // Save to Firestore
    await _remindersCollection(reminder.userId).doc(reminder.reminderId).set(model.toFirestore());

    // Schedule notifications
    final notificationIds = await _scheduleNotifications(reminder);

    // Update reminder with notification IDs
    final updatedReminder = reminder.copyWith(notificationIds: notificationIds);

    await _remindersCollection(reminder.userId)
        .doc(reminder.reminderId)
        .update({'notificationIds': notificationIds});

    // Cache locally
    await _cacheService.cacheReminder(updatedReminder);
    await _cacheService.savePendingNotification(reminder.reminderId, notificationIds);

    return updatedReminder;
  }

  @override
  Future<ReminderEntity> updateReminder(ReminderEntity reminder) async {
    // Cancel existing notifications
    final existingIds = _cacheService.getPendingNotificationIds(reminder.reminderId);
    await _notificationService.cancelReminderNotifications(existingIds);

    // Schedule new notifications if not completed
    List<int> notificationIds = [];
    if (!reminder.isCompleted && reminder.scheduledAt.isAfter(DateTime.now())) {
      notificationIds = await _scheduleNotifications(reminder);
    }

    final updatedReminder = reminder.copyWith(
      notificationIds: notificationIds,
      updatedAt: DateTime.now(),
    );
    final model = ReminderModel.fromEntity(updatedReminder);

    // Update in Firestore
    await _remindersCollection(reminder.userId)
        .doc(reminder.reminderId)
        .update(model.toFirestore());

    // Update local cache
    await _cacheService.cacheReminder(updatedReminder);
    await _cacheService.savePendingNotification(reminder.reminderId, notificationIds);

    return updatedReminder;
  }

  @override
  Future<void> deleteReminder(String userId, String reminderId) async {
    // Cancel notifications
    final notificationIds = _cacheService.getPendingNotificationIds(reminderId);
    await _notificationService.cancelReminderNotifications(notificationIds);

    // Delete from Firestore
    await _remindersCollection(userId).doc(reminderId).delete();

    // Delete associated images from Storage
    try {
      final storageRef = _storage.ref().child('users/$userId/reminders/$reminderId');
      final items = await storageRef.listAll();
      for (final item in items.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignore storage errors
    }

    // Remove from cache
    await _cacheService.removeReminderFromCache(reminderId);
    await _cacheService.removePendingNotification(reminderId);
  }

  @override
  Future<void> markAsCompleted(String userId, String reminderId) async {
    // Cancel notifications
    final notificationIds = _cacheService.getPendingNotificationIds(reminderId);
    await _notificationService.cancelReminderNotifications(notificationIds);

    final now = DateTime.now();

    // Update in Firestore
    await _remindersCollection(userId).doc(reminderId).update({
      'isCompleted': true,
      'completedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'notificationIds': [],
    });

    // Update cache
    final cachedReminders = _cacheService.getCachedReminders();
    final index = cachedReminders.indexWhere((r) => r.reminderId == reminderId);
    if (index >= 0) {
      final cachedReminder = cachedReminders[index];
      final updated = cachedReminder.copyWith(
        isCompleted: true,
        completedAt: now,
        updatedAt: now,
        notificationIds: [],
      );
      await _cacheService.cacheReminder(updated);
    }

    await _cacheService.removePendingNotification(reminderId);
  }

  @override
  Future<void> snoozeReminder(String userId, String reminderId, int minutes) async {
    final reminder = await getReminderById(userId, reminderId);
    if (reminder == null) return;

    final newTime = DateTime.now().add(Duration(minutes: minutes));
    await rescheduleReminder(userId, reminderId, newTime);
  }

  @override
  Future<void> rescheduleReminder(String userId, String reminderId, DateTime newDateTime) async {
    final reminder = await getReminderById(userId, reminderId);
    if (reminder == null) return;

    final updatedReminder = reminder.copyWith(
      scheduledAt: newDateTime,
      isCompleted: false,
      completedAt: null,
    );

    await updateReminder(updatedReminder);
  }

  @override
  Future<List<ReminderEntity>> getRemindersForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _remindersCollection(userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Future<void> syncFromFirebase(String userId) async {
    // Fetch all reminders from Firebase
    final reminders = await getReminders(userId);

    // Cache all reminders
    await _cacheService.cacheReminders(reminders);

    // Re-schedule notifications for upcoming reminders
    final now = DateTime.now();
    for (final reminder in reminders) {
      if (!reminder.isCompleted && reminder.scheduledAt.isAfter(now)) {
        final notificationIds = await _scheduleNotifications(reminder);
        await _cacheService.savePendingNotification(reminder.reminderId, notificationIds);
      }
    }
  }

  @override
  Stream<List<ReminderEntity>> watchReminders(String userId) {
    return _remindersCollection(userId)
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final reminders = snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc).toEntity())
              .toList();

          // Update cache
          _cacheService.cacheReminders(reminders);

          return reminders;
        });
  }

  @override
  List<ReminderEntity> getCachedRemindersForDate(DateTime date) {
    return _cacheService.getRemindersForDate(date);
  }

  Future<List<int>> _scheduleNotifications(ReminderEntity reminder) async {
    return await _notificationService.scheduleReminder(reminder);
  }

  /// Upload image and return URL
  Future<String> uploadImage(String userId, String reminderId, File imageFile) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$userId/reminders/$reminderId/$fileName');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors
    }
  }
}

