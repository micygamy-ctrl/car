import 'package:cloud_firestore/cloud_firestore.dart';

/// تصنيف حالة القطعة
enum PartStatus { ok, dueSoon, overdue }

/// نموذج قطعة السيارة
class CarPartModel {
  final String partId;
  final String carId;
  final String name;
  final String category; // engine, brakes, tires, fluids, electrical, other
  final double? intervalKm;
  final int? intervalDays;
  final double? lastServiceOdometer;
  final DateTime? lastServiceDate;
  final double? nextDueOdometer;
  final DateTime? nextDueDate;
  final bool enabled;
  final DateTime updatedAt;

  const CarPartModel({
    required this.partId,
    required this.carId,
    required this.name,
    required this.category,
    this.intervalKm,
    this.intervalDays,
    this.lastServiceOdometer,
    this.lastServiceDate,
    this.nextDueOdometer,
    this.nextDueDate,
    required this.enabled,
    required this.updatedAt,
  });

  /// حساب الكيلومترات الباقية
  double? kmRemaining(double currentOdometer) {
    if (nextDueOdometer == null) return null;
    return nextDueOdometer! - currentOdometer;
  }

  /// حساب الأيام الباقية
  int? daysRemaining() {
    if (nextDueDate == null) return null;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  /// حالة القطعة بناءً على العداد أو التاريخ
  PartStatus status(double currentOdometer) {
    final km = kmRemaining(currentOdometer);
    final days = daysRemaining();

    if ((km != null && km <= 0) || (days != null && days < 0)) {
      return PartStatus.overdue;
    }
    if ((km != null && km <= 500) || (days != null && days <= 30)) {
      return PartStatus.dueSoon;
    }
    return PartStatus.ok;
  }

  /// نسبة التقدم (0.0 → 1.0) لشريط التقدم
  double progress(double currentOdometer) {
    if (lastServiceOdometer != null && nextDueOdometer != null) {
      final interval = nextDueOdometer! - lastServiceOdometer!;
      if (interval <= 0) return 1.0;
      final driven = currentOdometer - lastServiceOdometer!;
      return (driven / interval).clamp(0.0, 1.0);
    }
    if (lastServiceDate != null && nextDueDate != null) {
      final totalDays =
          nextDueDate!.difference(lastServiceDate!).inDays.toDouble();
      if (totalDays <= 0) return 1.0;
      final elapsed =
          DateTime.now().difference(lastServiceDate!).inDays.toDouble();
      return (elapsed / totalDays).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'carId': carId,
      'name': name,
      'category': category,
      'intervalKm': intervalKm,
      'intervalDays': intervalDays,
      'lastServiceOdometer': lastServiceOdometer,
      'lastServiceDate': lastServiceDate,
      'nextDueOdometer': nextDueOdometer,
      'nextDueDate': nextDueDate,
      'enabled': enabled,
      'updatedAt': updatedAt,
    };
  }

  factory CarPartModel.fromMap(Map<String, dynamic> map) {
    return CarPartModel(
      partId: map['partId'] ?? '',
      carId: map['carId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'other',
      intervalKm: map['intervalKm']?.toDouble(),
      intervalDays: map['intervalDays'],
      lastServiceOdometer: map['lastServiceOdometer']?.toDouble(),
      lastServiceDate: _dateFrom(map['lastServiceDate']),
      nextDueOdometer: map['nextDueOdometer']?.toDouble(),
      nextDueDate: _dateFrom(map['nextDueDate']),
      enabled: map['enabled'] ?? true,
      updatedAt: _dateFrom(map['updatedAt']) ?? DateTime.now(),
    );
  }

  CarPartModel copyWith({
    double? lastServiceOdometer,
    DateTime? lastServiceDate,
    double? nextDueOdometer,
    DateTime? nextDueDate,
    DateTime? updatedAt,
  }) {
    return CarPartModel(
      partId: partId,
      carId: carId,
      name: name,
      category: category,
      intervalKm: intervalKm,
      intervalDays: intervalDays,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextDueOdometer: nextDueOdometer ?? this.nextDueOdometer,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      enabled: enabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _dateFrom(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

/// القطع الافتراضية لأي سيارة جديدة
List<CarPartModel> defaultPartsFor(String carId, double currentOdometer) {
  final now = DateTime.now();

  final parts = [
    ('تغيير زيت الموتور', 'engine', 5000, 180),
    ('تغيير فلتر الزيت', 'engine', 5000, 180),
    ('تغيير فلتر الهواء', 'engine', 10000, 365),
    ('تغيير فلتر التكييف', 'other', 10000, 365),
    ('تغيير بوجيهات', 'engine', 30000, 730),
    ('تغيير تيل الفرامل', 'brakes', 20000, 730),
    ('تغيير زيت الفتيس', 'fluids', 60000, 1095),
    ('تغيير سائل التبريد', 'fluids', 40000, 730),
    ('تغيير البطارية', 'electrical', 0, 730),
    ('تغيير الإطارات', 'tires', 50000, 1460),
    ('تغيير زيت الباور', 'fluids', 60000, 1095),
    ('تغيير فلتر الوقود', 'engine', 60000, 1095),
  ];

  return parts.map((p) {
    final name = p.$1;
    final cat = p.$2;
    final km = p.$3;
    final days = p.$4;
    final partId =
    '${carId}_${name.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '')}';

    return CarPartModel(
      partId: partId,
      carId: carId,
      name: name,
      category: cat,
      intervalKm: km > 0 ? km.toDouble() : null,
      intervalDays: days,
      lastServiceOdometer: currentOdometer,
      lastServiceDate: now,
      nextDueOdometer: km > 0 ? currentOdometer + km : null,
      nextDueDate: now.add(Duration(days: days)),
      enabled: true,
      updatedAt: now,
    );
  }).toList();
}
