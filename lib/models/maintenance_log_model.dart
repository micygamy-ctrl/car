import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceLogModel {
  final String logId;
  final String carId;
  final String category;
  final String title;
  final DateTime date;
  final double cost;
  final String? notes;
  final String status;
  final bool reminderSent;
  final double? odometer;
  final String? garage;
  final double? nextDueOdometer;
  final DateTime? expiryDate;
  final String? provider;
  final String? violationNumber;
  final String? violationLocation;

  ServiceLogModel({
    required this.logId,
    required this.carId,
    required this.category,
    required this.title,
    required this.date,
    required this.cost,
    this.notes,
    required this.status,
    required this.reminderSent,
    this.odometer,
    this.garage,
    this.nextDueOdometer,
    this.expiryDate,
    this.provider,
    this.violationNumber,
    this.violationLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'carId': carId,
      'category': category,
      'title': title,
      'date': date,
      'cost': cost,
      'notes': notes,
      'status': status,
      'reminderSent': reminderSent,
      'odometer': odometer,
      'garage': garage,
      'nextDueOdometer': nextDueOdometer,
      'expiryDate': expiryDate,
      'provider': provider,
      'violationNumber': violationNumber,
      'violationLocation': violationLocation,
    };
  }

  factory ServiceLogModel.fromMap(Map<String, dynamic> map) {
    return ServiceLogModel(
      logId: map['logId'] ?? '',
      carId: map['carId'] ?? '',
      category: map['category'] ?? 'maintenance',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      cost: (map['cost'] ?? 0).toDouble(),
      notes: map['notes'],
      status: map['status'] ?? 'done',
      reminderSent: map['reminderSent'] ?? false,
      odometer: map['odometer']?.toDouble(),
      garage: map['garage'],
      nextDueOdometer: map['nextDueOdometer']?.toDouble(),
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      provider: map['provider'],
      violationNumber: map['violationNumber'],
      violationLocation: map['violationLocation'],
    );
  }
}

typedef MaintenanceLogModel = ServiceLogModel;