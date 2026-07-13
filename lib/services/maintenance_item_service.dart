import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/maintenance_item_model.dart';
import '../models/maintenance_log_model.dart';

class MaintenanceItemService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  MaintenanceItemService({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  Stream<List<MaintenanceItemModel>> getCarMaintenanceItems(String carId) {
    return _firestore
        .collection('maintenanceItems')
        .where('carId', isEqualTo: carId)
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MaintenanceItemModel.fromMap(doc.data()))
          .toList();
      items.sort((a, b) => a.title.compareTo(b.title));
      return items;
    });
  }

  Future<void> upsertFromServiceLog({
    required ServiceLogModel log,
    double? intervalKm,
    int? intervalDays,
  }) async {
    if (log.category != 'maintenance') return;

    final itemId = _buildItemId(log.carId, log.title);
    final item = MaintenanceItemModel(
      itemId: itemId,
      carId: log.carId,
      title: log.title.trim(),
      category: log.category,
      intervalKm: intervalKm,
      intervalDays: intervalDays,
      lastServiceOdometer: log.odometer,
      lastServiceDate: log.date,
      nextDueOdometer: log.nextDueOdometer,
      nextDueDate: log.expiryDate,
      lastServiceLogId: log.logId,
      enabled: true,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('maintenanceItems')
        .doc(itemId)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> addCustomItem(MaintenanceItemModel item) async {
    await _firestore
        .collection('maintenanceItems')
        .doc(item.itemId)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> disableItem(String itemId) async {
    await _firestore.collection('maintenanceItems').doc(itemId).update({
      'enabled': false,
      'updatedAt': DateTime.now(),
    });
  }

  String generateId() => _uuid.v4();

  String _buildItemId(String carId, String title) {
    final normalized = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '');
    return '${carId}_$normalized';
  }
}
