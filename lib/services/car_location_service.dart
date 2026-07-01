import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمة "أين عربيتي؟" - بتحفظ آخر موقع وقفت فيه العربية في Firestore
/// (على وثيقة السيارة نفسها) عشان أي سواق أو المالك يقدر يشوفه من أي جهاز.
class CarLocationService {
  static final _firestore = FirebaseFirestore.instance;

  /// حفظ الموقع الحالي كمكان وقوف العربية
  static Future<bool> saveCarLocation(String carId) async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) return false;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _firestore.collection('cars').doc(carId).update({
        'parkedLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'savedAt': Timestamp.now(),
        },
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// جلب بيانات آخر موقع محفوظ للعربية
  static Future<Map<String, dynamic>?> getSavedLocation(String carId) async {
    final doc = await _firestore.collection('cars').doc(carId).get();
    final data = doc.data();
    final loc = data?['parkedLocation'] as Map<String, dynamic>?;
    if (loc == null || loc['lat'] == null || loc['lng'] == null) return null;

    final savedAt = loc['savedAt'];
    DateTime? time;
    if (savedAt is Timestamp) time = savedAt.toDate();

    return {
      'lat': (loc['lat'] as num).toDouble(),
      'lng': (loc['lng'] as num).toDouble(),
      'time': time,
    };
  }

  /// فتح Google Maps على مكان العربية المحفوظ
  static Future<void> openCarInMaps(String carId) async {
    final loc = await getSavedLocation(carId);
    if (loc == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${loc['lat']},${loc['lng']}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }
}
