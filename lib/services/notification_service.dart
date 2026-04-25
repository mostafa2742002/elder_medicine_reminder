import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';

typedef NotificationTapHandler = void Function(String? payload);

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _medicineChannelId = 'medicine_reminders';
  static const String _medicineChannelName = 'تذكير الدواء';
  static const String _medicineChannelDescription =
      'تنبيهات مواعيد الدواء اليومية';

  static const String _urgentMedicineChannelId = 'urgent_medicine_reminders';
  static const String _urgentMedicineChannelName = 'تنبيه آخر ساعة للدواء';
  static const String _urgentMedicineChannelDescription =
      'تنبيهات مهمة عند بداية آخر ساعة من وقت الدواء';

  static const String _appShortcutChannelId = 'app_shortcut_v2';
  static const String _appShortcutChannelName = 'اختصار فتح التطبيق';
  static const String _appShortcutChannelDescription =
      'تنبيه ثابت وواضح يساعد المستخدم على فتح التطبيق بسرعة';

  static const int _appShortcutNotificationId = 777777;

  static bool _wasAppLaunchedByNotification = false;
  static String? _launchNotificationPayload;

  static bool get wasAppLaunchedByNotification {
    return _wasAppLaunchedByNotification;
  }

  static String? get launchNotificationPayload {
    return _launchNotificationPayload;
  }

  static Future<void> initialize({
    NotificationTapHandler? onNotificationTap,
  }) async {
    if (kIsWeb) {
      return;
    }

    timezone_data.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) {
        onNotificationTap?.call(notificationResponse.payload);
      },
    );

    await _checkIfAppWasLaunchedByNotification();
    await _requestAndroidNotificationPermissions();
  }

  static Future<void> showPinnedAppShortcutNotification() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin.show(
      id: _appShortcutNotificationId,
      title: 'تذكير الدواء',
      body: 'اضغط هنا لفتح التطبيق ومتابعة الدواء بسهولة',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _appShortcutChannelId,
          _appShortcutChannelName,
          channelDescription: _appShortcutChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.status,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(
            'اضغط هنا لفتح التطبيق بسرعة.\n\n'
            'يمكنك متابعة الدواء الحالي، سماع الرسالة الصوتية، '
            'والضغط على زر "أخذت الدواء" بسهولة.',
            contentTitle: 'تذكير الدواء',
            summaryText: 'اختصار دائم لفتح التطبيق',
          ),
        ),
      ),
      payload: 'open_app_shortcut',
    );
  }

  static Future<void> cancelPinnedAppShortcutNotification() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin.cancel(
      id: _appShortcutNotificationId,
    );
  }

  static Future<void> scheduleAllMedicineNotifications() async {
    if (kIsWeb) {
      return;
    }

    final medicineRepository = MedicineRepository();
    final medicines = medicineRepository.findAll();

    await cancelAllMedicineNotifications();

    for (final medicine in medicines) {
      await scheduleDailyMedicineNotification(medicine);
      await scheduleUrgentFinalHourNotification(medicine);
    }
  }

  static Future<void> scheduleDailyMedicineNotification(
    Medicine medicine,
  ) async {
    if (kIsWeb) {
      return;
    }

    final notificationId = _createNotificationId(
      '${medicine.id}-normal',
    );

    final scheduledDate = _nextInstanceOfTime(
      medicine.startHour,
      medicine.startMinute,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'حان وقت الدواء',
        body: '${medicine.name} - ${medicine.dosage}',
        scheduledDate: scheduledDate,
        notificationDetails: _buildMedicineNotificationDetails(
          fullScreenIntent: true,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    } on PlatformException {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'حان وقت الدواء',
        body: '${medicine.name} - ${medicine.dosage}',
        scheduledDate: scheduledDate,
        notificationDetails: _buildMedicineNotificationDetails(
          fullScreenIntent: true,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    }
  }

  static Future<void> scheduleUrgentFinalHourNotification(
    Medicine medicine,
  ) async {
    if (kIsWeb) {
      return;
    }

    final finalHourAlertTime = _calculateFinalHourAlertTime(medicine);

    if (finalHourAlertTime == null) {
      return;
    }

    final notificationId = _createNotificationId(
      '${medicine.id}-urgent-final-hour',
    );

    final scheduledDate = _nextInstanceOfTime(
      finalHourAlertTime.hour,
      finalHourAlertTime.minute,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'تنبيه مهم: آخر ساعة للدواء',
        body: '${medicine.name} - اضغط هنا لأخذ الدواء الآن',
        scheduledDate: scheduledDate,
        notificationDetails: _buildUrgentMedicineNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    } on PlatformException {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'تنبيه مهم: آخر ساعة للدواء',
        body: '${medicine.name} - اضغط هنا لأخذ الدواء الآن',
        scheduledDate: scheduledDate,
        notificationDetails: _buildUrgentMedicineNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    }
  }

  static Future<void> cancelAllMedicineNotifications() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin.cancelAll();
    await showPinnedAppShortcutNotification();
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin.show(
      id: 999999,
      title: 'اختبار التنبيه',
      body: 'إذا ظهرت هذه الرسالة، فالتنبيهات تعمل بنجاح.',
      notificationDetails: _buildMedicineNotificationDetails(
        fullScreenIntent: false,
      ),
      payload: 'test_notification',
    );
  }

  static NotificationDetails _buildMedicineNotificationDetails({
    required bool fullScreenIntent,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _medicineChannelId,
        _medicineChannelName,
        channelDescription: _medicineChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: fullScreenIntent,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  static NotificationDetails _buildUrgentMedicineNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _urgentMedicineChannelId,
        _urgentMedicineChannelName,
        channelDescription: _urgentMedicineChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        ticker: 'آخر ساعة للدواء',
        styleInformation: BigTextStyleInformation(
          'هذا تنبيه مهم لأننا دخلنا في آخر ساعة من وقت الدواء.\n\n'
          'اضغط هنا لفتح التطبيق، مشاهدة صورة الدواء، سماع الرسالة الصوتية، '
          'ثم اضغط زر "أخذت الدواء".',
          contentTitle: 'تنبيه مهم: آخر ساعة للدواء',
          summaryText: 'يرجى أخذ الدواء الآن',
        ),
      ),
    );
  }

  static _MedicineAlertTime? _calculateFinalHourAlertTime(Medicine medicine) {
    final startTotalMinutes = _toMinutes(
      medicine.startHour,
      medicine.startMinute,
    );

    final endTotalMinutes = _toMinutes(
      medicine.endHour,
      medicine.endMinute,
    );

    final rangeDurationMinutes = endTotalMinutes - startTotalMinutes;

    if (rangeDurationMinutes <= 60) {
      return null;
    }

    final finalHourStartMinutes = endTotalMinutes - 60;

    return _MedicineAlertTime(
      hour: finalHourStartMinutes ~/ 60,
      minute: finalHourStartMinutes % 60,
    );
  }

  static int _toMinutes(int hour, int minute) {
    return (hour * 60) + minute;
  }

  static Future<void> _requestAndroidNotificationPermissions() async {
    if (!Platform.isAndroid) {
      return;
    }

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> _checkIfAppWasLaunchedByNotification() async {
    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();

    _wasAppLaunchedByNotification =
        launchDetails?.didNotificationLaunchApp ?? false;

    _launchNotificationPayload =
        launchDetails?.notificationResponse?.payload;
  }

  static timezone.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = timezone.TZDateTime.now(timezone.local);

    var scheduledDate = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static int _createNotificationId(String medicineId) {
    return medicineId.hashCode.abs() % 2147483647;
  }

  static Future<void> _configureLocalTimezone() async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    timezone.setLocalLocation(
      timezone.getLocation(timezoneInfo.identifier),
    );
  }
}

class _MedicineAlertTime {
  final int hour;
  final int minute;

  const _MedicineAlertTime({
    required this.hour,
    required this.minute,
  });
}