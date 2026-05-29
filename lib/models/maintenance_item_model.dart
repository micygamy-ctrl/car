import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceItemModel {
  final String itemId;
  final String carId;
  final String title;
  final String category;
  final double? intervalKm;
  final int? intervalDays;
  final double? lastServiceOdometer;
  final DateTime? lastServiceDate;
  final double? nextDueOdometer;
  final DateTime? nextDueDate;
  final String? lastServiceLogId;
  final bool enabled;
  final DateTime updatedAt;

  const MaintenanceItemModel({
    required this.itemId,
    required this.carId,
    required this.title,
    required this.category,
    this.intervalKm,
    this.intervalDays,
    this.lastServiceOdometer,
    this.lastServiceDate,
    this.nextDueOdometer,
    this.nextDueDate,
    this.lastServiceLogId,
    required this.enabled,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'carId': carId,
      'title': title,
      'category': category,
      'intervalKm': intervalKm,
      'intervalDays': intervalDays,
      'lastServiceOdometer': lastServiceOdometer,
      'lastServiceDate': lastServiceDate,
      'nextDueOdometer': nextDueOdometer,
      'nextDueDate': nextDueDate,
      'lastServiceLogId': lastServiceLogId,
      'enabled': enabled,
      'updatedAt': updatedAt,
    };
  }

  factory MaintenanceItemModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceItemModel(
      itemId: map['itemId'] ?? '',
      carId: map['carId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'maintenance',
      intervalKm: map['intervalKm']?.toDouble(),
      intervalDays: map['intervalDays'],
      lastServiceOdometer: map['lastServiceOdometer']?.toDouble(),
      lastServiceDate: _dateFrom(map['lastServiceDate']),
      nextDueOdometer: map['nextDueOdometer']?.toDouble(),
      nextDueDate: _dateFrom(map['nextDueDate']),
      lastServiceLogId: map['lastServiceLogId'],
      enabled: map['enabled'] ?? true,
      updatedAt: _dateFrom(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
