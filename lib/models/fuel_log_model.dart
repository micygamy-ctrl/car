class FuelLogModel {
  final String logId;
  final String carId;
  final DateTime date;
  final double odometer;
  final String odometerSource;
  final double fuelAmount;
  final double pricePerUnit;
  final double totalCost;
  final bool isFullTank;
  final String? stationName;
  final double? calculatedEfficiency;
  final String? ocrImageUrl;
  final String? notes;

  FuelLogModel({
    required this.logId,
    required this.carId,
    required this.date,
    required this.odometer,
    required this.odometerSource,
    required this.fuelAmount,
    required this.pricePerUnit,
    required this.totalCost,
    required this.isFullTank,
    this.stationName,
    this.calculatedEfficiency,
    this.ocrImageUrl,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'carId': carId,
      'date': date,
      'odometer': odometer,
      'odometerSource': odometerSource,
      'fuelAmount': fuelAmount,
      'pricePerUnit': pricePerUnit,
      'totalCost': totalCost,
      'isFullTank': isFullTank,
      'stationName': stationName,
      'calculatedEfficiency': calculatedEfficiency,
      'ocrImageUrl': ocrImageUrl,
      'notes': notes,
    };
  }

  factory FuelLogModel.fromMap(Map<String, dynamic> map) {
    return FuelLogModel(
      logId: map['logId'] ?? '',
      carId: map['carId'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      odometer: (map['odometer'] ?? 0).toDouble(),
      odometerSource: map['odometerSource'] ?? 'manual',
      fuelAmount: (map['fuelAmount'] ?? 0).toDouble(),
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      isFullTank: map['isFullTank'] ?? true,
      stationName: map['stationName'],
      calculatedEfficiency: map['calculatedEfficiency']?.toDouble(),
      ocrImageUrl: map['ocrImageUrl'],
      notes: map['notes'],
    );
  }
}