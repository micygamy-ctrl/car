import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car_model.dart';
import '../models/car_part_model.dart';
import '../models/maintenance_log_model.dart';
import 'notification_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // بيتحقق إذا كان اليوم اتعملتله فحص قبل كده — key خاص بكل مستخدم
  Future<bool> _shouldCheck(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_reminder_check_$userId';
    final lastCheck = prefs.getString(key);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastCheck == today) return false;
    await prefs.setString(key, today);
    return true;
  }

  // الدالة الرئيسية — بتفحص كل السيارات (مملوكة + منضم إليها كسائق)
  Future<void> runDailyCheck(String userId) async {
    final shouldCheck = await _shouldCheck(userId);
    if (!shouldCheck) return;

    try {
      // جلب السيارات المملوكة + السيارات اللي المستخدم سواق فيها بالتوازي
      final results = await Future.wait([
        _firestore.collection('cars').where('ownerId', isEqualTo: userId).get(),
        _firestore
            .collection('carMembers')
            .where('userId', isEqualTo: userId)
            .get(),
      ]);

      final Set<String> checkedCarIds = {};
      final List<CarModel> allCars = [];

      // السيارات المملوكة
      for (final doc in results[0].docs) {
        final car = CarModel.fromMap(doc.data());
        if (checkedCarIds.add(car.carId)) allCars.add(car);
      }

      // السيارات اللي انضملها كسائق
      final memberDocs = results[1].docs;
      if (memberDocs.isNotEmpty) {
        final carSnaps = await Future.wait(
          memberDocs.map((d) {
            final carId = d.data()['carId'] as String? ?? '';
            return _firestore.collection('cars').doc(carId).get();
          }),
        );
        for (final snap in carSnaps) {
          if (!snap.exists) continue;
          final car = CarModel.fromMap(snap.data()!);
          if (checkedCarIds.add(car.carId)) allCars.add(car);
        }
      }

      for (final car in allCars) {
        await _checkCar(car);
      }
    } catch (e) {
      // تجاهل الأخطاء عشان ما توقفش البرنامج
    }
  }

  Future<void> _checkCar(CarModel car) async {
    final carName = '${car.make} ${car.model}';
    final notif = NotificationService();

    // 1. فحص تغيير الزيت
    await notif.checkOilChangeReminder(
      carId: car.carId,
      carName: carName,
      currentOdometer: car.currentOdometer,
      lastOilChangeOdometer: car.lastOilChangeOdometer,
      oilChangeInterval: car.oilChangeInterval,
    );

    // 2. جلب سجلات الخدمات وقطع السيارة بالتوازي
    try {
      final results = await Future.wait([
        _firestore
            .collection('serviceLogs')
            .where('carId', isEqualTo: car.carId)
            .get(),
        _firestore
            .collection('carParts')
            .where('carId', isEqualTo: car.carId)
            .where('enabled', isEqualTo: true)
            .get(),
      ]);

      final logs = results[0]
          .docs
          .map((doc) => ServiceLogModel.fromMap(doc.data()))
          .toList();

      final parts = results[1]
          .docs
          .map((doc) => CarPartModel.fromMap(doc.data()))
          .toList();

      // 3. فحص التواريخ (سجلات الخدمات)
      await notif.checkExpiryReminders(
        carId: car.carId,
        carName: carName,
        logs: logs,
      );

      // 4. فحص الكيلومترات (سجلات الخدمات)
      await notif.checkOdometerReminders(
        carId: car.carId,
        carName: carName,
        currentOdometer: car.currentOdometer,
        logs: logs,
      );

      // 5. فحص قطع السيارة (carParts collection)
      await notif.checkCarPartsReminders(
        carId: car.carId,
        carName: carName,
        currentOdometer: car.currentOdometer,
        parts: parts,
      );
    } catch (e) {
      // تجاهل
    }
  }
}
