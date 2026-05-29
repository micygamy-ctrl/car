import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart' as fb;

import '../models/car_model.dart';

class TrackingResult {
  final double distanceKm;
  final double suggestedOdometer;

  TrackingResult({required this.distanceKm, required this.suggestedOdometer});
}

class _TrackingSession {
  final CarModel car;
  Position? startPosition;
  Position? lastPosition;
  double totalDistanceMeters = 0;
  int stationaryCount = 0;
  StreamSubscription<Position>? subscription;

  _TrackingSession(this.car);
}

class BackgroundTrackingService {
  BackgroundTrackingService._private();
  static final BackgroundTrackingService _instance =
      BackgroundTrackingService._private();
  factory BackgroundTrackingService() => _instance;

  final ValueNotifier<bool> backgroundEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<Set<String>> activeTrackings =
      ValueNotifier<Set<String>>(<String>{});

  final Map<String, _TrackingSession> _sessions = {};
  static const double _minMovementMeters = 10;
  static const double _maxAcceptedAccuracyMeters = 50;
  static const double _maxReasonableSegmentMeters = 1000;
  static const double _stationarySpeedMetersPerSecond = 1.5;

  LocationSettings get _gpsLocationSettings => AndroidSettings(
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

  Future<void> init() async {
    // No-op for now; keep for future initialization
  }

  Future<bool> _checkPermission() async {
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

  bool isTrackingForCar(String carId) => _sessions.containsKey(carId);

  Future<void> startTracking(CarModel car) async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) throw Exception('Location permission denied');

    await _ensureBackground();

    if (isTrackingForCar(car.carId)) return;

    final session = _TrackingSession(car);

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      session.startPosition = position;
      session.lastPosition = position;

      session.subscription = Geolocator.getPositionStream(
        locationSettings: _gpsLocationSettings,
      ).listen((pos) {
        if (session.startPosition == null) session.startPosition = pos;
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

        final hasSpeed = pos.speed >= 0;
        final isStationary =
            (hasSpeed && pos.speed < _stationarySpeedMetersPerSecond) ||
                movedDistance < _minMovementMeters;
        if (isStationary) {
          session.stationaryCount += 1;
        } else {
          session.stationaryCount = 0;
          session.totalDistanceMeters += movedDistance;
          session.lastPosition = pos;
        }

        if (session.stationaryCount >= 3) {
          // auto-stop when stationary
          stopTracking(car.carId);
        }
      }, onError: (_) {
        // ignore
      });

      _sessions[car.carId] = session;
      activeTrackings.value = {...activeTrackings.value, car.carId};
    } catch (e) {
      rethrow;
    }
  }

  Future<TrackingResult?> stopTracking(String carId) async {
    final session = _sessions.remove(carId);
    if (session == null) return null;

    await session.subscription?.cancel();

    if (session.startPosition == null || session.lastPosition == null) {
      activeTrackings.value = {...activeTrackings.value}..remove(carId);
      return TrackingResult(
          distanceKm: 0, suggestedOdometer: session.car.currentOdometer);
    }

    final distanceKm = session.totalDistanceMeters / 1000;
    final suggested = session.car.currentOdometer + distanceKm;

    activeTrackings.value = {...activeTrackings.value}..remove(carId);

    return TrackingResult(distanceKm: distanceKm, suggestedOdometer: suggested);
  }
}
