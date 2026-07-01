import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// نموذج بيانات المكان (محطة وقود أو ورشة)
class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingsTotal;
  final bool isOpen;
  final String type; // 'gas_station' أو 'car_repair'

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    required this.isOpen,
    required this.type,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json, String type) {
    final location = json['geometry']['location'];
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['vicinity'] ?? '',
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      isOpen: json['opening_hours']?['open_now'] ?? true,
      type: type,
    );
  }

  LatLng get latLng => LatLng(lat, lng);
}

class MapService {
  // المفتاح بيُمرر وقت البناء عن طريق --dart-define، مش مكتوب هنا مباشرة.
  // ده بيمنع ظهوره كـ نص صريح في الكود المرفوع على GitHub، وبيقلل (لكن
  // لا يمنع تمامًا) ظهوره الواضح لو حد فك تشفير الـ APK.
  // طريقة التشغيل/البناء:
  //   flutter run --dart-define=GOOGLE_PLACES_API_KEY=مفتاحك_هنا
  //   flutter build apk --dart-define=GOOGLE_PLACES_API_KEY=مفتاحك_هنا
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');

  /// هل تم تمرير مفتاح فعلي وقت البناء؟
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// طلب إذن الموقع والحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// البحث عن أماكن بالنوع ونصف القطر (بالمتر)
  Future<List<PlaceModel>> searchNearby({
    required double lat,
    required double lng,
    required String type, // 'gas_station' أو 'car_repair'
    int radius = 3000,
  }) async {
    if (!isConfigured) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=$type'
      '&language=ar'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((json) => PlaceModel.fromJson(json, type))
              .toList();
        }
      }
    } catch (e) {
      // يمكن إضافة logging هنا
    }
    return [];
  }

  /// البحث عن محطات الوقود والورش معاً
  Future<List<PlaceModel>> searchAll({
    required double lat,
    required double lng,
    int radius = 3000,
  }) async {
    final results = await Future.wait([
      searchNearby(lat: lat, lng: lng, type: 'gas_station', radius: radius),
      searchNearby(lat: lat, lng: lng, type: 'car_repair', radius: radius),
    ]);
    return [...results[0], ...results[1]];
  }
}
