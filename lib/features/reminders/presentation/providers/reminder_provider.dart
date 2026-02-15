import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/entities/reminder_entity.dart';

/// Local Cache Service Provider
final localCacheServiceProvider = FutureProvider<LocalCacheService>((ref) async {
  return LocalCacheService.create();
});

/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Reminder Repository Provider
final reminderRepositoryProvider = FutureProvider<ReminderRepository>((ref) async {
  final cacheService = await ref.watch(localCacheServiceProvider.future);
  final notificationService = ref.watch(notificationServiceProvider);
  return ReminderRepositoryImpl(
    cacheService: cacheService,
    notificationService: notificationService,
  );
});

/// Selected Date Provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Reminders for Selected Date Provider
final remindersForDateProvider = FutureProvider.family<List<ReminderEntity>, DateTime>((ref, date) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final repository = await ref.watch(reminderRepositoryProvider.future);
  return repository.getRemindersForDate(user.uid, date);
});

/// All Reminders Provider (Real-time stream from Firebase)
final allRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    yield [];
    return;
  }

  final repository = await ref.read(reminderRepositoryProvider.future);
  yield* repository.watchReminders(user.uid);
});

/// Cached Reminders for Date Provider (offline-first)
final cachedRemindersForDateProvider = Provider.family<List<ReminderEntity>, DateTime>((ref, date) {
  final allReminders = ref.watch(allRemindersProvider);
  return allReminders.when(
    data: (reminders) {
      return reminders.where((r) {
        return r.scheduledAt.year == date.year &&
            r.scheduledAt.month == date.month &&
            r.scheduledAt.day == date.day;
      }).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Upcoming Reminders Provider
final upcomingRemindersProvider = Provider<List<ReminderEntity>>((ref) {
  final allReminders = ref.watch(allRemindersProvider);
  final now = DateTime.now();
  return allReminders.when(
    data: (reminders) {
      return reminders
          .where((r) => !r.isCompleted && r.scheduledAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Overdue Reminders Provider
final overdueRemindersProvider = Provider<List<ReminderEntity>>((ref) {
  final allReminders = ref.watch(allRemindersProvider);
  final now = DateTime.now();
  return allReminders.when(
    data: (reminders) {
      return reminders
          .where((r) => !r.isCompleted && r.scheduledAt.isBefore(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Completed Reminders Provider
final completedRemindersProvider = Provider<List<ReminderEntity>>((ref) {
  final allReminders = ref.watch(allRemindersProvider);
  return allReminders.when(
    data: (reminders) {
      return reminders.where((r) => r.isCompleted).toList()
        ..sort((a, b) => (b.completedAt ?? b.scheduledAt)
            .compareTo(a.completedAt ?? a.scheduledAt));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Reminder Notifier for managing reminder actions
class ReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ReminderNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<ReminderEntity?> createReminder({
    required String title,
    String? description,
    required DateTime scheduledAt,
    int? earlyReminderMinutes,
    String alarmSound = 'default',
    bool isUrgent = false,
    List<Subtask> subtasks = const [],
    String? colorTag,
    int priority = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      final now = DateTime.now();
      final reminder = ReminderEntity(
        reminderId: const Uuid().v4(),
        userId: user.uid,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        timezone: DateTime.now().timeZoneName,
        createdAt: now,
        updatedAt: now,
        earlyReminderMinutes: earlyReminderMinutes,
        alarmSound: alarmSound,
        isUrgent: isUrgent,
        subtasks: subtasks,
        colorTag: colorTag,
        priority: priority,
      );

      final created = await repository.createReminder(reminder);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateReminder(ReminderEntity reminder) async {
    state = const AsyncValue.loading();
    try {
      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.updateReminder(reminder);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.deleteReminder(user.uid, reminderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsCompleted(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.markAsCompleted(user.uid, reminderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> snoozeReminder(String reminderId, int minutes) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.snoozeReminder(user.uid, reminderId, minutes);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rescheduleReminder(String reminderId, DateTime newDateTime) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.rescheduleReminder(user.uid, reminderId, newDateTime);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSubtask(ReminderEntity reminder, String subtaskId, bool isDone) async {
    final updatedSubtasks = reminder.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isDone: isDone);
      }
      return s;
    }).toList();

    await updateReminder(reminder.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> syncFromFirebase() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) throw Exception('User not logged in');

      final repository = await _ref.read(reminderRepositoryProvider.future);
      await repository.syncFromFirebase(user.uid);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Reminder Notifier Provider
final reminderNotifierProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<void>>((ref) {
  return ReminderNotifier(ref);
});

/// Single Reminder Provider
final reminderByIdProvider = FutureProvider.family<ReminderEntity?, String>((ref, reminderId) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final repository = await ref.watch(reminderRepositoryProvider.future);
  return repository.getReminderById(user.uid, reminderId);
});

/// Reminders Count for Date Provider (for calendar indicators)
final remindersCountForDateProvider = Provider.family<int, DateTime>((ref, date) {
  final allReminders = ref.watch(allRemindersProvider);
  return allReminders.when(
    data: (reminders) {
      return reminders.where((r) {
        return r.scheduledAt.year == date.year &&
            r.scheduledAt.month == date.month &&
            r.scheduledAt.day == date.day;
      }).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

