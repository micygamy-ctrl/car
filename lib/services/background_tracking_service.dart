import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart' as fb;

import '../models/car_model.dart';
import 'notification_service.dart';

// ─── نتيجة التتبع ───
class TrackingResult {
  final double distanceKm;
  final double suggestedOdometer;
  TrackingResult({required this.distanceKm, required this.suggestedOdometer});
}

// ─── بيانات التتبع المباشر (للعداد المرئي) ───
class LiveTrackingData {
  final double speedKmh;
  final double distanceKm;
  final int elapsedSeconds;
  const LiveTrackingData({
    required this.speedKmh,
    required this.distanceKm,
    required this.elapsedSeconds,
  });
  static const zero =
      LiveTrackingData(speedKmh: 0, distanceKm: 0, elapsedSeconds: 0);
}

// ─── جلسة التتبع الداخلية ───
class _TrackingSession {
  final CarModel car;
  final DateTime startTime;
  Position? lastPosition;
  double totalDistanceMeters = 0;
  Timer? stationaryTimer;
  StreamSubscription<Position>? subscription;

  _TrackingSession(this.car) : startTime = DateTime.now();

  void cancelStationaryTimer() {
    stationaryTimer?.cancel();
    stationaryTimer = null;
  }
}

/// خدمة تتبع السيارة — Singleton
/// Passive Monitor: subscription مشترك واحد لكل السيارات (توفير بطارية)
/// Full Tracking: يوقف تلقائيًا بعد 5 دقائق وقوف ويُبلغ الـ UI
class BackgroundTrackingService {
  BackgroundTrackingService._private();
  static final BackgroundTrackingService _instance =
      BackgroundTrackingService._private();
  factory BackgroundTrackingService() => _instance;

  // ─── Full tracking ───
  final ValueNotifier<bool> backgroundEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<Set<String>> activeTrackings =
      ValueNotifier<Set<String>>(<String>{});
  final Map<String, _TrackingSession> _sessions = {};

  /// يُطلق عند انتهاء التتبع (يدوي أو تلقائي) ليعرض الـ UI النتيجة
  final ValueNotifier<MapEntry<String, TrackingResult>?> trackingCompleted =
      ValueNotifier(null);

  /// بيانات مباشرة للعداد المرئي (تتحدث مع كل قراءة GPS)
  final ValueNotifier<Map<String, LiveTrackingData>> liveTrackingData =
      ValueNotifier(<String, LiveTrackingData>{});

  /// السيارات التي تملك شاشة تحديث عداد مفتوحة حالياً
  /// (تمنع الهوم سكرين من عرض dialog مكرر)
  final Set<String> odometerScreenOpenCars = {};

  // ─── Passive monitor — ONE shared subscription ───
  final ValueNotifier<String?> movementDetectedForCar =
      ValueNotifier<String?>(null);

  StreamSubscription<Position>? _sharedPassiveSub;
  final Map<String, CarModel> _monitoredCars = {};
  final Map<String, int> _movementCounts = {};

  // ─── Constants ───
  static const double _minMovementMeters = 10;
  static const double _maxAcceptedAccuracyMeters = 50;
  static const double _maxReasonableSegmentMeters = 1000;
  static const double _stationarySpeedMs = 1.5;
  static const double _movementDetectionSpeedMs = 2.8;
  static const int _movementConfirmationCount = 2;
  static const Duration _stationaryTimeout = Duration(minutes: 5);

