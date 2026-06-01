class CarModel {
  final String carId;
  final String ownerId;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final double currentOdometer;
  final String fuelType;
  final double tankCapacity;
  final double oilChangeInterval;
  final double lastOilChangeOdometer;
  final String? photoUrl;
  final int? engineCc; // 1. تم إضافة المتغير هنا كقيمة اختيارية

  CarModel({
    required this.carId,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.currentOdometer,
    required this.fuelType,
    required this.tankCapacity,
    required this.oilChangeInterval,
    required this.lastOilChangeOdometer,
    this.photoUrl,
    this.engineCc, // 2. تم إضافته هنا داخل الـ Constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'ownerId': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'currentOdometer': currentOdometer,
      'fuelType': fuelType,
      'tankCapacity': tankCapacity,
      'oilChangeInterval': oilChangeInterval,
      'lastOilChangeOdometer': lastOilChangeOdometer,
      'photoUrl': photoUrl,
      'engineCc': engineCc, // 3. تم إضافته هنا ليتم حفظه في قاعدة البيانات
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      carId: map['carId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      licensePlate: map['licensePlate'] ?? '',
      currentOdometer: (map['currentOdometer'] ?? 0).toDouble(),
      fuelType: map['fuelType'] ?? 'petrol',
      tankCapacity: (map['tankCapacity'] ?? 0).toDouble(),
      oilChangeInterval: (map['oilChangeInterval'] ?? 5000).toDouble(),
      lastOilChangeOdometer: (map['lastOilChangeOdometer'] ?? 0).toDouble(),
      photoUrl: map['photoUrl'],
      engineCc: map['engineCc'] as int?, // 4. تم إضافته هنا لاسترجاعه من قاعدة البيانات دون مشاكل
    );
  }
}