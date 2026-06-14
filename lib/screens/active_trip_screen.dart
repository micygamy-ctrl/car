import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../services/auth_service.dart';
import '../services/background_tracking_service.dart';
import '../services/car_service.dart';
import '../services/trip_service.dart';

class ActiveTripScreen extends StatefulWidget {
  final CarModel car;
  const ActiveTripScreen({super.key, required this.car});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final _bgService = BackgroundTrackingService();
  final _carService = CarService();
  final _tripService = TripService();

  late final DateTime _startTime;
  late final double _startOdometer;

  bool _isStarted = false;
  bool _isEnding = false;
  String? _errorMsg;

  late final VoidCallback _liveListener;
  late final VoidCallback _completedListener;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startOdometer = widget.car.currentOdometer;

    // منع الهوم سكرين من التقاط نتيجة التتبع
    _bgService.odometerScreenOpenCars.add(widget.car.carId);

    // استهلك أي نتيجة قديمة
    if (_bgService.trackingCompleted.value?.key == widget.car.carId) {
      _bgService.trackingCompleted.value = null;
    }

    _liveListener = () {
      if (mounted) setState(() {});
    };
    _completedListener = _onTrackingCompleted;

    _bgService.liveTrackingData.addListener(_liveListener);
    _bgService.trackingCompleted.addListener(_completedListener);

    _startTracking();
  }

  @override
  void dispose() {
    _bgService.odometerScreenOpenCars.remove(widget.car.carId);
    _bgService.liveTrackingData.removeListener(_liveListener);
    _bgService.trackingCompleted.removeListener(_completedListener);
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      await _bgService.startTracking(widget.car);
      if (mounted) setState(() => _isStarted = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'تعذر بدء التتبع: تأكد من صلاحيات الموقع');
      }
    }
  }

  void _onTrackingCompleted() {
    final entry = _bgService.trackingCompleted.value;
    if (entry == null || entry.key != widget.car.carId) return;
    _bgService.trackingCompleted.value = null;
    _saveTrip(entry.value);
  }

  Future<void> _endTrip() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    await _bgService.stopTracking(widget.car.carId);
    // _onTrackingCompleted يستقبل النتيجة تلقائياً
  }

  Future<void> _saveTrip(TrackingResult result) async {
    if (result.distanceKm < 0.05) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('المسافة قصيرة جداً لتسجيل رحلة',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
      return;
    }

    final user = AuthService().currentUser;
    final tripId = const Uuid().v4();
    final endTime = DateTime.now();
    final endOdometer = _startOdometer + result.distanceKm;

    try {
      await Future.wait([
        _tripService.saveTrip(TripModel(
          tripId: tripId,
          carId: widget.car.carId,
          driverId: user?.uid ?? '',
          driverName: user?.displayName ?? user?.email ?? '',
          startOdometer: _startOdometer,
          endOdometer: endOdometer,
          distanceKm: result.distanceKm,
          startTime: _startTime,
          endTime: endTime,
          status: 'completed',
        )),
        _carService.updateCar(widget.car.carId, {
          'currentOdometer': endOdometer,
        }),
      ]);

      if (mounted) _showTripSummary(result, endTime);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ في حفظ الرحلة', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    }
  }

  void _showTripSummary(TrackingResult result, DateTime endTime) {
    final duration = endTime.difference(_startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('✅  '),
              Expanded(
                child: Text('تمت الرحلة!',
                    style:
                        GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRow(Icons.route, 'المسافة',
                  '${result.distanceKm.toStringAsFixed(2)} كم',
                  const Color(0xFF1E88E5)),
              const SizedBox(height: 12),
              _summaryRow(Icons.timer, 'المدة',
                  '${minutes}د ${seconds}ث',
                  const Color(0xFF43A047)),
              const SizedBox(height: 12),
              _summaryRow(Icons.speed, 'العداد الجديد',
                  '${(_startOdometer + result.distanceKm).toStringAsFixed(1)} كم',
                  const Color(0xFF8E24AA)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تمام 👍',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withAlpha(25), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
              Text(value,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    if (!_bgService.isTrackingForCar(widget.car.carId)) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إنهاء الرحلة؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text('لو رجعت دلوقتي هتخسر بيانات الرحلة الحالية.',
              style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('تابع الرحلة', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('إنهاء بدون حفظ',
                  style: GoogleFonts.cairo(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await _bgService.stopTracking(widget.car.carId);
      _bgService.trackingCompleted.value = null;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final live = _bgService.liveTrackingData.value[widget.car.carId] ??
        LiveTrackingData.zero;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // شريط العلوي
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white70),
                        onPressed: () async {
                          final should = await _onWillPop();
                          if (should && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.car.make} ${widget.car.model}',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _isEnding
                                  ? 'جاري الحفظ...'
                                  : _isStarted
                                      ? '🟢 الرحلة جارية'
                                      : _errorMsg ?? 'جاري البدء...',
                              style: GoogleFonts.cairo(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // عداد المسافة الكبير
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                    border: Border.all(
                        color: Colors.white.withAlpha(80), width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        live.distanceKm.toStringAsFixed(2),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        'كيلومتر',
                        style: GoogleFonts.cairo(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // السرعة والوقت
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statCard(
                      Icons.speed,
                      '${live.speedKmh.toStringAsFixed(0)}',
                      'كم/س',
                    ),
                    const SizedBox(width: 32),
                    _statCard(
                      Icons.timer,
                      _formatDuration(live.elapsedSeconds),
                      'مدة الرحلة',
                    ),
                  ],
                ),

                const Spacer(),

                // زرار إنهاء الرحلة
                if (_errorMsg == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isEnding || !_isStarted) ? null : _endTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEnding
                              ? Colors.grey
                              : const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: _isEnding
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.stop_circle_outlined,
                                color: Colors.white, size: 26),
                        label: Text(
                          _isEnding ? 'جاري الحفظ...' : 'أنهِ الرحلة',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: Text(_errorMsg!,
                        style: GoogleFonts.cairo(
                            color: Colors.red[200], fontSize: 14),
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
