import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/models/car_part_model.dart';
import 'package:car/services/car_part_service.dart';

void main() {
  group('CarPartService.getCarParts', () {
    test('يرجع بس القطع المفعّلة الخاصة بالسيارة المطلوبة', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);
      await firestore.collection('carParts').doc('p1').set({
        'carId': 'car1',
        'name': 'زيت المحرك',
        'category': 'engine',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });
      await firestore.collection('carParts').doc('p2').set({
        'carId': 'car1',
        'name': 'قطعة معطلة',
        'category': 'engine',
        'enabled': false,
        'updatedAt': DateTime.now(),
      });
      await firestore.collection('carParts').doc('p3').set({
        'carId': 'car2',
        'name': 'قطعة سيارة تانية',
        'category': 'engine',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });

      final parts = await service.getCarParts('car1').first;

      expect(parts.length, 1);
      expect(parts.first.name, 'زيت المحرك');
    });
  });

  group('CarPartService.upsertPart', () {
    test('ينشئ أو يحدّث القطعة بدمج البيانات', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);
      final now = DateTime.now();

      await service.upsertPart(CarPartModel(
        partId: 'p1',
        carId: 'car1',
        name: 'زيت',
        category: 'engine',
        enabled: true,
        updatedAt: now,
      ));

      final doc = await firestore.collection('carParts').doc('p1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], 'زيت');
    });
  });

  group('CarPartService.initDefaultParts', () {
    test('ينشئ القطع الافتراضية لو مفيش قطع للسيارة أصلاً', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);

      await service.initDefaultParts('car1', 5000);

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();
      expect(parts.docs, isNotEmpty);
      expect(parts.docs.length, 12); // عدد القطع الافتراضية المعرّفة
    });

    test('ميعملش حاجة لو السيارة عندها قطع بالفعل', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);
      await firestore.collection('carParts').doc('existing').set({
        'carId': 'car1',
        'name': 'قطعة موجودة بالفعل',
        'category': 'engine',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });

      await service.initDefaultParts('car1', 5000);

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();
      // المفروض يفضل بس القطعة الموجودة، من غير ما تتضاف القطع الافتراضية
      expect(parts.docs.length, 1);
    });
  });

  group('CarPartService.upsertFromServiceTitle', () {
    test('ينشئ قطعة جديدة لو مفيش أي قطعة بنفس المفهوم', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);

      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير تيل الفرامل',
        currentOdometer: 20000,
        intervalKm: 30000,
        intervalDays: null,
        nextDueOdometer: 50000,
        nextDueDate: null,
      );

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();
      expect(parts.docs.length, 1);
      expect(parts.docs.first.data()['name'], 'تغيير تيل الفرامل');
    });

    test(
        'يحدّث نفس القطعة لو نفس العنوان بالظبط اتسجل تاني (نفس الـ ID)',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);

      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير فلتر الهواء',
        currentOdometer: 10000,
        intervalKm: 10000,
        intervalDays: null,
        nextDueOdometer: 20000,
        nextDueDate: null,
      );
      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير فلتر الهواء',
        currentOdometer: 20000,
        intervalKm: 10000,
        intervalDays: null,
        nextDueOdometer: 30000,
        nextDueDate: null,
      );

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();
      // لازم تفضل قطعة واحدة بس، اتحدثت مش اتضاعفت
      expect(parts.docs.length, 1);
      expect(parts.docs.first.data()['lastServiceOdometer'], 20000.0);
    });

    test(
        'يتعرف على نفس القطعة حتى لو الاسم مكتوب بصيغة مختلفة (مرادفات عربي)',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);

      // القطعة الأولى مسجلة بصيغة "تغيير زيت الموتور" (زي القطع الافتراضية)
      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير زيت الموتور',
        currentOdometer: 10000,
        intervalKm: 5000,
        intervalDays: null,
        nextDueOdometer: 15000,
        nextDueDate: null,
      );

      // بعدين المستخدم بيسجل خدمة بصيغة مختلفة لكن بنفس "المفهوم" (زيت + محرك)
      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'زيت المحرك',
        currentOdometer: 15000,
        intervalKm: 5000,
        intervalDays: null,
        nextDueOdometer: 20000,
        nextDueDate: null,
      );

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();

      // المفروض يتعرف عليها كـ نفس القطعة ويحدثها، مش يعمل قطعة جديدة مكررة
      expect(parts.docs.length, 1);
      expect(parts.docs.first.data()['lastServiceOdometer'], 15000.0);
    });

    test('مبيدمجش قطعتين مختلفتين تمامًا في المفهوم', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);

      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير زيت الموتور',
        currentOdometer: 10000,
        intervalKm: 5000,
        intervalDays: null,
        nextDueOdometer: 15000,
        nextDueDate: null,
      );
      await service.upsertFromServiceTitle(
        carId: 'car1',
        serviceTitle: 'تغيير الإطارات',
        currentOdometer: 10000,
        intervalKm: 50000,
        intervalDays: null,
        nextDueOdometer: 60000,
        nextDueDate: null,
      );

      final parts = await firestore
          .collection('carParts')
          .where('carId', isEqualTo: 'car1')
          .get();

      expect(parts.docs.length, 2);
    });
  });

  group('CarPartService.disablePart', () {
    test('يعطّل القطعة من غير ما يحذفها', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CarPartService(firestore: firestore);
      await firestore.collection('carParts').doc('p1').set({
        'carId': 'car1',
        'name': 'قطعة',
        'category': 'engine',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });

      await service.disablePart('p1');

      final doc = await firestore.collection('carParts').doc('p1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['enabled'], isFalse);
    });
  });
}