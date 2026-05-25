import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/fuel_log_model.dart';

class FuelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // إضافة سجل وقود جديد
  Future<void> addFuelLog(FuelLogModel log) async {
    try {
      await _firestore
          .collection('fuelLogs')
          .doc(log.logId)
          .set(log.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // جلب سجلات وقود سيارة معينة
  Stream<List<FuelLogModel>> getCarFuelLogs(String carId) {
  return _firestore
      .collection('fuelLogs')
      .where('carId', isEqualTo: carId)
      .snapshots()
      .map((snapshot) {
        final logs = snapshot.docs
            .map((doc) => FuelLogModel.fromMap(doc.data()))
            .toList();
        logs.sort((a, b) => b.date.compareTo(a.date));
        return logs;
      });
}

  // حساب متوسط الاستهلاك
  Future<double?> getAverageEfficiency(String carId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fuelLogs')
          .where('carId', isEqualTo: carId)
          .where('isFullTank', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      List<FuelLogModel> logs = snapshot.docs
          .map((doc) => FuelLogModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (logs.length < 2) return null;

      double totalEfficiency = 0;
      int count = 0;

      for (var log in logs) {
        if (log.calculatedEfficiency != null) {
          totalEfficiency += log.calculatedEfficiency!;
          count++;
        }
      }

      return count > 0 ? totalEfficiency / count : null;
    } catch (e) {
      rethrow;
    }
  }

  // حذف سجل وقود
  Future<void> deleteFuelLog(String logId) async {
    try {
      await _firestore.collection('fuelLogs').doc(logId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // توليد ID جديد
  String generateId() => _uuid.v4();
}