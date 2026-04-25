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

  static Future<void> scheduleAllMedicineNotifications() async {
    if (kIsWeb) {
      return;
    }

    final medicineRepository = MedicineRepository();
    final medicines = medicineRepository.findAll();

    await cancelAllMedicineNotifications();

    for (final medicine in medicines) {
      await scheduleDailyMedicineNotification(medicine);
    }
  }

  static Future<void> scheduleDailyMedicineNotification(
    Medicine medicine,
  ) async {
    if (kIsWeb) {
      return;
    }

    final notificationId = _createNotificationId(medicine.id);
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
        notificationDetails: _buildNotificationDetails(
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
        notificationDetails: _buildNotificationDetails(
          fullScreenIntent: true,
        ),
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
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) {
      return;
    }

    await _notificationsPlugin.show(
      id: 999999,
      title: 'اختبار التنبيه',
      body: 'إذا ظهرت هذه الرسالة، فالتنبيهات تعمل بنجاح.',
      notificationDetails: _buildNotificationDetails(
        fullScreenIntent: false,
      ),
      payload: 'test_notification',
    );
  }

  static NotificationDetails _buildNotificationDetails({
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
      ),
    );
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