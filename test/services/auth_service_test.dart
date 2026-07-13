import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car/services/auth_service.dart';

void main() {
  group('AuthService.register', () {
    test('بينشئ مستخدم ويحفظ الإعدادات الافتراضية في users/{uid}', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final service = AuthService(auth: auth, firestore: firestore);

      final user = await service.register(
        'test@example.com',
        'password123',
        'أحمد',
      );

      expect(user, isNotNull);
      final doc = await firestore.collection('users').doc(user!.uid).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['displayName'], 'أحمد');
      expect(doc.data()?['email'], 'test@example.com');
      expect(doc.data()?['preferredCurrency'], 'EGP');
      expect(doc.data()?['notificationsEnabled'], isTrue);
    });
  });

  group('AuthService.login', () {
    test('بيرجع نفس المستخدم اللي مسجل دخول بيه', () async {
      final mockUser = MockUser(
        uid: 'user1',
        email: 'existing@example.com',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = AuthService(auth: auth, firestore: FakeFirebaseFirestore());

      final user = await service.login('existing@example.com', 'password123');

      expect(user, isNotNull);
      expect(user!.email, 'existing@example.com');
    });
  });

  group('AuthService.currentUser', () {
    test('بيرجع null لو مفيش حد مسجل دخول', () {
      final auth = MockFirebaseAuth(signedIn: false);
      final service = AuthService(auth: auth, firestore: FakeFirebaseFirestore());

      expect(service.currentUser, isNull);
    });

    test('بيرجع المستخدم الحالي لو فيه حد مسجل دخول', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user1', email: 'x@x.com'),
      );
      final service = AuthService(auth: auth, firestore: FakeFirebaseFirestore());

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.uid, 'user1');
    });
  });

  group('AuthService.logout', () {
    test('بيمسح المستخدم الحالي بعد تسجيل الخروج', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user1', email: 'x@x.com'),
      );
      final service = AuthService(auth: auth, firestore: FakeFirebaseFirestore());

      expect(service.currentUser, isNotNull);
      await service.logout();
      expect(service.currentUser, isNull);
    });
  });

  group('AuthService.resetPassword', () {
    test('بيكمل من غير أخطاء لبريد إلكتروني صحيح', () async {
      final auth = MockFirebaseAuth();
      final service = AuthService(auth: auth, firestore: FakeFirebaseFirestore());

      await expectLater(
        service.resetPassword('test@example.com'),
        completes,
      );
    });
  });
}