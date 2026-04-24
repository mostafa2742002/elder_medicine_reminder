class TimeFormatter {
  static String formatHour12(int hour24) {
    return formatTime12(hour24, 0);
  }

  static String formatTime12(int hour24, int minute) {
    final period = hour24 < 12 ? 'صباحًا' : 'مساءً';

    var hour12 = hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final minuteText = minute.toString().padLeft(2, '0');

    return '$hour12:$minuteText $period';
  }

  static String formatDateTime12(DateTime dateTime) {
    return formatTime12(dateTime.hour, dateTime.minute);
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