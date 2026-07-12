import 'package:car/models/car_model.dart';

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