  // ─────────────────────────────────────
  //  Location settings
  // ─────────────────────────────────────
  LocationSettings get _fullLocationSettings {
    if (kIsWeb) {
      return const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5);
    }
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'تتبع العداد بالخلفية',
        notificationText: 'يتم حساب مسافة السيارة بالـ GPS.',
        notificationChannelName: 'تتبع العداد',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  }

  LocationSettings get _passiveLocationSettings {
    if (kIsWeb) {
      return const LocationSettings(
          accuracy: LocationAccuracy.medium, distanceFilter: 20);
    }
    return AndroidSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 20,
      intervalDuration: const Duration(seconds: 5),
    );
  }

  // ─────────────────────────────────────
  //  Permissions & background
  // ─────────────────────────────────────
  Future<void> init() async {}

  Future<bool> _checkPermission() async {
    if (kIsWeb) {
      LocationPermission status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      return status != LocationPermission.denied &&
          status != LocationPermission.deniedForever;
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
    return await Permission.location.isGranted ||
        await Permission.locationAlways.isGranted;
  }

  Future<void> _ensureBackground() async {
    if (kIsWeb) return;
    if (backgroundEnabled.value) return;
    const androidConfig = fb.FlutterBackgroundAndroidConfig(
      notificationTitle: 'تتبع السيارة بالخلفية',
      notificationText: 'التطبيق يراقب حركة السيارة في الخلفية',
      notificationImportance: fb.AndroidNotificationImportance.normal,
      notificationIcon:
          fb.AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );
    final initialized =
        await fb.FlutterBackground.initialize(androidConfig: androidConfig);
    if (initialized) {
      backgroundEnabled.value =
          await fb.FlutterBackground.enableBackgroundExecution();
    }
  }

  // ─────────────────────────────────────
  //  Passive monitor — shared GPS stream
  // ─────────────────────────────────────

  Future<void> startPassiveMonitor(CarModel car) async {
    if (isTrackingForCar(car.carId)) return;
    if (_monitoredCars.containsKey(car.carId)) return;

    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    _monitoredCars[car.carId] = car;
    _movementCounts[car.carId] = 0;

    _sharedPassiveSub ??= Geolocator.getPositionStream(
      locationSettings: _passiveLocationSettings,
    ).listen(_onPassivePosition, onError: (_) {});
  }

  void _onPassivePosition(Position pos) {
    if (_monitoredCars.isEmpty) {
      _stopSharedPassiveSub();
      return;
    }

    if (pos.accuracy > _maxAcceptedAccuracyMeters) return;
    final speed = pos.speed >= 0 ? pos.speed : 0.0;
    final isMoving = speed >= _movementDetectionSpeedMs;

    for (final carId in List<String>.from(_monitoredCars.keys)) {
      if (isTrackingForCar(carId)) {
        _monitoredCars.remove(carId);
        _movementCounts.remove(carId);
        continue;
      }

      if (isMoving) {
        _movementCounts[carId] = (_movementCounts[carId] ?? 0) + 1;
        if ((_movementCounts[carId] ?? 0) >= _movementConfirmationCount) {
          final car = _monitoredCars[carId];
          _monitoredCars.remove(carId);
          _movementCounts.remove(carId);
          // إرسال notification فعلية تصحّي المستخدم حتى لو الشاشة مقفولة
          if (car != null) {
            NotificationService().showNotification(
              id: car.carId.hashCode.abs() % 900000 + 1000000,
              title: '🚗 عربيتك بدأت تتحرك!',
              body: '${car.make} ${car.model} — اضغط لبدء تتبع العداد تلقائياً',
            );
          }
          movementDetectedForCar.value = carId;
          break;
        }
      } else {
        _movementCounts[carId] = 0;
      }
    }

    if (_monitoredCars.isEmpty) _stopSharedPassiveSub();
  }

  void _stopSharedPassiveSub() {
    _sharedPassiveSub?.cancel();
    _sharedPassiveSub = null;
  }

  void stopPassiveMonitor(String carId) {
    _monitoredCars.remove(carId);
    _movementCounts.remove(carId);
    if (_monitoredCars.isEmpty) _stopSharedPassiveSub();
  }

  void stopAllPassiveMonitors() {
    _monitoredCars.clear();
    _movementCounts.clear();
    _stopSharedPassiveSub();
  }

  bool isPassiveMonitoring(String carId) => _monitoredCars.containsKey(carId);

  // ─────────────────────────────────────
  //  Full tracking session
  // ─────────────────────────────────────
  bool isTrackingForCar(String carId) => _sessions.containsKey(carId);

  Future<void> startTracking(CarModel car) async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) throw Exception('Location permission denied');

    stopPassiveMonitor(car.carId);
    await _ensureBackground();
    if (isTrackingForCar(car.carId)) return;

    final session = _TrackingSession(car);

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      session.lastPosition = position;

      session.subscription = Geolocator.getPositionStream(
        locationSettings: _fullLocationSettings,
      ).listen((pos) {
        if (session.lastPosition == null) session.lastPosition = pos;
        if (pos.accuracy > _maxAcceptedAccuracyMeters) return;

        final movedDistance = Geolocator.distanceBetween(
          session.lastPosition!.latitude,
          session.lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );

        if (movedDistance > _maxReasonableSegmentMeters) {
          session.lastPosition = pos;
          return;
        }

        final speed = pos.speed >= 0 ? pos.speed : 0.0;
        final isMoving =
            speed >= _stationarySpeedMs && movedDistance >= _minMovementMeters;

        if (!isMoving) {
          // واقف أو انجراف GPS — حدّث نقطة المرجع عشان منراكمش الخطأ
          session.lastPosition = pos;
          // ابدأ عداد الوقوف (5 دقائق) لو مش شغال
          session.stationaryTimer ??= Timer(_stationaryTimeout, () {
            stopTracking(car.carId);
          });
        } else {
          // تحرك مؤكد — ألغِ عداد الوقوف وسجّل المسافة
          session.cancelStationaryTimer();
          session.totalDistanceMeters += movedDistance;
          session.lastPosition = pos;
        }

        // حدّث بيانات العداد المرئي
        final elapsed = DateTime.now().difference(session.startTime).inSeconds;
        final updated =
            Map<String, LiveTrackingData>.from(liveTrackingData.value);
        updated[car.carId] = LiveTrackingData(
          speedKmh: speed * 3.6,
          distanceKm: session.totalDistanceMeters / 1000,
          elapsedSeconds: elapsed,
        );
        liveTrackingData.value = updated;
      }, onError: (_) {});

      _sessions[car.carId] = session;
      activeTrackings.value = {...activeTrackings.value, car.carId};
    } catch (e) {
      rethrow;
    }
  }

  /// يوقف التتبع ويُبلغ الـ UI بالنتيجة عبر [trackingCompleted].
  /// يُعيد النتيجة أيضًا للمتصل المباشر.
  Future<TrackingResult?> stopTracking(String carId) async {
    final session = _sessions.remove(carId);
    if (session == null) return null;

    session.cancelStationaryTimer();
    await session.subscription?.cancel();

    // أزل من البيانات المباشرة
    final updatedLive =
        Map<String, LiveTrackingData>.from(liveTrackingData.value)
          ..remove(carId);
    liveTrackingData.value = updatedLive;

    final updated = {...activeTrackings.value}..remove(carId);
    activeTrackings.value = updated;

    final distanceKm = session.totalDistanceMeters / 1000;
    final result = TrackingResult(
      distanceKm: distanceKm,
      suggestedOdometer: session.car.currentOdometer + distanceKm,
    );

    // أخبر الـ UI بالنتيجة (يدوي أو تلقائي)
    trackingCompleted.value = MapEntry(carId, result);

    // ✅ أعِد تشغيل المراقبة السلبية عشان نكتشف الحركة التالية
    startPassiveMonitor(session.car);

    return result;
  }
}
