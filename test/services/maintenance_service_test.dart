import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/maintenance_service.dart';
import '../fixtures/car_fixtures.dart';

void main() {
  group('MaintenanceService.addServiceLog / getCarMaintenanceLogs', () {
    test('بيحفظ السجل ويرجعه في القايمة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);

      await service.addServiceLog(
        buildTestServiceLog(logId: 'log1', carId: 'car1'),
      );

      final logs = await service.getCarMaintenanceLogs('car1').first;

      expect(logs.length, 1);
      expect(logs.first.logId, 'log1');
    });

    test('بيرتب السجلات من الأحدث للأقدم', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);

      await service.addServiceLog(buildTestServiceLog(
        logId: 'old',
        carId: 'car1',
        date: DateTime(2026, 1, 1),
      ));
      await service.addServiceLog(buildTestServiceLog(
        logId: 'new',
        carId: 'car1',
        date: DateTime(2026, 6, 1),
      ));

      final logs = await service.getCarMaintenanceLogs('car1').first;

      expect(logs.first.logId, 'new');
      expect(logs.last.logId, 'old');
    });

    test('بيرجع بس سجلات السيارة المطلوبة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);

      await service
          .addServiceLog(buildTestServiceLog(logId: 'log1', carId: 'car1'));
      await service
          .addServiceLog(buildTestServiceLog(logId: 'log2', carId: 'car2'));

      final logs = await service.getCarMaintenanceLogs('car1').first;

      expect(logs.length, 1);
      expect(logs.first.carId, 'car1');
    });
  });

  group('MaintenanceService.addMaintenanceLog', () {
    test('اسم تاني لنفس addServiceLog، بيحفظ بنفس الطريقة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);

      await service.addMaintenanceLog(
        buildTestServiceLog(logId: 'log1', carId: 'car1'),
      );

      final doc = await firestore.collection('serviceLogs').doc('log1').get();
      expect(doc.exists, isTrue);
    });
  });

  group('MaintenanceService.getUpcomingReminders', () {
    test('بيرجع بس السجلات اللي هتنتهي خلال 30 يوم ولسه مبعتش تنبيهها',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);
      final now = DateTime.now();

      // هتنتهي بعد 10 أيام — المفروض تظهر
      await service.addServiceLog(buildTestServiceLog(
        logId: 'soon',
        carId: 'car1',
        expiryDate: now.add(const Duration(days: 10)),
        reminderSent: false,
      ));
      // هتنتهي بعد 60 يوم — بعيدة أوي، مش المفروض تظهر
      await service.addServiceLog(buildTestServiceLog(
        logId: 'far',
        carId: 'car1',
        expiryDate: now.add(const Duration(days: 60)),
        reminderSent: false,
      ));
      // اتبعت تنبيهها بالفعل — مش المفروض تظهر
      await service.addServiceLog(buildTestServiceLog(
        logId: 'already_sent',
        carId: 'car1',
        expiryDate: now.add(const Duration(days: 5)),
        reminderSent: true,
      ));
      // مالهاش تاريخ انتهاء أصلاً — مش المفروض تظهر
      await service.addServiceLog(buildTestServiceLog(
        logId: 'no_expiry',
        carId: 'car1',
        reminderSent: false,
      ));

      final reminders = await service.getUpcomingReminders('car1').first;

      expect(reminders.length, 1);
      expect(reminders.first.logId, 'soon');
    });
  });

  group('MaintenanceService.updateServiceLog', () {
    test('بيحدّث الحقول المطلوبة بس', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);
      await service
          .addServiceLog(buildTestServiceLog(logId: 'log1', carId: 'car1'));

      await service.updateServiceLog('log1', {'cost': 500.0});

      final doc = await firestore.collection('serviceLogs').doc('log1').get();
      expect(doc.data()?['cost'], 500.0);
    });
  });

  group('MaintenanceService.markReminderSent', () {
    test('بيعلّم reminderSent كـ true', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);
      await service.addServiceLog(
          buildTestServiceLog(logId: 'log1', carId: 'car1', reminderSent: false));

      await service.markReminderSent('log1');

      final doc = await firestore.collection('serviceLogs').doc('log1').get();
      expect(doc.data()?['reminderSent'], isTrue);
    });
  });

  group('MaintenanceService.deleteMaintenanceLog', () {
    test('بيحذف السجل من Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceService(firestore: firestore);
      await service
          .addServiceLog(buildTestServiceLog(logId: 'log1', carId: 'car1'));

      await service.deleteMaintenanceLog('log1');

      final doc = await firestore.collection('serviceLogs').doc('log1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('MaintenanceService.generateId', () {
    test('بيرجع IDs فريدة', () {
      final service = MaintenanceService(firestore: FakeFirebaseFirestore());
      expect(service.generateId(), isNot(equals(service.generateId())));
    });
  });
}