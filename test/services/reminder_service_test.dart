import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/services/reminder_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('ReminderService.runDailyCheck', () {
    late FakeFirebaseFirestore firestore;
    late MockNotificationService notif;
    late ReminderService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      firestore = FakeFirebaseFirestore();
      notif = MockNotificationService();

      when(() => notif.checkOilChangeReminder(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            lastOilChangeOdometer: any(named: 'lastOilChangeOdometer'),
            oilChangeInterval: any(named: 'oilChangeInterval'),
          )).thenAnswer((_) async {});
      when(() => notif.checkExpiryReminders(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            logs: any(named: 'logs'),
          )).thenAnswer((_) async {});
      when(() => notif.checkOdometerReminders(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            logs: any(named: 'logs'),
          )).thenAnswer((_) async {});
      when(() => notif.checkCarPartsReminders(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            parts: any(named: 'parts'),
          )).thenAnswer((_) async {});

      service = ReminderService.forTesting(
        firestore: firestore,
        notificationService: notif,
      );
    });

    Map<String, dynamic> carData({
      required String ownerId,
      double odometer = 1000,
    }) =>
        {
          'carId': 'car1',
          'ownerId': ownerId,
          'make': 'تويوتا',
          'model': 'كورولا',
          'currentOdometer': odometer,
          'lastOilChangeOdometer': 500.0,
          'oilChangeInterval': 5000.0,
        };

    test('بيفحص السيارة المملوكة', () async {
      await firestore.collection('cars').doc('car1').set(carData(ownerId: 'user1'));

      await service.runDailyCheck('user1');

      verify(() => notif.checkOilChangeReminder(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            lastOilChangeOdometer: any(named: 'lastOilChangeOdometer'),
            oilChangeInterval: any(named: 'oilChangeInterval'),
          )).called(1);
    });

    test('بيدمج السيارات المملوكة والمشترك فيها كسائق من غير تكرار', () async {
      await firestore.collection('cars').doc('car1').set(carData(ownerId: 'user1'));
      await firestore.collection('cars').doc('car2').set({
        'carId': 'car2',
        'ownerId': 'someone_else',
        'make': 'هيونداي',
        'model': 'النترا',
        'currentOdometer': 2000.0,
        'lastOilChangeOdometer': 1000.0,
        'oilChangeInterval': 5000.0,
      });
      // المستخدم مسجل كسائق في car2
      await firestore.collection('carMembers').doc('car2_user1').set({
        'carId': 'car2',
        'userId': 'user1',
      });
      // وبالغلط مسجل كمان في carMembers لعربيته هو (سيناريو تكرار محتمل)
      await firestore.collection('carMembers').doc('car1_user1').set({
        'carId': 'car1',
        'userId': 'user1',
      });

      await service.runDailyCheck('user1');

      // المفروض تتفحص مرتين بس (car1, car2) رغم تكرار car1 في carMembers
      verify(() => notif.checkOilChangeReminder(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            lastOilChangeOdometer: any(named: 'lastOilChangeOdometer'),
            oilChangeInterval: any(named: 'oilChangeInterval'),
          )).called(2);
    });

    test('مبيكررش الفحص لنفس المستخدم في نفس اليوم', () async {
      await firestore.collection('cars').doc('car1').set(carData(ownerId: 'user1'));

      await service.runDailyCheck('user1');
      await service.runDailyCheck('user1');

      verify(() => notif.checkOilChangeReminder(
            carId: any(named: 'carId'),
            carName: any(named: 'carName'),
            currentOdometer: any(named: 'currentOdometer'),
            lastOilChangeOdometer: any(named: 'lastOilChangeOdometer'),
            oilChangeInterval: any(named: 'oilChangeInterval'),
          )).called(1);
    });
  });
}