import 'package:flutter_test/flutter_test.dart';
import 'package:car/models/car_part_model.dart';
import 'package:car/models/maintenance_log_model.dart';
import 'package:car/services/notification_service.dart';
import '../fixtures/car_fixtures.dart';

class _Captured {
  final int id;
  final String title;
  final String body;
  _Captured(this.id, this.title, this.body);
}

void main() {
  late List<_Captured> captured;
  late NotificationService service;

  setUp(() {
    captured = [];
    service = NotificationService.forTesting(
      sendNotification: ({
        required int id,
        required String title,
        required String body,
      }) async {
        captured.add(_Captured(id, title, body));
      },
    );
  });

  group('NotificationService.checkOilChangeReminder', () {
    test('من غير تنبيه لو لسه بعيد عن موعد تغيير الزيت', () async {
      await service.checkOilChangeReminder(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        currentOdometer: 1000,
        lastOilChangeOdometer: 0,
        oilChangeInterval: 5000,
      );

      expect(captured, isEmpty);
    });

    test('تنبيه "قريب" لو باقي 500 كم أو أقل', () async {
      await service.checkOilChangeReminder(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        currentOdometer: 4600,
        lastOilChangeOdometer: 0,
        oilChangeInterval: 5000,
      );

      expect(captured.length, 1);
      expect(captured.first.title, contains('قريب'));
    });

    test('تنبيه "حان الوقت" لو العداد تجاوز موعد التغيير', () async {
      await service.checkOilChangeReminder(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        currentOdometer: 6000,
        lastOilChangeOdometer: 0,
        oilChangeInterval: 5000,
      );

      expect(captured.length, 1);
      expect(captured.first.title, contains('حان وقت'));
    });
  });

  group('NotificationService.checkExpiryReminders', () {
    test('بيرسل تنبيه واحد بس لكل سجل حسب قرب تاريخ الانتهاء', () async {
      final now = DateTime.now();
      final logs = [
        // انتهت بالفعل
        buildTestServiceLog(
          logId: 'l1',
          carId: 'car1',
          expiryDate: now.subtract(const Duration(days: 1)),
        ),
        // هتنتهي خلال أسبوع
        buildTestServiceLog(
          logId: 'l2',
          carId: 'car1',
          expiryDate: now.add(const Duration(days: 5)),
        ),
        // هتنتهي خلال شهر
        buildTestServiceLog(
          logId: 'l3',
          carId: 'car1',
          expiryDate: now.add(const Duration(days: 20)),
        ),
        // بعيدة أوي — من غير تنبيه
        buildTestServiceLog(
          logId: 'l4',
          carId: 'car1',
          expiryDate: now.add(const Duration(days: 90)),
        ),
        // مالهاش تاريخ انتهاء أصلاً — من غير تنبيه
        buildTestServiceLog(logId: 'l5', carId: 'car1'),
      ];

      await service.checkExpiryReminders(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        logs: logs,
      );

      expect(captured.length, 3);
    });
  });

  group('NotificationService.checkOdometerReminders', () {
    test('بيرسل تنبيه بس للسجلات اللي قربت أو تجاوزت العداد المستهدف',
        () async {
      final logs = [
        ServiceLogModel(
          logId: 'l1',
          carId: 'car1',
          category: 'maintenance',
          title: 'تغيير زيت',
          date: DateTime.now(),
          cost: 250,
          status: 'done',
          reminderSent: false,
          nextDueOdometer: 9000, // تجاوز (العداد الحالي 10000)
        ),
        ServiceLogModel(
          logId: 'l2',
          carId: 'car1',
          category: 'maintenance',
          title: 'تغيير فلتر',
          date: DateTime.now(),
          cost: 100,
          status: 'done',
          reminderSent: false,
          nextDueOdometer: 10300, // قريب (باقي 300 كم)
        ),
        ServiceLogModel(
          logId: 'l3',
          carId: 'car1',
          category: 'maintenance',
          title: 'فحص دوري',
          date: DateTime.now(),
          cost: 150,
          status: 'done',
          reminderSent: false,
          nextDueOdometer: 50000, // بعيد أوي
        ),
      ];

      await service.checkOdometerReminders(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        currentOdometer: 10000,
        logs: logs,
      );

      expect(captured.length, 2);
    });
  });

  group('NotificationService.checkCarPartsReminders', () {
    test('بيرسل تنبيه حسب حالة كل قطعة (متأخرة/قريبة/تمام)', () async {
      final now = DateTime.now();
      final parts = [
        CarPartModel(
          partId: 'p1',
          carId: 'car1',
          name: 'زيت المحرك',
          category: 'engine',
          nextDueOdometer: 9000, // متأخرة (العداد الحالي 10000)
          enabled: true,
          updatedAt: now,
        ),
        CarPartModel(
          partId: 'p2',
          carId: 'car1',
          name: 'فلتر الهواء',
          category: 'engine',
          nextDueOdometer: 10300, // قريبة
          enabled: true,
          updatedAt: now,
        ),
        CarPartModel(
          partId: 'p3',
          carId: 'car1',
          name: 'الكاوتش',
          category: 'tires',
          nextDueOdometer: 50000, // تمام
          enabled: true,
          updatedAt: now,
        ),
      ];

      await service.checkCarPartsReminders(
        carId: 'car1',
        carName: 'تويوتا كورولا',
        currentOdometer: 10000,
        parts: parts,
      );

      expect(captured.length, 2);
      expect(captured.any((c) => c.title.contains('حان موعد')), isTrue);
      expect(captured.any((c) => c.title.contains('قريبة')), isTrue);
    });
  });
}