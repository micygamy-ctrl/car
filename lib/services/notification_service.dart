import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/maintenance_log_model.dart';

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

  int _carBaseId(String carId) => (carId.hashCode.abs() % 9000);

  Future<void> checkOilChangeReminder({
    required String carId,
    required String carName,
    required double currentOdometer,
    required double lastOilChangeOdometer,
    required double oilChangeInterval,
  }) async {
    final kmDriven = currentOdometer - lastOilChangeOdometer;
    final kmToNextOil = oilChangeInterval - kmDriven;
    final baseId = _carBaseId(carId);

    if (kmToNextOil <= 0) {
      await showNotification(
        id: baseId,
        title: '🔴 حان وقت تغيير الزيت!',
        body: '$carName — لقد تجاوزت موعد تغيير الزيت، افحص سيارتك الآن!',
      );
    } else if (kmToNextOil <= 500) {
      await showNotification(
        id: baseId + 1,
        title: '⚠️ تغيير الزيت قريب!',
        body: '$carName — باقي ${kmToNextOil.toStringAsFixed(0)} كم لتغيير الزيت.',
      );
    }
  }

  Future<void> checkExpiryReminders({
    required String carId,
    required String carName,
    required List<ServiceLogModel> logs,
  }) async {
    final now = DateTime.now();
    final baseId = _carBaseId(carId) + 100;
    int offset = 0;

    for (final log in logs) {
      if (log.expiryDate == null) continue;
      final daysLeft = log.expiryDate!.difference(now).inDays;

      if (daysLeft < 0) {
        await showNotification(
          id: baseId + offset++,
          title: '🔴 انتهت الصلاحية!',
          body: '$carName — ${log.title} انتهت صلاحيته منذ ${daysLeft.abs()} يوم',
        );
      } else if (daysLeft <= 7) {
        await showNotification(
          id: baseId + offset++,
          title: '🔴 ينتهي خلال أيام!',
          body: '$carName — ${log.title} ينتهي خلال $daysLeft يوم فقط!',
        );
      } else if (daysLeft <= 30) {
        await showNotification(
          id: baseId + offset++,
          title: '⚠️ تذكير انتهاء صلاحية',
          body: '$carName — ${log.title} ينتهي خلال $daysLeft يوم',
        );
      }
    }
  }

  Future<void> checkOdometerReminders({
    required String carId,
    required String carName,
    required double currentOdometer,
    required List<ServiceLogModel> logs,
  }) async {
    final baseId = _carBaseId(carId) + 200;
    int offset = 0;

    for (final log in logs) {
      if (log.nextDueOdometer == null) continue;
      final kmLeft = log.nextDueOdometer! - currentOdometer;

      if (kmLeft <= 0) {
        await showNotification(
          id: baseId + offset++,
          title: '🔴 حان موعد الصيانة!',
          body: '$carName — ${log.title} متأخر ${kmLeft.abs().toStringAsFixed(0)} كم',
        );
      } else if (kmLeft <= 500) {
        await showNotification(
          id: baseId + offset++,
          title: '⚠️ صيانة قريبة',
          body: '$carName — ${log.title} بعد ${kmLeft.toStringAsFixed(0)} كم',
        );
      }
    }
  }
}
