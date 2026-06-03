import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_part_model.dart';

class CarPartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'carParts';

  Stream<List<CarPartModel>> getCarParts(String carId) {
    return _firestore
        .collection(_collection)
        .where('carId', isEqualTo: carId)
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final parts =
          snap.docs.map((d) => CarPartModel.fromMap(d.data())).toList();
      return parts;
    });
  }

  Future<void> upsertPart(CarPartModel part) async {
    await _firestore
        .collection(_collection)
        .doc(part.partId)
        .set(part.toMap(), SetOptions(merge: true));
  }

  Future<void> initDefaultParts(String carId, double currentOdometer) async {
    final existing = await _firestore
        .collection(_collection)
        .where('carId', isEqualTo: carId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final parts = defaultPartsFor(carId, currentOdometer);
    final batch = _firestore.batch();
    for (final part in parts) {
      final ref = _firestore.collection(_collection).doc(part.partId);
      batch.set(ref, part.toMap());
    }
    await batch.commit();
  }

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

  Future<void> upsertFromServiceTitle({
    required String carId,
    required String serviceTitle,
    required double currentOdometer,
    required double? intervalKm,
    required int? intervalDays,
    required double? nextDueOdometer,
    required DateTime? nextDueDate,
  }) async {
    final exactPartId =
        '${carId}_${serviceTitle.trim().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '')}';

    final now = DateTime.now();
    final category = _guessCategoryFromTitle(serviceTitle);

    final exactDoc =
        await _firestore.collection(_collection).doc(exactPartId).get();

    String? resolvedDocId;

    if (exactDoc.exists) {
      resolvedDocId = exactPartId;
    } else {
      final allParts = await _firestore
          .collection(_collection)
          .where('carId', isEqualTo: carId)
          .where('enabled', isEqualTo: true)
          .get();

      String? bestMatch;
      int bestScore = 0;
      final titleKeywords = _extractKeywords(serviceTitle);

      for (final doc in allParts.docs) {
        final partName = (doc.data()['name'] as String?) ?? '';
        final partKeywords = _extractKeywords(partName);
        final overlap =
            titleKeywords.intersection(partKeywords).length;
        if (overlap > bestScore) {
          bestScore = overlap;
          bestMatch = doc.id;
        }
      }

      if (bestScore >= 1 && bestMatch != null) {
        resolvedDocId = bestMatch;
      }
    }

    if (resolvedDocId != null) {
      final updateData = <String, dynamic>{
        'lastServiceOdometer': currentOdometer,
        'lastServiceDate': now,
        'updatedAt': now,
      };
      if (intervalKm != null) updateData['intervalKm'] = intervalKm;
      if (intervalDays != null) updateData['intervalDays'] = intervalDays;
      if (nextDueOdometer != null) updateData['nextDueOdometer'] = nextDueOdometer;
      if (nextDueDate != null) updateData['nextDueDate'] = nextDueDate;
      await _firestore
          .collection(_collection)
          .doc(resolvedDocId)
          .update(updateData);
    } else {
      final part = CarPartModel(
        partId: exactPartId,
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
          .doc(exactPartId)
          .set(part.toMap());
    }
  }

  Set<String> _extractKeywords(String text) {
    const stopWords = {
      'تغيير', 'تبديل', 'فحص', 'تحويل', 'عمل', 'تنظيف', 'إصلاح', 'صيانة',
    };
    return text
        .split(' ')
        .map((w) => w.trim().replaceAll(RegExp(r'^ال'), ''))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toSet();
  }

  Future<void> disablePart(String partId) async {
    await _firestore.collection(_collection).doc(partId).update({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
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
