import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/config/theme.dart';
import '../../../../core/config/routes.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/reminder_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  late List<DateTime> _calendarDates;

  @override
  void initState() {
    super.initState();
    _calendarDates = app_date_utils.DateTimeUtils.getCalendarDates();

    // Scroll to today on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      // Sync reminders from Firebase on login
      _syncReminders();
    });
  }

  Future<void> _syncReminders() async {
    await ref.read(reminderNotifierProvider.notifier).syncFromFirebase();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final todayIndex = _calendarDates
        .indexWhere((date) => app_date_utils.DateTimeUtils.isToday(date));
    if (todayIndex != -1) {
      _scrollController.animateTo(
        todayIndex * 70.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(allRemindersProvider);
    final remindersForDate = ref.watch(cachedRemindersForDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyReminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Calendar Strip
          _buildCalendarStrip(),

          const Divider(height: 1),

          // Selected Date Header
          _buildDateHeader(remindersForDate.length),

          // Reminders Timeline
          Expanded(
            child: remindersAsync.when(
              data: (_) => _buildRemindersList(remindersForDate),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading reminders'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _syncReminders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.addReminder);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _calendarDates.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final date = _calendarDates[index];
          final isSelected = app_date_utils.DateTimeUtils.startOfDay(date) ==
              app_date_utils.DateTimeUtils.startOfDay(_selectedDate);
          final isToday = app_date_utils.DateTimeUtils.isToday(date);
          final reminderCount = ref.watch(remindersCountForDateProvider(date));

          return _CalendarDayItem(
            date: date,
            isSelected: isSelected,
            isToday: isToday,
            reminderCount: reminderCount,
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app_date_utils.DateTimeUtils.formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count reminder${count != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
              _scrollToToday();
            },
            tooltip: 'Go to Today',
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(List<ReminderEntity> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add one',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _ReminderCard(
          reminder: reminder,
          onTap: () => _showReminderOptions(reminder),
          onComplete: () => _markAsCompleted(reminder.reminderId),
          onSnooze: () => _showSnoozeOptions(reminder),
        );
      },
    );
  }

  void _showReminderOptions(ReminderEntity reminder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-reminder/${reminder.reminderId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Done'),
              onTap: () {
                Navigator.pop(context);
                _markAsCompleted(reminder.reminderId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('Snooze'),
              onTap: () {
                Navigator.pop(context);
                _showSnoozeOptions(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Change Date/Time'),
              onTap: () {
                Navigator.pop(context);
                _showRescheduleDialog(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteReminder(reminder.reminderId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsCompleted(String reminderId) async {
    await ref.read(reminderNotifierProvider.notifier).markAsCompleted(reminderId);
  }

  Future<void> _deleteReminder(String reminderId) async {
    await ref.read(reminderNotifierProvider.notifier).deleteReminder(reminderId);
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

  Future<void> _showRescheduleDialog(ReminderEntity reminder) async {
    final date = await showDatePicker(
      context: context,
      initialDate: reminder.scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminder.scheduledAt),
    );
    if (time == null) return;

    final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ref.read(reminderNotifierProvider.notifier).rescheduleReminder(reminder.reminderId, newDateTime);
  }
}

class _CalendarDayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final int reminderCount;
  final VoidCallback onTap;

  const _CalendarDayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.reminderCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : isToday
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppTheme.primaryColor
                        : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppTheme.primaryColor
                        : Colors.black,
              ),
            ),
            if (reminderCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$reminderCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              )
            else if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onComplete,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = !reminder.isCompleted && reminder.scheduledAt.isBefore(DateTime.now());
    final timeStr = DateFormat('h:mm a').format(reminder.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: reminder.isCompleted
          ? Colors.grey[100]
          : isOverdue
              ? Colors.red[50]
              : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: reminder.isCompleted
                          ? Colors.grey
                          : isOverdue
                              ? Colors.red
                              : AppTheme.primaryColor,
                    ),
                  ),
                  if (reminder.isUrgent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                        color: reminder.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (reminder.description != null && reminder.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          reminder.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    if (reminder.subtasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.checklist, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${reminder.subtasks.where((s) => s.isDone).length}/${reminder.subtasks.length} subtasks',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    if (reminder.earlyReminderMinutes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.alarm, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${reminder.earlyReminderMinutes}min early',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              if (!reminder.isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.snooze),
                      onPressed: onSnooze,
                      tooltip: 'Snooze',
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: onComplete,
                      tooltip: 'Mark as Done',
                    ),
                  ],
                )
              else
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
