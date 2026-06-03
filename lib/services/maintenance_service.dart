import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_log_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> addServiceLog(ServiceLogModel log) async {
    try {
      await _firestore.collection('serviceLogs').doc(log.logId).set(log.toMap());
    } catch (e) { rethrow; }
  }

  Future<void> addMaintenanceLog(ServiceLogModel log) => addServiceLog(log);

  Stream<List<ServiceLogModel>> getCarMaintenanceLogs(String carId) {
    return _firestore
        .collection('serviceLogs')
        .where('carId', isEqualTo: carId)
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs.map((doc) => ServiceLogModel.fromMap(doc.data())).toList();
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs;
    });
  }

  Stream<List<ServiceLogModel>> getUpcomingReminders(String carId) {
    return _firestore
        .collection('serviceLogs')
        .where('carId', isEqualTo: carId)
        .where('reminderSent', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final logs = snapshot.docs
          .map((doc) => ServiceLogModel.fromMap(doc.data()))
          .where((log) {
        if (log.expiryDate != null) {
          final daysLeft = log.expiryDate!.difference(now).inDays;
          return daysLeft <= 30 && daysLeft >= 0;
        }
        return false;
      }).toList();
      logs.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
      return logs;
    });
  }

  Future<void> updateServiceLog(String logId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('serviceLogs').doc(logId).update(data);
    } catch (e) { rethrow; }
  }

  Future<void> deleteMaintenanceLog(String logId) async {
    try {
      await _firestore.collection('serviceLogs').doc(logId).delete();
    } catch (e) { rethrow; }
  }

  Future<void> markReminderSent(String logId) async {
    try {
      await _firestore.collection('serviceLogs').doc(logId).update({'reminderSent': true});
    } catch (e) { rethrow; }
  }

  String generateId() => _uuid.v4();
}
