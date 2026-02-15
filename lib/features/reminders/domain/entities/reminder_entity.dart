import 'package:equatable/equatable.dart';

/// Subtask Entity
class Subtask extends Equatable {
  final String id;
  final String text;
  final bool isDone;

  const Subtask({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Subtask copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return Subtask(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      text: map['text'] as String,
      isDone: map['isDone'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, text, isDone];
}

/// Reminder Entity (Domain Layer)
class ReminderEntity extends Equatable {
  final String reminderId;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final String timezone;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int priority; // 0 = normal, 1 = high
  final String? colorTag;
  final int? earlyReminderMinutes;
  final String alarmSound;
  final int snoozeDefaultMinutes;
  final List<String> images;
  final List<Subtask> subtasks;
  final List<int> notificationIds;
  final Map<String, dynamic>? platformMeta;
  final bool isUrgent; // true = show as alarm, false = show as notification

  const ReminderEntity({
    required this.reminderId,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.timezone,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 0,
    this.colorTag,
    this.earlyReminderMinutes,
    this.alarmSound = 'default',
    this.snoozeDefaultMinutes = 10,
    this.images = const [],
    this.subtasks = const [],
    this.notificationIds = const [],
    this.platformMeta,
    this.isUrgent = false,
  });

  ReminderEntity copyWith({
    String? reminderId,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    String? timezone,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? priority,
    String? colorTag,
    int? earlyReminderMinutes,
    String? alarmSound,
    int? snoozeDefaultMinutes,
    List<String>? images,
    List<Subtask>? subtasks,
    List<int>? notificationIds,
    Map<String, dynamic>? platformMeta,
    bool? isUrgent,
  }) {
    return ReminderEntity(
      reminderId: reminderId ?? this.reminderId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timezone: timezone ?? this.timezone,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      colorTag: colorTag ?? this.colorTag,
      earlyReminderMinutes: earlyReminderMinutes ?? this.earlyReminderMinutes,
      alarmSound: alarmSound ?? this.alarmSound,
      snoozeDefaultMinutes: snoozeDefaultMinutes ?? this.snoozeDefaultMinutes,
      images: images ?? this.images,
      subtasks: subtasks ?? this.subtasks,
      notificationIds: notificationIds ?? this.notificationIds,
      platformMeta: platformMeta ?? this.platformMeta,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  @override
  List<Object?> get props => [
        reminderId,
        userId,
        title,
        description,
        scheduledAt,
        timezone,
        isCompleted,
        completedAt,
        createdAt,
        updatedAt,
        priority,
        colorTag,
        earlyReminderMinutes,
        alarmSound,
        snoozeDefaultMinutes,
        images,
        subtasks,
        notificationIds,
        platformMeta,
        isUrgent,
      ];
}
