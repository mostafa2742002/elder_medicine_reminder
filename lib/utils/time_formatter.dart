class TimeFormatter {
  static String formatHour12(int hour24) {
    final period = hour24 < 12 ? 'صباحًا' : 'مساءً';

    var hour12 = hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    return '$hour12 $period';
  }

  static String formatDateTime12(DateTime dateTime) {
    final period = dateTime.hour < 12 ? 'صباحًا' : 'مساءً';

    var hour12 = dateTime.hour % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour12:$minute $period';
  }

  static String formatArabicDateLabel(DateTime dateTime) {
    final now = DateTime.now();

    if (_isSameDay(dateTime, now)) {
      return 'اليوم';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(dateTime, yesterday)) {
      return 'أمس';
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    return '$day/$month/$year';
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}