import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reminder_entity.dart';

/// Reminder Model (Data Layer) - extends Entity and adds Firestore serialization
class ReminderModel extends ReminderEntity {
  const ReminderModel({
    required super.reminderId,
    required super.userId,
    required super.title,
    super.description,
    required super.scheduledAt,
    required super.timezone,
    super.isCompleted,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
    super.priority,
    super.colorTag,
    super.earlyReminderMinutes,
    super.alarmSound,
    super.snoozeDefaultMinutes,
    super.images,
    super.subtasks,
    super.notificationIds,
    super.platformMeta,
  });

  /// Convert from Entity
  factory ReminderModel.fromEntity(ReminderEntity entity) {
    return ReminderModel(
      reminderId: entity.reminderId,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      scheduledAt: entity.scheduledAt,
      timezone: entity.timezone,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      priority: entity.priority,
      colorTag: entity.colorTag,
      earlyReminderMinutes: entity.earlyReminderMinutes,
      alarmSound: entity.alarmSound,
      snoozeDefaultMinutes: entity.snoozeDefaultMinutes,
      images: entity.images,
      subtasks: entity.subtasks,
      notificationIds: entity.notificationIds,
      platformMeta: entity.platformMeta,
    );
  }

  /// Convert to Entity
  ReminderEntity toEntity() {
    return ReminderEntity(
      reminderId: reminderId,
      userId: userId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      timezone: timezone,
      isCompleted: isCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      priority: priority,
      colorTag: colorTag,
      earlyReminderMinutes: earlyReminderMinutes,
      alarmSound: alarmSound,
      snoozeDefaultMinutes: snoozeDefaultMinutes,
      images: images,
      subtasks: subtasks,
      notificationIds: notificationIds,
      platformMeta: platformMeta,
    );
  }

  /// Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'reminderId': reminderId,
      'title': title,
      'description': description,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'timezone': timezone,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'priority': priority,
      'colorTag': colorTag,
      'earlyReminderMinutes': earlyReminderMinutes,
      'alarmSound': alarmSound,
      'snoozeDefaultMinutes': snoozeDefaultMinutes,
      'images': images,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'notificationIds': notificationIds,
      'platformMeta': platformMeta,
    };
  }

  /// Create from Firestore Document
  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel.fromMap(data);
  }

  /// Create from Map
  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      reminderId: map['reminderId'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      timezone: map['timezone'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      priority: map['priority'] as int? ?? 0,
      colorTag: map['colorTag'] as String?,
      earlyReminderMinutes: map['earlyReminderMinutes'] as int?,
      alarmSound: map['alarmSound'] as String? ?? 'default',
      snoozeDefaultMinutes: map['snoozeDefaultMinutes'] as int? ?? 10,
      images: (map['images'] as List<dynamic>?)?.cast<String>() ?? [],
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      notificationIds:
          (map['notificationIds'] as List<dynamic>?)?.cast<int>() ?? [],
      platformMeta: map['platformMeta'] as Map<String, dynamic>?,
    );
  }
}
