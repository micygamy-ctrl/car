import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarMember {
  final String userId;
  final String role;
  final String name;
  final String email;
  final DateTime? joinedAt;

  const CarMember({
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    this.joinedAt,
  });

  factory CarMember.fromMap(Map<String, dynamic> map) {
    return CarMember(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'driver',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => _chars[rand.nextInt(_chars.length)]).join();
  }

  Future<String?> getUserRole(String carId, String userId) async {
    final carDoc = await _firestore.collection('cars').doc(carId).get();
    if (carDoc.exists && carDoc.data()?['ownerId'] == userId) return 'admin';
    final memberDoc = await _firestore
        .collection('carMembers')
        .doc('${carId}_$userId')
        .get();
    if (memberDoc.exists) return memberDoc.data()?['role'] as String?;
    return null;
  }

  Future<String> generateInviteCode(String carId, String carName) async {
    final code = _generateCode();
    await _firestore.collection('inviteCodes').doc(code).set({
      'carId': carId,
      'carName': carName,
      'createdBy': _auth.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))),
      'isUsed': false,
    });
    return code;
  }

  Future<String> joinByCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    final upperCode = code.trim().toUpperCase();
    final codeDoc =
        await _firestore.collection('inviteCodes').doc(upperCode).get();
    if (!codeDoc.exists) throw Exception('الكود غير صحيح');

    final data = codeDoc.data()!;
    if (data['isUsed'] == true) throw Exception('الكود مستخدم بالفعل');

    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) throw Exception('انتهت صلاحية الكود');

    final carId = data['carId'] as String;

    final carDoc = await _firestore.collection('cars').doc(carId).get();
    if (!carDoc.exists) throw Exception('السيارة غير موجودة');
    if (carDoc.data()?['ownerId'] == user.uid) {
      throw Exception('أنت بالفعل مالك هذه السيارة');
    }

    final existing = await _firestore
        .collection('carMembers')
        .doc('${carId}_${user.uid}')
        .get();
    if (existing.exists) throw Exception('أنت بالفعل عضو في هذه السيارة');

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('carMembers').doc('${carId}_${user.uid}'),
      {
        'carId': carId,
        'userId': user.uid,
        'role': 'driver',
        'name': user.displayName ?? user.email ?? '',
        'email': user.email ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _firestore.collection('inviteCodes').doc(upperCode),
      {'isUsed': true, 'usedBy': user.uid},
    );
    await batch.commit();

    return data['carName'] as String? ?? '';
  }

  Stream<List<CarMember>> getCarMembers(String carId) {
    return _firestore
        .collection('carMembers')
        .where('carId', isEqualTo: carId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CarMember.fromMap(d.data())).toList());
  }

  Future<void> removeMember(String carId, String userId) async {
    await _firestore
        .collection('carMembers')
        .doc('${carId}_$userId')
        .delete();
  }
}
