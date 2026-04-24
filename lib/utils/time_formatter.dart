class TimeFormatter {
  static String formatHour12(int hour24) {
    final period = hour24 < 12 ? 'صباحًا' : 'مساءً';

    var hour12 = hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    return '$hour12 $period';
  }
}