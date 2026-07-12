import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/car_service.dart';
import '../fixtures/car_fixtures.dart';

void main() {
  group('CarService.addCar', () {
    test('يحفظ السيارة في Firestore بكل بياناتها', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      final car = buildTestCar(carId: 'car1', ownerId: 'user1');

      await service.addCar(car);

      final doc = await firestore.collection('cars').doc('car1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['ownerId'], 'user1');
    });
  });

  group('CarService.getUserCarsWithRole', () {
    test('يرجع السيارات المملوكة بدور admin', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());

      final result = await service
          .getUserCarsWithRole('user1')
          .firstWhere((list) => list.isNotEmpty);

      expect(result.length, 1);
      expect(result.first.role, 'admin');
      expect(result.first.car.carId, 'car1');
    });

    test('يرجع السيارات اللي المستخدم سواق فيها بدور driver', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car2')
          .set(buildTestCar(carId: 'car2', ownerId: 'owner_x').toMap());
      await firestore.collection('carMembers').doc('car2_user1').set({
        'carId': 'car2',
        'userId': 'user1',
        'role': 'driver',
      });

      final result = await service
          .getUserCarsWithRole('user1')
          .firstWhere((list) => list.isNotEmpty);

      expect(result.length, 1);
      expect(result.first.role, 'driver');
      expect(result.first.car.carId, 'car2');
    });

    test('يدمج السيارات المملوكة والمشترك فيها كسائق مع بعض', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());
      await firestore
          .collection('cars')
          .doc('car2')
          .set(buildTestCar(carId: 'car2', ownerId: 'owner_x').toMap());
      await firestore.collection('carMembers').doc('car2_user1').set({
        'carId': 'car2',
        'userId': 'user1',
        'role': 'driver',
      });

      final result = await service
          .getUserCarsWithRole('user1')
          .firstWhere((list) => list.length == 2);

      final roles = {for (final r in result) r.car.carId: r.role};
      expect(roles['car1'], 'admin');
      expect(roles['car2'], 'driver');
    });
  });

  group('CarService.getCarStream', () {
    test('يرجع بيانات السيارة لما تتغير', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());

      final car = await service.getCarStream('car1').first;

      expect(car, isNotNull);
      expect(car!.carId, 'car1');
    });

    test('يرجع null لو السيارة مش موجودة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);

      final car = await service.getCarStream('ghost').first;

      expect(car, isNull);
    });
  });

  group('CarService.getCar', () {
    test('يرجع السيارة لو موجودة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());

      final car = await service.getCar('car1');

      expect(car, isNotNull);
      expect(car!.ownerId, 'user1');
    });

    test('يرجع null لو مش موجودة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);

      final car = await service.getCar('ghost');

      expect(car, isNull);
    });
  });

  group('CarService.updateCar', () {
    test('يحدّث الحقول المطلوبة بس', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());

      await service.updateCar('car1', {'currentOdometer': 9999.0});

      final doc = await firestore.collection('cars').doc('car1').get();
      expect(doc.data()?['currentOdometer'], 9999.0);
      // باقي الحقول المفروض تفضل زي ما هي
      expect(doc.data()?['ownerId'], 'user1');
    });
  });

  group('CarService.deleteCar', () {
    test('يحذف السيارة وكل السجلات المرتبطة بيها', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarService(firestore: firestore);
      await firestore
          .collection('cars')
          .doc('car1')
          .set(buildTestCar(carId: 'car1', ownerId: 'user1').toMap());
      await firestore
          .collection('fuelLogs')
          .doc('log1')
          .set({'carId': 'car1', 'totalCost': 100});
      await firestore
          .collection('serviceLogs')
          .doc('log2')
          .set({'carId': 'car1', 'cost': 200});
      await firestore
          .collection('carParts')
          .doc('part1')
          .set({'carId': 'car1', 'name': 'زيت'});
      // سجل لسيارة تانية، المفروض يفضل زي ما هو
      await firestore
          .collection('fuelLogs')
          .doc('log3')
          .set({'carId': 'car2', 'totalCost': 50});

      await service.deleteCar('car1');

      final carDoc = await firestore.collection('cars').doc('car1').get();
      expect(carDoc.exists, isFalse);

      final fuelLogs = await firestore
          .collection('fuelLogs')
          .where('carId', isEqualTo: 'car1')
          .get();
      expect(fuelLogs.docs, isEmpty);

      final serviceLogs = await firestore
          .collection('serviceLogs')
          .where('carId', isEqualTo: 'car1')
          .get();
      expect(serviceLogs.docs, isEmpty);

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();
      expect(parts.docs, isEmpty);

      // سجل السيارة التانية لازم يفضل موجود
      final otherLog = await firestore.collection('fuelLogs').doc('log3').get();
      expect(otherLog.exists, isTrue);
    });
  });

  group('CarService.generateId', () {
    test('بيرجع IDs فريدة في كل مرة', () {
      final service = CarService(firestore: FakeFirebaseFirestore());
      final id1 = service.generateId();
      final id2 = service.generateId();

      expect(id1, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });
  });
}