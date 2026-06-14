import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String tripId;
  final String carId;
  final String driverId;
  final String driverName;
  final double startOdometer;
  final double? endOdometer;
  final double? distanceKm;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status; // 'completed'

  const TripModel({
    required this.tripId,
    required this.carId,
    required this.driverId,
    required this.driverName,
    required this.startOdometer,
    this.endOdometer,
    this.distanceKm,
    this.startTime,
    this.endTime,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'carId': carId,
      'driverId': driverId,
      'driverName': driverName,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'distanceKm': distanceKm,
      'startTime':
          startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      tripId: map['tripId'] ?? '',
      carId: map['carId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      startOdometer: (map['startOdometer'] ?? 0).toDouble(),
      endOdometer: map['endOdometer'] != null
          ? (map['endOdometer'] as num).toDouble()
          : null,
      distanceKm: map['distanceKm'] != null
          ? (map['distanceKm'] as num).toDouble()
          : null,
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'completed',
    );
  }

  Duration get duration {
    if (startTime == null || endTime == null) return Duration.zero;
    return endTime!.difference(startTime!);
  }
}
