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
    required CarPartModel part,
    required double currentOdometer,
  }) async {
    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'lastServiceOdometer': currentOdometer,
      'lastServiceDate': now,
      'updatedAt': now,
      'nextDueOdometer':
          part.intervalKm != null ? currentOdometer + part.intervalKm! : null,
      'nextDueDate': part.intervalDays != null
          ? now.add(Duration(days: part.intervalDays!))
          : null,
    };
    await _firestore
        .collection(_collection)
        .doc(part.partId)
        .update(updateData);
  }

  /// مجموعات كلمات مرادفة لتحديد "نوع" القطعة بغض النظر عن صيغة الاسم
  /// (مثلاً "زيت المحرك" و"تغيير زيت الموتور" لازم يُعتبروا نفس القطعة)
  static const Map<String, List<String>> _conceptGroups = {
    'oil': ['زيت'],
    'filter': ['فلتر', 'فلاتر'],
    'engine': ['محرك', 'موتور'],
    'air': ['هواء'],
    'fuel': ['وقود', 'بنزين', 'سولار', 'بترول'],
    'ac': ['تكييف'],
    'spark': ['بوجيه', 'شمعات', 'شمعة'],
    'brake': ['فرامل', 'تيل'],
    'transmission': ['فتيس', 'جير', 'ناقل'],
    'coolant': ['تبريد', 'مويه', 'مياه'],
    'battery': ['بطاري'],
    'tire': ['اطار', 'إطار', 'كاوتش', 'عجل'],
    'power': ['باور', 'دركسيون'],
    'timing': ['توقيت', 'تايمنج', 'سير', 'سيور'],
  };

  /// يحوّل اسم القطعة/عنوان الخدمة لمجموعة "مفاهيم" (مثلاً {oil, engine})
  /// عشان نقدر نقارن قطعتين بمعنى واحد حتى لو الصياغة مختلفة
  Set<String> _conceptsOf(String text) {
    final result = <String>{};
    for (final entry in _conceptGroups.entries) {
      for (final word in entry.value) {
        if (text.contains(word)) {
          result.add(entry.key);
          break;
        }
      }
    }
    return result;
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

    final updateData = <String, dynamic>{
      'lastServiceOdometer': currentOdometer,
      'lastServiceDate': now,
      'updatedAt': now,
    };
    if (intervalKm != null) updateData['intervalKm'] = intervalKm;
    if (intervalDays != null) updateData['intervalDays'] = intervalDays;
    if (nextDueOdometer != null)
      updateData['nextDueOdometer'] = nextDueOdometer;
    if (nextDueDate != null) updateData['nextDueDate'] = nextDueDate;

    // 1) أول حاجة: نشوف هل في قطعة موجودة بنفس "المفهوم" (زيت+محرك مثلًا)
    //    حتى لو الاسم متكتب بصيغة مختلفة عن عنوان الخدمة
    final newConcepts = _conceptsOf(serviceTitle);
    if (newConcepts.isNotEmpty) {
      final existingParts = await _firestore
          .collection(_collection)
          .where('carId', isEqualTo: carId)
          .get();

      for (final doc in existingParts.docs) {
        final part = CarPartModel.fromMap(doc.data());
        if (_conceptsOf(part.name).difference(newConcepts).isEmpty &&
            newConcepts.difference(_conceptsOf(part.name)).isEmpty) {
          await _firestore
              .collection(_collection)
              .doc(part.partId)
              .update(updateData);
          return;
        }
      }
    }

    // 2) نحاول تحديث القطعة الموجودة بنفس الـ ID (توافقًا مع البيانات القديمة)
    final exactDoc =
        await _firestore.collection(_collection).doc(exactPartId).get();

    if (exactDoc.exists) {
      await _firestore
          .collection(_collection)
          .doc(exactPartId)
          .update(updateData);
    } else {
      // إنشاء قطعة جديدة مباشرة بدون البحث في كل القطع
      final newPart = CarPartModel(
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
          .set(newPart.toMap());
    }
  }

  Future<void> disablePart(String partId) async {
    await _firestore.collection(_collection).doc(partId).update({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _guessCategoryFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('زيت') ||
        t.contains('فلتر') ||
        t.contains('بوجيه') ||
        t.contains('تبريد')) return 'engine';
    if (t.contains('فرامل') || t.contains('تيل')) return 'brakes';
    if (t.contains('إطار') || t.contains('طار')) return 'tires';
    if (t.contains('بطارية') || t.contains('كهرب')) return 'electrical';
    if (t.contains('فتيس') || t.contains('سائل')) return 'fluids';
    return 'other';
  }
}
