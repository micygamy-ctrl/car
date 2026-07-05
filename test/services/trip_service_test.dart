import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/trip_service.dart';

void main() {
  group('TripService.saveCompletedTrip', () {
    test('بيحسب العداد الجديد بناءً على القيمة الحية في Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('cars').doc('car1').set({'currentOdometer': 1000});
      final service = TripService(firestore: firestore);

      final (start, end) = await service.saveCompletedTrip(
        tripId: 'trip1',
        carId: 'car1',
        driverId: 'driver1',
        driverName: 'أحمد',
        distanceKm: 50,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 9),
      );

      expect(start, 1000);
      expect(end, 1050);

      final carDoc = await firestore.collection('cars').doc('car1').get();
      expect(carDoc.data()?['currentOdometer'], 1050);

      final tripDoc = await firestore.collection('trips').doc('trip1').get();
      expect(tripDoc.exists, isTrue);
      expect(tripDoc.data()?['status'], 'completed');
    });

    test('بيعتمد على القيمة الحالية وقت الحفظ، مش أي قيمة قديمة كانت متوقعة',
        () async {
      // ده أهم اختبار هنا — بيتأكد إن الـ transaction فعلاً بتقرا القيمة
      // اللحظية من Firestore، مش قيمة كانت متخزنة قبل كده في مكان تاني
      // (اللي كان سبب الـ race condition الأصلي بين سواقين).
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('cars').doc('car1').set({'currentOdometer': 2000});
      final service = TripService(firestore: firestore);

      final (start, end) = await service.saveCompletedTrip(
        tripId: 'trip2',
        carId: 'car1',
        driverId: 'driver2',
        driverName: 'محمد',
        distanceKm: 30,
        startTime: DateTime(2026, 1, 1, 10),
        endTime: DateTime(2026, 1, 1, 11),
      );

      expect(start, 2000);
      expect(end, 2030);
    });

    test('بيتعامل مع سيارة جديدة من غير currentOdometer كـ صفر', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('cars').doc('car1').set({});
      final service = TripService(firestore: firestore);

      final (start, end) = await service.saveCompletedTrip(
        tripId: 'trip3',
        carId: 'car1',
        driverId: 'driver1',
        driverName: 'أحمد',
        distanceKm: 10,
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
      );

      expect(start, 0);
      expect(end, 10);
    });
  });

  group('TripService.deleteTrip', () {
    test('بيحذف الرحلة من Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('trips').doc('trip1').set({'status': 'completed'});
      final service = TripService(firestore: firestore);

      await service.deleteTrip('trip1');

      final doc = await firestore.collection('trips').doc('trip1').get();
      expect(doc.exists, isFalse);
    });
  });
}   