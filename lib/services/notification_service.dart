import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'car_maintenance_channel',
      'تنبيهات السيارة',
      channelDescription: 'تنبيهات صيانة ووقود السيارة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'car_maintenance_channel',
      'تنبيهات السيارة',
      channelDescription: 'تنبيهات صيانة ووقود السيارة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> checkOilChangeReminder({
    required String carName,
    required double currentOdometer,
    required double lastOilChangeOdometer,
    required double oilChangeInterval,
  }) async {
    final kmDriven = currentOdometer - lastOilChangeOdometer;
    final kmToNextOil = oilChangeInterval - kmDriven;

    if (kmToNextOil <= 0) {
      await showNotification(
        id: 1,
        title: '🔴 حان وقت تغيير الزيت!',
        body: '$carName — لقد تجاوزت موعد تغيير الزيت، افحص سيارتك الآن!',
      );
    } else if (kmToNextOil <= 500) {
      await showNotification(
        id: 1,
        title: '⚠️ تغيير الزيت قريب!',
        body: '$carName — باقي ${kmToNextOil.toStringAsFixed(0)} كم لتغيير الزيت.',
      );
    }
  }
}