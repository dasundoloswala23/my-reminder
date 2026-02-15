import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/reminder_provider.dart';
import '../../../../core/config/routes.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  ConsumerState<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final reminderAsync = ref.watch(reminderByIdProvider(widget.reminderId));

    return reminderAsync.when(
      data: (reminder) {
        if (reminder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reminder')),
            body: const Center(child: Text('Reminder not found')),
          );
        }
        return _buildContent(reminder);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(ReminderEntity reminder) {
    final isOverdue = !reminder.isCompleted && reminder.scheduledAt.isBefore(DateTime.now());
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(reminder.scheduledAt);
    final timeStr = DateFormat('h:mm a').format(reminder.scheduledAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/edit-reminder/${reminder.reminderId}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(reminder),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Badge
            if (reminder.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Overdue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Title
            Text(
              reminder.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),

            // Urgent Badge
            if (reminder.isUrgent)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('URGENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

            // Date & Time Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: isOverdue ? Colors.red : null),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 16,
                              color: isOverdue ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: isOverdue ? Colors.red : null),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 16,
                              color: isOverdue ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (reminder.earlyReminderMinutes != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Early reminder: ${reminder.earlyReminderMinutes} min before',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (reminder.description != null && reminder.description!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(reminder.description!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subtasks
            if (reminder.subtasks.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${reminder.subtasks.where((s) => s.isDone).length}/${reminder.subtasks.length}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...reminder.subtasks.map((subtask) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          subtask.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                          color: subtask.isDone ? Colors.green : null,
                        ),
                        title: Text(
                          subtask.text,
                          style: TextStyle(
                            decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                            color: subtask.isDone ? Colors.grey : null,
                          ),
                        ),
                        onTap: () => _toggleSubtask(reminder, subtask.id),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Images
            if (reminder.images.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Images', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reminder.images.map((url) => GestureDetector(
                          onTap: () => _showFullImage(url),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (!reminder.isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSnoozeOptions(reminder),
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsCompleted(reminder.reminderId),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Done'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSubtask(ReminderEntity reminder, String subtaskId) {
    final subtask = reminder.subtasks.firstWhere((s) => s.id == subtaskId);
    ref.read(reminderNotifierProvider.notifier).updateSubtask(
      reminder,
      subtaskId,
      !subtask.isDone,
    );
  }

  Future<void> _markAsCompleted(String reminderId) async {
    await ref.read(reminderNotifierProvider.notifier).markAsCompleted(reminderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder marked as completed')),
      );
    }
  }

  void _showSnoozeOptions(ReminderEntity reminder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Snooze for', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('10 minutes'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reminderNotifierProvider.notifier).snoozeReminder(reminder.reminderId, 10);
              },
            ),
            ListTile(
              title: const Text('30 minutes'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reminderNotifierProvider.notifier).snoozeReminder(reminder.reminderId, 30);
              },
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                ref.read(reminderNotifierProvider.notifier).snoozeReminder(reminder.reminderId, 60);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ReminderEntity reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(reminderNotifierProvider.notifier).deleteReminder(reminder.reminderId);
              if (context.mounted) {
                context.go(AppRoutes.home);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.network(url, fit: BoxFit.contain),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
