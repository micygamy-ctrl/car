import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart' as fb;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../services/notification_service.dart';
import 'ocr_screen.dart';

enum OdometerSource { manual, gps, camera }

class OdometerUpdateScreen extends StatefulWidget {
  final CarModel car;
  final double? initialOdometer;
  const OdometerUpdateScreen(
      {super.key, required this.car, this.initialOdometer});

  @override
  State<OdometerUpdateScreen> createState() => _OdometerUpdateScreenState();
}

class _OdometerUpdateScreenState extends State<OdometerUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final CarService _carService = CarService();

  OdometerSource _source = OdometerSource.manual;
  bool _isTracking = false;
  bool _isSaving = false;
  Position? _startPosition;
  Position? _lastPosition;
  bool _backgroundEnabled = false;
  bool _movementReminderSent = false;
  int _stationaryCount = 0;
  double _baseOdometer = 0;
  double _pendingMovementMeters = 0;
  double _trackedDistanceMeters = 0;
  double _trackedDistance = 0;
  String? _trackingStatus;
  StreamSubscription<Position>? _positionStreamSubscription;
  static const double _minMovementMeters = 10;
  static const double _autoStartMovementMeters = 100;
  static const double _maxAutoStartSegmentMeters = 200;
  static const double _maxAcceptedAccuracyMeters = 50;
  static const double _maxReasonableSegmentMeters = 1000;
  static const double _stationarySpeedMetersPerSecond = 1.5;

  @override
  void initState() {
    super.initState();
    _odometerController.text =
        (widget.initialOdometer ?? widget.car.currentOdometer)
            .toStringAsFixed(1);
    _baseOdometer = widget.car.currentOdometer;
    if (widget.initialOdometer != null &&
        widget.initialOdometer! > widget.car.currentOdometer) {
      _trackedDistance = widget.initialOdometer! - widget.car.currentOdometer;
      _trackedDistanceMeters = _trackedDistance * 1000;
      _source = OdometerSource.gps;
    }
    _initBackground();
    _startAutoGpsTracking();
  }

  LocationSettings get _gpsLocationSettings => AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'تتبع العداد بالخلفية',
          notificationText: 'يتم متابعة حركة السيارة لحساب العداد بدقة.',
          notificationChannelName: 'تتبع العداد',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _odometerController.dispose();
    super.dispose();
  }

  // ── GPS ─────────────────────────────────────────────────────────────────

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

  Future<void> _initBackground() async {
    final androidConfig = fb.FlutterBackgroundAndroidConfig(
      notificationTitle: 'تتبع السيارة بالخلفية',
      notificationText: 'التطبيق يراقب حركة السيارة في الخلفية',
      notificationIcon:
          fb.AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    final initialized = await fb.FlutterBackground.initialize(
      androidConfig: androidConfig,
    );
    if (initialized) {
      _backgroundEnabled =
          await fb.FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> _startAutoGpsTracking() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    if (!_backgroundEnabled) {
      await _initBackground();
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: _gpsLocationSettings,
    ).listen((position) {
      if (_isTracking) {
        _handleTrackingPosition(position);
        return;
      }

      if (_lastPosition == null) {
        _lastPosition = position;
        return;
      }

      if (position.accuracy > _maxAcceptedAccuracyMeters) return;

      final previousPosition = _lastPosition!;
      final distance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance > _maxAutoStartSegmentMeters) {
        _lastPosition = position;
        _pendingMovementMeters = 0;
        return;
      }

      _lastPosition = position;

      final hasSpeed = position.speed >= 0;
      final isMoving =
          (!hasSpeed || position.speed >= _stationarySpeedMetersPerSecond) &&
              distance >= _minMovementMeters;

      if (isMoving) {
        _pendingMovementMeters += distance;
      } else {
        _pendingMovementMeters = 0;
      }

      if (_pendingMovementMeters >= _autoStartMovementMeters &&
          !_movementReminderSent) {
        if (!mounted) return;
        setState(() {
          _startPosition = previousPosition;
          _baseOdometer = double.tryParse(_odometerController.text) ??
              widget.car.currentOdometer;
          _trackedDistanceMeters = _pendingMovementMeters;
          _trackedDistance = _trackedDistanceMeters / 1000;
          _isTracking = true;
          _source = OdometerSource.gps;
          _trackingStatus =
              'بدأ التتبع تلقائياً بعد حركة 100 متر. استمر في القيادة ثم أوقف التتبع.';
        });
        NotificationService().showNotification(
          id: 2,
          title: 'بدأ تتبع العداد تلقائياً',
          body:
              'تم اكتشاف حركة السيارة لمسافة 100 متر، وبدأ حساب المسافة بالـ GPS.',
        );
        _movementReminderSent = true;
        _pendingMovementMeters = 0;
      }
    }, onError: (_) {
      // Ignore location stream errors here.
    });
  }

  void _handleTrackingPosition(Position position) {
    if (_startPosition == null) {
      _startPosition = position;
      _lastPosition = position;
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      return;
    }

    if (position.accuracy > _maxAcceptedAccuracyMeters) return;

    final movedDistance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    if (movedDistance > _maxReasonableSegmentMeters) {
      _lastPosition = position;
      return;
    }

    final hasSpeed = position.speed >= 0;
    final isStationary =
        (hasSpeed && position.speed < _stationarySpeedMetersPerSecond) ||
            movedDistance < _minMovementMeters;
    if (isStationary) {
      _stationaryCount += 1;
    } else {
      _stationaryCount = 0;
      _trackedDistanceMeters += movedDistance;
      _lastPosition = position;
    }

    if (_stationaryCount >= 3) {
      _stopAutoTracking(position);
      return;
    }

    final totalDistanceKm = _trackedDistanceMeters / 1000;

    setState(() {
      _trackedDistance = totalDistanceKm;
      _trackingStatus =
          'تم تتبع الحركة تلقائياً — انتظر حتى تتوقف السيارة لإيقاف التتبع';
    });
  }

  void _handleFinalPosition(Position position) {
    if (_lastPosition == null ||
        position.accuracy > _maxAcceptedAccuracyMeters) {
      return;
    }

    final movedDistance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    final hasSpeed = position.speed >= 0;
    final isStationary =
        (hasSpeed && position.speed < _stationarySpeedMetersPerSecond) ||
            movedDistance < _minMovementMeters;

    if (!isStationary && movedDistance <= _maxReasonableSegmentMeters) {
      _trackedDistanceMeters += movedDistance;
      _lastPosition = position;
    }
  }

  Future<void> _stopAutoTracking(Position currentPosition) async {
    if (_startPosition == null) return;

    _handleFinalPosition(currentPosition);

    final distanceKm = _trackedDistanceMeters / 1000;
    final suggested = _baseOdometer + distanceKm;

    _stationaryCount = 0;

    setState(() {
      _isTracking = false;
      _trackedDistance = distanceKm;
      _odometerController.text = suggested.toStringAsFixed(1);
      _source = OdometerSource.gps;
      _trackingStatus = null;
      _movementReminderSent = false;
      _pendingMovementMeters = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'تم إيقاف التتبع تلقائياً عند توقف السيارة. تم حساب ${distanceKm.toStringAsFixed(1)} كم.',
            style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF43A047),
      ));
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('يرجى منح إذن الموقع', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _startPosition = position;
        _lastPosition = position;
        _baseOdometer = double.tryParse(_odometerController.text) ??
            widget.car.currentOdometer;
        _isTracking = true;
        _pendingMovementMeters = 0;
        _trackedDistanceMeters = 0;
        _trackedDistance = 0;
        _movementReminderSent = false;
        _trackingStatus = 'جاري التتبع... قُد سيارتك ثم أوقف التتبع';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في تحديد الموقع: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _stopTracking() async {
    if (_startPosition == null) return;
    try {
      final endPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _handleFinalPosition(endPosition);

      final distanceKm = _trackedDistanceMeters / 1000;
      final suggested = _baseOdometer + distanceKm;

      setState(() {
        _isTracking = false;
        _trackedDistance = distanceKm;
        _odometerController.text = suggested.toStringAsFixed(1);
        _source = OdometerSource.gps;
        _trackingStatus = null;
        _movementReminderSent = false;
        _pendingMovementMeters = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'تم حساب ${distanceKm.toStringAsFixed(1)} كم — راجع الرقم وعدّله إن لزم',
              style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF43A047),
        ));
      }
    } catch (e) {
      setState(() {
        _isTracking = false;
        _trackingStatus = null;
        _pendingMovementMeters = 0;
      });
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _saveOdometer() async {
    if (!_formKey.currentState!.validate()) return;

    final newOdometer = double.tryParse(_odometerController.text);
    if (newOdometer == null) return;

    if (newOdometer < widget.car.currentOdometer) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('العداد الجديد أقل من الحالي!', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _carService.updateCar(widget.car.carId, {
        'currentOdometer': newOdometer,
        'odometerUpdateSource': _source.name, // 'manual' | 'gps' | 'camera'
        'odometerUpdatedAt': DateTime.now(),
      });
      if (mounted) {
        Navigator.pop(context, newOdometer);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تحديث العداد ✅', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF43A047),
        ));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في الحفظ: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'تحديث عداد المسافة 🚗',
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCurrentOdometerCard(),
              const SizedBox(height: 20),
              _buildInputCard(),
              const SizedBox(height: 16),
              _buildGpsCard(),
              const SizedBox(height: 16),
              if (_source != OdometerSource.manual) ...[
                _buildSourceBadge(),
                const SizedBox(height: 16),
              ],
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildCurrentOdometerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.speed, color: Colors.white54, size: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('العداد الحالي',
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
              Text(
                '${widget.car.currentOdometer.toStringAsFixed(0)} كم',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.car.make} ${widget.car.model}',
                style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(((0.06) * 255).round()),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('أدخل قراءة العداد',
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            ],
          ),
          const Divider(height: 20),

          // ── Odometer field + camera icon ──
          TextFormField(
            controller: _odometerController,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5)),
            onChanged: (_) => setState(() => _source = OdometerSource.manual),
            decoration: InputDecoration(
              hintText: 'مثال: 45000',
              hintStyle: GoogleFonts.cairo(color: Colors.grey),
              suffixText: 'كم',
              suffixStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
              // Camera icon → opens OCR screen
              prefixIcon: Tooltip(
                message: 'قراءة العداد بالكاميرا',
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF7B1FA2)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OcrScreen(
                          onOdometerDetected: (value) {
                            setState(() {
                              _odometerController.text =
                                  value.toStringAsFixed(0);
                              _source = OdometerSource.camera;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF1E88E5), width: 2),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'أدخل قراءة العداد';
              if (double.tryParse(v) == null) return 'رقم غير صالح';
              return null;
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'اضغط أيقونة الكاميرا 📷 لقراءة العداد تلقائياً',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(((0.06) * 255).round()),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('تتبع المسافة بالـ GPS',
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.gps_fixed, color: Color(0xFF43A047)),
            ],
          ),
          const Divider(height: 20),
          Text(
            'ابدأ التتبع قبل القيادة. عند الإيقاف، تُضاف المسافة للعداد تلقائياً ويمكنك تعديل الرقم قبل الحفظ.',
            style: GoogleFonts.cairo(
                color: Colors.grey[600], fontSize: 13, height: 1.6),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _backgroundEnabled
                        ? 'التتبع بالخلفية مفعل الآن. يمكنك الرجوع لتطبيقات أخرى وسيستمر الاستماع إلى حركة السيارة.'
                        : 'التتبع بالخلفية غير مفعل بعد. اضغط الزر لتفعيل الخلفية قبل أن تبدأ القيادة.',
                    style: GoogleFonts.cairo(
                      color: Colors.blueGrey[800],
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _backgroundEnabled
                            ? const Color(0xFF43A047)
                            : const Color(0xFFFB8C00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _backgroundEnabled ? Icons.check : Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    if (!_backgroundEnabled) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await _initBackground();
                          if (mounted) setState(() {});
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'تفعيل الخلفية',
                          style: GoogleFonts.cairo(
                              color: const Color(0xFF1E88E5), fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tracking status
          if (_trackingStatus != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_trackingStatus!,
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF43A047), fontSize: 13)),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF43A047)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tracked distance result
          if (_trackedDistance > 0 && !_isTracking) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'المسافة المقطوعة: ${_trackedDistance.toStringAsFixed(1)} كم',
                    style: GoogleFonts.cairo(
                        color: const Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle,
                      color: Color(0xFF1E88E5), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Start / Stop button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isTracking ? Colors.red : const Color(0xFF43A047),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow,
                  color: Colors.white),
              label: Text(
                _isTracking ? 'إيقاف التتبع ⏹️' : 'بدء التتبع 📍',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge() {
    final configs = {
      OdometerSource.gps: {
        'color': const Color(0xFF43A047),
        'icon': Icons.gps_fixed,
        'label': 'المصدر: GPS 📡',
      },
      OdometerSource.camera: {
        'color': const Color(0xFF7B1FA2),
        'icon': Icons.camera_alt,
        'label': 'المصدر: كاميرا (OCR) 📷',
      },
    };

    final cfg = configs[_source]!;
    final color = cfg['color'] as Color;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(((0.1) * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(((0.3) * 255).round())),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cfg['label'] as String,
                style: GoogleFonts.cairo(
                    color: color, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(cfg['icon'] as IconData, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveOdometer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'حفظ قراءة العداد ✅',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }
}
