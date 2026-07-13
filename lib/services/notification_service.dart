import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/maintenance_log_model.dart';
import '../models/car_part_model.dart';

typedef SendNotificationFn = Future<void> Function({
  required int id,
  required String title,
  required String body,
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() : _sendOverride = null;

  /// باب خلفي للاختبارات فقط — بيتجاوز الـ singleton وبيسمح بحقن دالة
  /// وهمية بدل الاتصال الحقيقي بمكتبة الإشعارات (اللي مش متاحة في بيئة الاختبار).
  @visibleForTesting
  NotificationService.forTesting({required SendNotificationFn sendNotification})
      : _sendOverride = sendNotification;

  final SendNotificationFn? _sendOverride;

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
   final override = _sendOverride;
    if (override != null) {
      return override(id: id, title: title, body: body);
    }

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

  // ─── ID Scheme (لا تصادم) ─────────────────────────────────────────────────
  // كل نوع تنبيه يستخدم hash منفصل من (carId + itemId)
  // النطاق 1–999_999 محجوز للصيانة؛ 1_000_000+ لحركة السيارة
  int _notifId(String carId, String category, String itemKey) {
    final hash = (carId + category + itemKey).hashCode.abs() % 999999;
    return hash == 0 ? 1 : hash;
  }

  Future<void> checkOilChangeReminder({
    required String carId,
    required String carName,
    required double currentOdometer,
    required double lastOilChangeOdometer,
    required double oilChangeInterval,
  }) async {
    final kmDriven = currentOdometer - lastOilChangeOdometer;
    final kmToNextOil = oilChangeInterval - kmDriven;

    if (kmToNextOil <= 0) {
      await showNotification(
        id: _notifId(carId, 'oil', 'overdue'),
        title: '🔴 حان وقت تغيير الزيت!',
        body: '$carName — لقد تجاوزت موعد تغيير الزيت، افحص سيارتك الآن!',
      );
    } else if (kmToNextOil <= 500) {
      await showNotification(
        id: _notifId(carId, 'oil', 'soon'),
        title: '⚠️ تغيير الزيت قريب!',
        body:
            '$carName — باقي ${kmToNextOil.toStringAsFixed(0)} كم لتغيير الزيت.',
      );
    }
  }

  Future<void> checkExpiryReminders({
    required String carId,
    required String carName,
    required List<ServiceLogModel> logs,
  }) async {
    final now = DateTime.now();

    for (final log in logs) {
      if (log.expiryDate == null) continue;
      final daysLeft = log.expiryDate!.difference(now).inDays;

      if (daysLeft < 0) {
        await showNotification(
          id: _notifId(carId, 'expiry_overdue', log.logId),
          title: '🔴 انتهت الصلاحية!',
          body:
              '$carName — ${log.title} انتهت صلاحيته منذ ${daysLeft.abs()} يوم',
        );
      } else if (daysLeft <= 7) {
        await showNotification(
          id: _notifId(carId, 'expiry_7d', log.logId),
          title: '🔴 ينتهي خلال أيام!',
          body: '$carName — ${log.title} ينتهي خلال $daysLeft يوم فقط!',
        );
      } else if (daysLeft <= 30) {
        await showNotification(
          id: _notifId(carId, 'expiry_30d', log.logId),
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
    for (final log in logs) {
      if (log.nextDueOdometer == null) continue;
      final kmLeft = log.nextDueOdometer! - currentOdometer;

      if (kmLeft <= 0) {
        await showNotification(
          id: _notifId(carId, 'odo_overdue', log.logId),
          title: '🔴 حان موعد الصيانة!',
          body:
              '$carName — ${log.title} متأخر ${kmLeft.abs().toStringAsFixed(0)} كم',
        );
      } else if (kmLeft <= 500) {
        await showNotification(
          id: _notifId(carId, 'odo_soon', log.logId),
          title: '⚠️ صيانة قريبة',
          body: '$carName — ${log.title} بعد ${kmLeft.toStringAsFixed(0)} كم',
        );
      }
    }
  }

  Future<void> checkCarPartsReminders({
    required String carId,
    required String carName,
    required double currentOdometer,
    required List<CarPartModel> parts,
  }) async {
    for (final part in parts) {
      final status = part.status(currentOdometer);
      if (status == PartStatus.overdue) {
        final kmLeft = part.kmRemaining(currentOdometer);
        final daysLeft = part.daysRemaining();
        final detail = kmLeft != null
            ? 'تجاوز الموعد بـ ${kmLeft.abs().toStringAsFixed(0)} كم'
            : daysLeft != null
                ? 'تجاوز الموعد بـ ${daysLeft.abs()} يوم'
                : '';
        await showNotification(
          id: _notifId(carId, 'part_overdue', part.partId),
          title: '🔴 حان موعد صيانة!',
          body: '$carName — ${part.name}، $detail',
        );
      } else if (status == PartStatus.dueSoon) {
        final kmLeft = part.kmRemaining(currentOdometer);
        final daysLeft = part.daysRemaining();
        final detail = kmLeft != null
            ? 'باقي ${kmLeft.toStringAsFixed(0)} كم'
            : daysLeft != null
                ? 'باقي $daysLeft يوم'
                : '';
        await showNotification(
          id: _notifId(carId, 'part_soon', part.partId),
          title: '⚠️ صيانة قريبة',
          body: '$carName — ${part.name}، $detail',
        );
      }
    }
  }
}