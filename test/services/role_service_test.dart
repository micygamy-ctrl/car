import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/role_service.dart';

void main() {
  group('RoleService.getUserRole', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('يرجع admin لو المستخدم هو مالك السيارة', () async {
      await firestore.collection('cars').doc('car1').set({'ownerId': 'user1'});
      final service = RoleService(firestore: firestore);

      final role = await service.getUserRole('car1', 'user1');

      expect(role, 'admin');
    });

    test('يرجع الدور المسجل لو المستخدم عضو مش مالك', () async {
      await firestore.collection('cars').doc('car1').set({'ownerId': 'owner1'});
      await firestore
          .collection('carMembers')
          .doc('car1_user2')
          .set({'role': 'driver'});
      final service = RoleService(firestore: firestore);

      final role = await service.getUserRole('car1', 'user2');

      expect(role, 'driver');
    });

    test('يرجع null لو المستخدم مش مالك ولا عضو', () async {
      await firestore.collection('cars').doc('car1').set({'ownerId': 'owner1'});
      final service = RoleService(firestore: firestore);

      final role = await service.getUserRole('car1', 'stranger');

      expect(role, isNull);
    });
  });

  group('RoleService.generateInviteCode', () {
    test('يرمي استثناء لو المستخدم مش مسجل دخول', () {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: false);
      final service = RoleService(firestore: firestore, auth: auth);

      expect(
        () => service.generateInviteCode('car1', 'تويوتا كورولا'),
        throwsA(isA<Exception>()),
      );
    });

    test('يرمي استثناء لو المستخدم مش مالك السيارة', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('cars').doc('car1').set({'ownerId': 'owner1'});
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'intruder', email: 'x@x.com'),
      );
      final service = RoleService(firestore: firestore, auth: auth);

      expect(
        () => service.generateInviteCode('car1', 'تويوتا كورولا'),
        throwsA(isA<Exception>()),
      );
    });

    test('ينشئ كود دعوة صحيح لو المستخدم هو المالك', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('cars').doc('car1').set({'ownerId': 'owner1'});
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'owner1', email: 'owner@x.com'),
      );
      final service = RoleService(firestore: firestore, auth: auth);

      final code = await service.generateInviteCode('car1', 'تويوتا كورولا');

      expect(code.length, 6);
      final doc = await firestore.collection('inviteCodes').doc(code).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['carId'], 'car1');
      expect(doc.data()?['usageCount'], 0);
    });
  });

  group('RoleService.joinByCode', () {
    late FakeFirebaseFirestore firestore;
    late RoleService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'driver1', email: 'driver@x.com'),
      );
      service = RoleService(firestore: firestore, auth: auth);
    });

    test('يرمي استثناء لو الكود مش موجود', () {
      expect(() => service.joinByCode('ZZZZZZ'), throwsA(isA<Exception>()));
    });

    test('يرمي استثناء لو الكود منتهي الصلاحية', () async {
      await firestore.collection('inviteCodes').doc('ABC123').set({
        'carId': 'car1',
        'carName': 'تويوتا',
        'createdBy': 'owner1',
        'expiresAt':
            Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'usedBy': [],
        'usageCount': 0,
      });

      expect(() => service.joinByCode('ABC123'), throwsA(isA<Exception>()));
    });

    test('يرمي استثناء لو صاحب الكود بيحاول ينضم لعربيته هو', () async {
      await firestore.collection('inviteCodes').doc('ABC123').set({
        'carId': 'car1',
        'carName': 'تويوتا',
        'createdBy': 'driver1',
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'usedBy': [],
        'usageCount': 0,
      });

      expect(() => service.joinByCode('ABC123'), throwsA(isA<Exception>()));
    });

    test('يرمي استثناء لو المستخدم عضو بالفعل', () async {
      await firestore.collection('inviteCodes').doc('ABC123').set({
        'carId': 'car1',
        'carName': 'تويوتا',
        'createdBy': 'owner1',
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'usedBy': [],
        'usageCount': 0,
      });
      await firestore
          .collection('carMembers')
          .doc('car1_driver1')
          .set({'role': 'driver'});

      expect(() => service.joinByCode('ABC123'), throwsA(isA<Exception>()));
    });

    test('ينضم بنجاح ويحدّث usageCount (case-insensitive)', () async {
      await firestore.collection('inviteCodes').doc('ABC123').set({
        'carId': 'car1',
        'carName': 'تويوتا كورولا',
        'createdBy': 'owner1',
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'usedBy': [],
        'usageCount': 0,
      });

      final carName = await service.joinByCode('abc123');

      expect(carName, 'تويوتا كورولا');
      final memberDoc =
          await firestore.collection('carMembers').doc('car1_driver1').get();
      expect(memberDoc.exists, isTrue);
      expect(memberDoc.data()?['role'], 'driver');
      final codeDoc = await firestore.collection('inviteCodes').doc('ABC123').get();
      expect(codeDoc.data()?['usageCount'], 1);
    });
  });
}