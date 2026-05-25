import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_log_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // إضافة سجل صيانة جديد
  Future<void> addMaintenanceLog(MaintenanceLogModel log) async {
    try {
      await _firestore
          .collection('maintenanceLogs')
          .doc(log.logId)
          .set(log.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // جلب سجلات صيانة سيارة معينة
  Stream<List<MaintenanceLogModel>> getCarMaintenanceLogs(String carId) {
  return _firestore
      .collection('maintenanceLogs')
      .where('carId', isEqualTo: carId)
      .snapshots()
      .map((snapshot) {
        final logs = snapshot.docs
            .map((doc) => MaintenanceLogModel.fromMap(doc.data()))
            .toList();
        logs.sort((a, b) => b.date.compareTo(a.date));
        return logs;
      });
}

  // جلب التذكيرات القادمة
  Stream<List<MaintenanceLogModel>> getUpcomingReminders(String carId) {
    return _firestore
        .collection('maintenanceLogs')
        .where('carId', isEqualTo: carId)
        .where('status', isEqualTo: 'scheduled')
        .where('reminderSent', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceLogModel.fromMap(doc.data()))
            .toList());
  }

  // تحديث حالة التذكير
  Future<void> markReminderSent(String logId) async {
    try {
      await _firestore
          .collection('maintenanceLogs')
          .doc(logId)
          .update({'reminderSent': true});
    } catch (e) {
      rethrow;
    }
  }

  // تحديث سجل صيانة
  Future<void> updateMaintenanceLog(
      String logId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('maintenanceLogs')
          .doc(logId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // حذف سجل صيانة
  Future<void> deleteMaintenanceLog(String logId) async {
    try {
      await _firestore
          .collection('maintenanceLogs')
          .doc(logId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // توليد ID جديد
  String generateId() => _uuid.v4();
}