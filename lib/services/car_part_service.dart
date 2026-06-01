import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_part_model.dart';

class CarPartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'carParts';

  /// جلب كل قطع سيارة معينة
  Stream<List<CarPartModel>> getCarParts(String carId) {
    return _firestore
        .collection(_collection)
        .where('carId', isEqualTo: carId)
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final parts =
          snap.docs.map((d) => CarPartModel.fromMap(d.data())).toList();
      // ترتيب حسب الأولوية: overdue أول ثم dueSoon ثم ok
      // (الترتيب الفعلي يتم في الـ widget بعد ما يعرف العداد الحالي)
      return parts;
    });
  }

  /// إضافة أو تحديث قطعة
  Future<void> upsertPart(CarPartModel part) async {
    await _firestore
        .collection(_collection)
        .doc(part.partId)
        .set(part.toMap(), SetOptions(merge: true));
  }

  /// إضافة القطع الافتراضية لسيارة جديدة (لو مش موجودة)
  Future<void> initDefaultParts(String carId, double currentOdometer) async {
    final existing = await _firestore
        .collection(_collection)
        .where('carId', isEqualTo: carId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // already initialized

    final parts = defaultPartsFor(carId, currentOdometer);
    final batch = _firestore.batch();
    for (final part in parts) {
      final ref = _firestore.collection(_collection).doc(part.partId);
      batch.set(ref, part.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// تحديث قطعة بعد عمل صيانة عليها
  Future<void> markServiced({
    required String partId,
    required double currentOdometer,
  }) async {
    final doc = await _firestore.collection(_collection).doc(partId).get();
    if (!doc.exists) return;

    final part = CarPartModel.fromMap(doc.data()!);
    final now = DateTime.now();

    final updatedPart = part.copyWith(
      lastServiceOdometer: currentOdometer,
      lastServiceDate: now,
      nextDueOdometer: part.intervalKm != null
          ? currentOdometer + part.intervalKm!
          : null,
      nextDueDate: part.intervalDays != null
          ? now.add(Duration(days: part.intervalDays!))
          : null,
      updatedAt: now,
    );

    await _firestore
        .collection(_collection)
        .doc(partId)
        .update(updatedPart.toMap());
  }

  /// تحديث قطعة من سجل خدمة (ربط add_service_screen بنظام القطع)
  Future<void> upsertFromServiceTitle({
    required String carId,
    required String serviceTitle,
    required double currentOdometer,
    required double? intervalKm,
    required int? intervalDays,
    required double? nextDueOdometer,
    required DateTime? nextDueDate,
  }) async {
    final partId =
        '${carId}_${serviceTitle.trim().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '')}';

    final existing = await _firestore.collection(_collection).doc(partId).get();
    final now = DateTime.now();

    // نحدد الـ category من اسم القطعة
    String category = _guessCategoryFromTitle(serviceTitle);

    final part = CarPartModel(
      partId: partId,
      carId: carId,
      name: serviceTitle.trim(),
      category: category,
      intervalKm: intervalKm,
      intervalDays: intervalDays,
      lastServiceOdometer: currentOdometer,
      lastServiceDate: now,
      nextDueOdometer: nextDueOdometer,
      nextDueDate: nextDueDate,
      enabled: true,
      updatedAt: now,
    );

    await _firestore
        .collection(_collection)
        .doc(partId)
        .set(part.toMap(), SetOptions(merge: true));
  }

  /// تعطيل قطعة (soft delete)
  Future<void> disablePart(String partId) async {
    await _firestore.collection(_collection).doc(partId).update({
      'enabled': false,
      'updatedAt': DateTime.now(),
    });
  }

  String _guessCategoryFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('زيت') || t.contains('فلتر') || t.contains('بوجيه') ||
        t.contains('تبريد')) return 'engine';
    if (t.contains('فرامل') || t.contains('تيل')) return 'brakes';
    if (t.contains('إطار') || t.contains('طار')) return 'tires';
    if (t.contains('بطارية') || t.contains('كهرب')) return 'electrical';
    if (t.contains('فتيس') || t.contains('سائل')) return 'fluids';
    return 'other';
  }
}
