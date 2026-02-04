import 'package:intl/intl.dart';

/// Date and Time Utility Functions
class DateTimeUtils {
  /// Check if a date is today (considering timezone)
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is before today
  static bool isBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  /// Check if a date is after today
  static bool isAfterToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }

  /// Check if a datetime is in the past (including time)
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Check if reminder is overdue
  /// - If reminder is today and time has passed and not completed -> overdue
  /// - If reminder is before today and not completed -> overdue
  static bool isOverdue(DateTime scheduledAt, bool isCompleted) {
    if (isCompleted) return false;

    final now = DateTime.now();

    // If scheduled time is in the past, it's overdue
    return scheduledAt.isBefore(now);
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format time to readable string
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format datetime to readable string
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return (to.difference(from).inHours / 24).round();
  }

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inSeconds < 60) {
        return 'Just now';
      } else if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes} min ago';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours} hr ago';
      } else if (absDifference.inDays < 7) {
        return '${absDifference.inDays} days ago';
      } else {
        return formatDate(dateTime);
      }
    } else {
      // Future
      if (difference.inSeconds < 60) {
        return 'In a moment';
      } else if (difference.inMinutes < 60) {
        return 'In ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'In ${difference.inHours} hr';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return formatDate(dateTime);
      }
    }
  }

  /// Get calendar dates for horizontal scroll (30 days before and after)
  static List<DateTime> getCalendarDates({
    DateTime? centerDate,
    int daysBefore = 30,
    int daysAfter = 30,
  }) {
    final center = centerDate ?? DateTime.now();
    final dates = <DateTime>[];

    for (int i = -daysBefore; i <= daysAfter; i++) {
      dates.add(startOfDay(center.add(Duration(days: i))));
    }

    return dates;
  }

  /// Parse time string to DateTime (keeping date, changing time)
  static DateTime parseTime(DateTime date, String timeString) {
    try {
      final format = DateFormat('hh:mm a');
      final time = format.parse(timeString);
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      return date;
    }
  }

  /// Get timezone name
  static String getTimeZone() {
    return DateTime.now().timeZoneName;
  }

  /// Calculate early reminder time
  static DateTime calculateEarlyReminderTime(
      DateTime scheduledAt, int minutesBefore) {
    return scheduledAt.subtract(Duration(minutes: minutesBefore));
  }
}
