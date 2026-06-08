import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car_model.dart';
import '../services/background_tracking_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_service.dart';
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
  double _baseOdometer = 0;
  double _trackedDistance = 0;

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
      _source = OdometerSource.gps;
    }

    final svc = BackgroundTrackingService();
    // سجّل إن شاشة العداد مفتوحة (يمنع الهوم سكرين من عرض dialog مكرر)
    svc.odometerScreenOpenCars.add(widget.car.carId);

    // ─── لو التتبع شغال بالفعل من الهوم سكرين ───
    if (svc.activeTrackings.value.contains(widget.car.carId)) {
      _isTracking = true;
    }
    svc.trackingCompleted.addListener(_onServiceTrackingCompleted);
  }

  @override
  void dispose() {
    final svc = BackgroundTrackingService();
    svc.odometerScreenOpenCars.remove(widget.car.carId);
    svc.trackingCompleted.removeListener(_onServiceTrackingCompleted);
    _odometerController.dispose();
    super.dispose();
  }

  /// يُستدعى لما ينتهي التتبع (يدوي أو تلقائي) من السيرفس
  void _onServiceTrackingCompleted() {
    final svc = BackgroundTrackingService();
    final entry = svc.trackingCompleted.value;
    if (entry == null || entry.key != widget.car.carId) return;
    if (!mounted) return;

    // استهلك الحدث حتى لا يُعالَج مرة ثانية من الهوم سكرين
    svc.trackingCompleted.value = null;

    final result = entry.value;
    setState(() {
      _isTracking = false;
      _trackedDistance = result.distanceKm;
      _odometerController.text = result.suggestedOdometer.toStringAsFixed(1);
      _source = OdometerSource.gps;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'تم حساب ${result.distanceKm.toStringAsFixed(1)} كم — راجع الرقم وعدّله إن لزم',
          style: GoogleFonts.cairo()),
      backgroundColor: const Color(0xFF43A047),
    ));
  }

  // ── Tracking ─────────────────────────────────────────────────────────────

  Future<void> _startTracking() async {
    try {
      _baseOdometer =
          double.tryParse(_odometerController.text) ?? widget.car.currentOdometer;
      await BackgroundTrackingService().startTracking(widget.car);
      setState(() {
        _isTracking = true;
        _trackedDistance = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذر بدء التتبع: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _stopTracking() async {
    await BackgroundTrackingService().stopTracking(widget.car.carId);
    // النتيجة تصل عبر _onServiceTrackingCompleted
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
        'odometerUpdateSource': _source.name,
        'odometerUpdatedAt': DateTime.now(),
      });

      final logs = await MaintenanceService()
          .getCarMaintenanceLogs(widget.car.carId)
          .first;
      await NotificationService().checkOdometerReminders(
        carId: widget.car.carId,
        carName: '${widget.car.make} ${widget.car.model}',
        currentOdometer: newOdometer,
        logs: logs,
      );
      await NotificationService().checkExpiryReminders(
        carId: widget.car.carId,
        carName: '${widget.car.make} ${widget.car.model}',
        logs: logs,
      );
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
          TextFormField(
            controller: _odometerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5)),
            onChanged: (_) => setState(() => _source = OdometerSource.manual),
            decoration: InputDecoration(
              hintText: 'مثال: 45000',
              hintStyle: GoogleFonts.cairo(color: Colors.grey),
              suffixText: 'كم',
              suffixStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
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

          // ─── عداد مرئي أثناء التتبع ───
          if (_isTracking) ...[
            _buildLiveSpeedometer(),
            const SizedBox(height: 12),
          ],

          // ─── نتيجة المسافة بعد الإيقاف ───
          if (_trackedDistance > 0 && !_isTracking) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withAlpha(20),
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

          // ─── زر بدء / إيقاف ───
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

  Widget _buildLiveSpeedometer() {
    return ValueListenableBuilder<Map<String, LiveTrackingData>>(
      valueListenable: BackgroundTrackingService().liveTrackingData,
      builder: (_, liveMap, __) {
        final live = liveMap[widget.car.carId] ?? LiveTrackingData.zero;
        final speed = live.speedKmh;
        final distKm = live.distanceKm;
        final elapsed = live.elapsedSeconds;

        final speedColor = speed < 60
            ? const Color(0xFF43A047)
            : speed < 100
                ? Colors.orange
                : Colors.red;

        final m = (elapsed ~/ 60).toString().padLeft(2, '0');
        final s = (elapsed % 60).toString().padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 8),
                  Text('جاري التتبع...',
                      style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OdometerSpeedometerPainter(speedKmh: speed),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              speed.toStringAsFixed(0),
                              key: ValueKey(speed.toStringAsFixed(0)),
                              style: GoogleFonts.cairo(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: speedColor),
                            ),
                          ),
                          Text('كم/س',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _liveChip(Icons.route,
                      '${distKm.toStringAsFixed(2)} كم', Colors.greenAccent),
                  Container(width: 1, height: 28, color: Colors.white24),
                  _liveChip(Icons.timer_outlined, '$m:$s',
                      Colors.lightBlueAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 700),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
              color: Color(0xFF43A047), shape: BoxShape.circle),
        ),
      ),
      onEnd: () => setState(() {}),
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

// ══════════════════════════════════════════════════════════════
//  Speedometer Painter
// ══════════════════════════════════════════════════════════════
class _OdometerSpeedometerPainter extends CustomPainter {
  final double speedKmh;
  static const double _maxSpeed = 160;
  static const double _strokeW = 10.0;

  const _OdometerSpeedometerPainter({required this.speedKmh});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) * 0.86;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW
        ..strokeCap = StrokeCap.round,
    );

    void zone(double from, double to, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (from / _maxSpeed) * sweepAngle,
        ((to - from) / _maxSpeed) * sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    zone(0, 60, const Color(0xFF43A047).withAlpha(140));
    zone(60, 100, Colors.orange.withAlpha(140));
    zone(100, 160, Colors.red.withAlpha(140));

    final clamped = speedKmh.clamp(0.0, _maxSpeed);
    if (clamped > 0) {
      final color = clamped < 60
          ? const Color(0xFF43A047)
          : clamped < 100
              ? Colors.orange
              : Colors.red;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (clamped / _maxSpeed) * sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeW + 4
          ..strokeCap = StrokeCap.round,
      );
    }

    final needleAngle = startAngle + (clamped / _maxSpeed) * sweepAngle;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius * 0.7) * math.cos(needleAngle),
        center.dy + (radius * 0.7) * math.sin(needleAngle),
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF1E88E5));

    for (final speed in [0.0, 60.0, 120.0, 160.0]) {
      final angle = startAngle + (speed / _maxSpeed) * sweepAngle;
      canvas.drawLine(
        Offset(center.dx + (radius - 14) * math.cos(angle),
            center.dy + (radius - 14) * math.sin(angle)),
        Offset(center.dx + (radius + 4) * math.cos(angle),
            center.dy + (radius + 4) * math.sin(angle)),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OdometerSpeedometerPainter old) =>
      old.speedKmh != speedKmh;
}
