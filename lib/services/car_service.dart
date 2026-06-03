import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/car_model.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> addCar(CarModel car) async {
    try {
      await _firestore.collection('cars').doc(car.carId).set(car.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<CarModel>> getUserCars(String userId) {
    return _firestore
        .collection('cars')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarModel.fromMap(doc.data()))
            .toList());
  }

  Stream<CarModel?> getCarStream(String carId) {
    return _firestore
        .collection('cars')
        .doc(carId)
        .snapshots()
        .map((doc) => doc.exists ? CarModel.fromMap(doc.data()!) : null);
  }

  Future<CarModel?> getCar(String carId) async {
    try {
      final doc = await _firestore.collection('cars').doc(carId).get();
      if (doc.exists) {
        return CarModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCar(String carId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('cars').doc(carId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCar(String carId) async {
    try {
      final collections = ['fuelLogs', 'serviceLogs', 'carParts'];
      for (final col in collections) {
        final snap = await _firestore
            .collection(col)
            .where('carId', isEqualTo: carId)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
      await _firestore.collection('cars').doc(carId).delete();
    } catch (e) {
      rethrow;
    }
  }

  String generateId() => _uuid.v4();
}
