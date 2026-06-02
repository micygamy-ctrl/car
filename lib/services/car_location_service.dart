import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CarLocationService {
  static const String _latKey = 'car_lat';
  static const String _lngKey = 'car_lng';
  static const String _timeKey = 'car_time';

  // حفظ مكان العربية الحالي
  static Future<bool> saveCarLocation() async {
    try {
      bool hasPermission = await _checkPermission();
      if (!hasPermission) return false;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);
      await prefs.setString(_timeKey, DateTime.now().toString());

      return true;
    } catch (e) {
      return false;
    }
  }

  // فتح Google Maps على مكان العربية
  static Future<void> openCarInMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(_latKey);
    final double? lng = prefs.getDouble(_lngKey);

    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // جلب بيانات آخر موقع محفوظ
  static Future<Map<String, dynamic>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(_latKey);
    final double? lng = prefs.getDouble(_lngKey);
    final String? time = prefs.getString(_timeKey);
    if (lat == null) return null;
    return {'lat': lat, 'lng': lng, 'time': time};
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