import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/models/maintenance_item_model.dart';
import 'package:car/services/maintenance_item_service.dart';
import '../fixtures/car_fixtures.dart';

void main() {
  group('MaintenanceItemService.upsertFromServiceLog', () {
    test('بيتجاهل السجل لو التصنيف مش "maintenance"', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceItemService(firestore: firestore);

      await service.upsertFromServiceLog(
        log: buildTestServiceLog(
          logId: 'log1',
          carId: 'car1',
          category: 'insurance',
        ),
      );

      final items = await firestore.collection('maintenanceItems').get();
      expect(items.docs, isEmpty);
    });

    test('بينشئ عنصر جديد لو التصنيف "maintenance"', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceItemService(firestore: firestore);

      await service.upsertFromServiceLog(
        log: buildTestServiceLog(
          logId: 'log1',
          carId: 'car1',
          category: 'maintenance',
          title: 'تغيير زيت المحرك',
        ),
        intervalKm: 5000,
      );

      final items = await firestore.collection('maintenanceItems').get();
      expect(items.docs.length, 1);
      expect(items.docs.first.data()['title'], 'تغيير زيت المحرك');
    });

    test('بيدمج نفس العنصر تاني (نفس العنوان) بدل ما يكرره', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceItemService(firestore: firestore);

      await service.upsertFromServiceLog(
        log: buildTestServiceLog(
          logId: 'log1',
          carId: 'car1',
          category: 'maintenance',
          title: 'تغيير زيت المحرك',
        ),
      );
      await service.upsertFromServiceLog(
        log: buildTestServiceLog(
          logId: 'log2',
          carId: 'car1',
          category: 'maintenance',
          title: 'تغيير زيت المحرك',
        ),
      );

      final items = await firestore.collection('maintenanceItems').get();
      expect(items.docs.length, 1);
    });
  });

  group('MaintenanceItemService.addCustomItem / disableItem', () {
    test('بيضيف عنصر مخصص ويقدر يعطّله بعد كده', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceItemService(firestore: firestore);

      await service.addCustomItem(_customItem());
      var items = await firestore.collection('maintenanceItems').get();
      expect(items.docs.first.data()['enabled'], isTrue);

      await service.disableItem('item1');
      items = await firestore.collection('maintenanceItems').get();
      expect(items.docs.first.data()['enabled'], isFalse);
    });
  });

  group('MaintenanceItemService.getCarMaintenanceItems', () {
    test('بيرجع بس العناصر المفعّلة الخاصة بالسيارة، مرتبة أبجديًا', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MaintenanceItemService(firestore: firestore);

      await firestore.collection('maintenanceItems').doc('i1').set({
        'itemId': 'i1',
        'carId': 'car1',
        'title': 'زيت',
        'category': 'maintenance',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });
      await firestore.collection('maintenanceItems').doc('i2').set({
        'itemId': 'i2',
        'carId': 'car1',
        'title': 'إطارات',
        'category': 'maintenance',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });
      await firestore.collection('maintenanceItems').doc('i3').set({
        'itemId': 'i3',
        'carId': 'car1',
        'title': 'معطل',
        'category': 'maintenance',
        'enabled': false,
        'updatedAt': DateTime.now(),
      });
      await firestore.collection('maintenanceItems').doc('i4').set({
        'itemId': 'i4',
        'carId': 'car2',
        'title': 'سيارة تانية',
        'category': 'maintenance',
        'enabled': true,
        'updatedAt': DateTime.now(),
      });

      final items = await service.getCarMaintenanceItems('car1').first;

      expect(items.length, 2);
      expect(items.first.title, 'إطارات'); // مرتبة أبجديًا
      expect(items.last.title, 'زيت');
    });
  });

  group('MaintenanceItemService.generateId', () {
    test('بيرجع IDs فريدة', () {
      final service =
          MaintenanceItemService(firestore: FakeFirebaseFirestore());
      expect(service.generateId(), isNot(equals(service.generateId())));
    });
  });
}

MaintenanceItemModel _customItem() => MaintenanceItemModel(
      itemId: 'item1',
      carId: 'car1',
      title: 'عنصر مخصص',
      category: 'maintenance',
      enabled: true,
      updatedAt: DateTime.now(),
    );