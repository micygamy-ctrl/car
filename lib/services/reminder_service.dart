import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car_model.dart';
import '../models/maintenance_log_model.dart';
import 'notification_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // بيتحقق إذا كان اليوم اتعملتله فحص قبل كده
  Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('last_reminder_check');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastCheck == today) return false;
    await prefs.setString('last_reminder_check', today);
    return true;
  }

  // الدالة الرئيسية — بتفحص كل السيارات بتاعت المستخدم
  Future<void> runDailyCheck(String userId) async {
    final shouldCheck = await _shouldCheck();
    if (!shouldCheck) return;

    try {
      // جلب كل السيارات بتاعت المستخدم
      final carsSnapshot = await _firestore
          .collection('cars')
          .where('ownerId', isEqualTo: userId)
          .get();

      for (final doc in carsSnapshot.docs) {
        final car = CarModel.fromMap(doc.data());
        await _checkCar(car);
      }
    } catch (e) {
      // تجاهل الأخطاء عشان ما توقفش البرنامج
    }
  }

  Future<void> _checkCar(CarModel car) async {
    final carName = '${car.make} ${car.model}';

    // 1. فحص تغيير الزيت
    await NotificationService().checkOilChangeReminder(
      carId: car.carId,
      carName: carName,
      currentOdometer: car.currentOdometer,
      lastOilChangeOdometer: car.lastOilChangeOdometer,
      oilChangeInterval: car.oilChangeInterval,
    );

    // 2. جلب سجلات الخدمات وفحصها
    try {
      final logsSnapshot = await _firestore
          .collection('serviceLogs')
          .where('carId', isEqualTo: car.carId)
          .get();

      final logs = logsSnapshot.docs
          .map((doc) => ServiceLogModel.fromMap(doc.data()))
          .toList();

      // 3. فحص التواريخ
      await NotificationService().checkExpiryReminders(
        carId: car.carId,
        carName: carName,
        logs: logs,
      );

      // 4. فحص الكيلومترات
      await NotificationService().checkOdometerReminders(
        carId: car.carId,
        carName: carName,
        currentOdometer: car.currentOdometer,
        logs: logs,
      );
    } catch (e) {
      // تجاهل
    }
  }
}