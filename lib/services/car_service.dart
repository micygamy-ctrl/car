import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/car_model.dart';

class CarWithRole {
  final CarModel car;
  final String role; // 'admin' or 'driver'
  const CarWithRole({required this.car, required this.role});
}

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

  /// Stream يجمع السيارات المملوكة + السيارات اللي المستخدم سواق فيها
  Stream<List<CarWithRole>> getUserCarsWithRole(String userId) {
    late StreamSubscription ownedSub;
    late StreamSubscription memberSub;

    List<CarWithRole> ownedCars = [];
    List<CarWithRole> memberCars = [];

    final controller = StreamController<List<CarWithRole>>();

    void emit() {
      if (!controller.isClosed) {
        controller.add([...ownedCars, ...memberCars]);
      }
    }

    ownedSub = _firestore
        .collection('cars')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      ownedCars = snap.docs
          .map((d) => CarWithRole(car: CarModel.fromMap(d.data()), role: 'admin'))
          .toList();
      emit();
    });

    memberSub = _firestore
        .collection('carMembers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snap) async {
          final List<CarWithRole> result = [];
          for (final doc in snap.docs) {
            final data = doc.data();
            final carId = data['carId'] as String;
            final carDoc =
                await _firestore.collection('cars').doc(carId).get();
            if (carDoc.exists) {
              result.add(CarWithRole(
                car: CarModel.fromMap(carDoc.data()!),
                role: data['role'] as String? ?? 'driver',
              ));
            }
          }
          return result;
        })
        .listen((result) {
          memberCars = result;
          emit();
        });

    controller.onCancel = () {
      ownedSub.cancel();
      memberSub.cancel();
      controller.close();
    };

    return controller.stream;
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
      const collections = ['fuelLogs', 'serviceLogs', 'carParts'];

      // جلب كل المجموعات بالتوازي
      final snaps = await Future.wait(
        collections.map((col) => _firestore
            .collection(col)
            .where('carId', isEqualTo: carId)
            .get()),
      );

      // حذف كل الوثائق في batch واحد
      final batch = _firestore.batch();
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
      }
      batch.delete(_firestore.collection('cars').doc(carId));
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  String generateId() => _uuid.v4();
}