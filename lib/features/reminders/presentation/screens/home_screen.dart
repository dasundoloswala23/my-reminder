import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    });
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

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Calendar Strip
          _buildCalendarStrip(),

          const Divider(height: 1),

          // Selected Date Header
          _buildDateHeader(),

          // Reminders Timeline
          Expanded(
            child: _buildRemindersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add reminder screen
          // context.push(AppRoutes.addReminder);
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

          return _CalendarDayItem(
            date: date,
            isSelected: isSelected,
            isToday: isToday,
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

  Widget _buildDateHeader() {
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
                  '0 reminders', // TODO: Show actual count
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

  Widget _buildRemindersList() {
    // TODO: Fetch reminders from Firestore for selected date
    // For now, show placeholder
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
}

class _CalendarDayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
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
              DateFormat('E').format(date), // Mon, Tue, etc.
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
              DateFormat('d').format(date), // Day number
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
            if (isToday && !isSelected)
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
