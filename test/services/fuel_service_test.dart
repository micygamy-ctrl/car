import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/fuel_service.dart';
import '../fixtures/car_fixtures.dart';

void main() {
  group('FuelService.addFuelLog / getCarFuelLogs', () {
    test('بيحفظ السجل ويرجعه في القايمة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);

      await service.addFuelLog(
        buildTestFuelLog(logId: 'log1', carId: 'car1'),
      );

      final logs = await service.getCarFuelLogs('car1').first;

      expect(logs.length, 1);
      expect(logs.first.logId, 'log1');
    });

    test('بيرتب السجلات من الأحدث للأقدم', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);

      await service.addFuelLog(buildTestFuelLog(
        logId: 'old',
        carId: 'car1',
        date: DateTime(2026, 1, 1),
      ));
      await service.addFuelLog(buildTestFuelLog(
        logId: 'new',
        carId: 'car1',
        date: DateTime(2026, 6, 1),
      ));

      final logs = await service.getCarFuelLogs('car1').first;

      expect(logs.first.logId, 'new');
      expect(logs.last.logId, 'old');
    });

    test('بيرجع بس سجلات السيارة المطلوبة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);

      await service.addFuelLog(buildTestFuelLog(logId: 'log1', carId: 'car1'));
      await service.addFuelLog(buildTestFuelLog(logId: 'log2', carId: 'car2'));

      final logs = await service.getCarFuelLogs('car1').first;

      expect(logs.length, 1);
      expect(logs.first.carId, 'car1');
    });
  });

  group('FuelService.getAverageEfficiency', () {
    test('بيرجع null لو أقل من سجلين full-tank', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);

      await service.addFuelLog(buildTestFuelLog(
        logId: 'log1',
        carId: 'car1',
        date: DateTime(2026, 1, 1),
        calculatedEfficiency: 7.5,
      ));

      final avg = await service.getAverageEfficiency('car1');

      expect(avg, isNull);
    });

    test('بيحسب متوسط الاستهلاك من سجلات full-tank بس', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);

      await service.addFuelLog(buildTestFuelLog(
        logId: 'log1',
        carId: 'car1',
        date: DateTime(2026, 1, 1),
        isFullTank: true,
        calculatedEfficiency: 8.0,
      ));
      await service.addFuelLog(buildTestFuelLog(
        logId: 'log2',
        carId: 'car1',
        date: DateTime(2026, 2, 1),
        isFullTank: true,
        calculatedEfficiency: 6.0,
      ));
      // سجل مش full-tank، المفروض ميتحسبش
      await service.addFuelLog(buildTestFuelLog(
        logId: 'log3',
        carId: 'car1',
        date: DateTime(2026, 3, 1),
        isFullTank: false,
        calculatedEfficiency: 100.0,
      ));

      final avg = await service.getAverageEfficiency('car1');

      expect(avg, 7.0); // متوسط (8.0 + 6.0) / 2
    });
  });

  group('FuelService.deleteFuelLog', () {
    test('بيحذف السجل من Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FuelService(firestore: firestore);
      await service.addFuelLog(buildTestFuelLog(logId: 'log1', carId: 'car1'));

      await service.deleteFuelLog('log1');

      final doc = await firestore.collection('fuelLogs').doc('log1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('FuelService.generateId', () {
    test('بيرجع IDs فريدة', () {
      final service = FuelService(firestore: FakeFirebaseFirestore());
      expect(service.generateId(), isNot(equals(service.generateId())));
    });
  });
}