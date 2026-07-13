import 'package:car/models/car_model.dart';
import 'package:car/models/fuel_log_model.dart';
import 'package:car/models/maintenance_log_model.dart';

/// يبني CarModel صالح للاختبارات بأقل عدد من الباراميترات المطلوبة،
/// مع إمكانية تخصيص أي حقل حسب الاختبار.
CarModel buildTestCar({
  required String carId,
  required String ownerId,
  String make = 'تويوتا',
  String model = 'كورولا',
  int year = 2022,
  String licensePlate = 'أ ب ج 1234',
  double currentOdometer = 10000,
  String fuelType = 'petrol',
  double tankCapacity = 50,
  double oilChangeInterval = 5000,
  double? lastOilChangeOdometer,
}) {
  return CarModel(
    carId: carId,
    ownerId: ownerId,
    make: make,
    model: model,
    year: year,
    licensePlate: licensePlate,
    currentOdometer: currentOdometer,
    fuelType: fuelType,
    tankCapacity: tankCapacity,
    oilChangeInterval: oilChangeInterval,
    lastOilChangeOdometer: lastOilChangeOdometer ?? currentOdometer,
  );
}

/// يبني FuelLogModel صالح للاختبارات
FuelLogModel buildTestFuelLog({
  required String logId,
  required String carId,
  DateTime? date,
  double odometer = 10000,
  String odometerSource = 'manual',
  double fuelAmount = 30,
  double pricePerUnit = 15,
  double? totalCost,
  bool isFullTank = true,
  double? calculatedEfficiency,
}) {
  return FuelLogModel(
    logId: logId,
    carId: carId,
    date: date ?? DateTime.now(),
    odometer: odometer,
    odometerSource: odometerSource,
    fuelAmount: fuelAmount,
    pricePerUnit: pricePerUnit,
    totalCost: totalCost ?? fuelAmount * pricePerUnit,
    isFullTank: isFullTank,
    calculatedEfficiency: calculatedEfficiency,
  );
}

/// يبني ServiceLogModel صالح للاختبارات
ServiceLogModel buildTestServiceLog({
  required String logId,
  required String carId,
  String category = 'maintenance',
  String title = 'تغيير زيت',
  DateTime? date,
  double cost = 250,
  String status = 'done',
  bool reminderSent = false,
  DateTime? expiryDate,
}) {
  return ServiceLogModel(
    logId: logId,
    carId: carId,
    category: category,
    title: title,
    date: date ?? DateTime.now(),
    cost: cost,
    status: status,
    reminderSent: reminderSent,
    expiryDate: expiryDate,
  );
}