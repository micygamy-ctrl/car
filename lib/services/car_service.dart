import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/car_model.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // إضافة سيارة جديدة
  Future<void> addCar(CarModel car) async {
    try {
      await _firestore
          .collection('cars')
          .doc(car.carId)
          .set(car.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // جلب سيارات المستخدم
  Stream<List<CarModel>> getUserCars(String userId) {
    return _firestore
        .collection('cars')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarModel.fromMap(doc.data()))
            .toList());
  }

  // جلب سيارة محددة
  Future<CarModel?> getCar(String carId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('cars').doc(carId).get();
      if (doc.exists) {
        return CarModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // تحديث بيانات السيارة
  Future<void> updateCar(String carId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('cars').doc(carId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // حذف سيارة
  Future<void> deleteCar(String carId) async {
    try {
      await _firestore.collection('cars').doc(carId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // توليد ID جديد
  String generateId() => _uuid.v4();
}