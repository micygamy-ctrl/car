import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../models/car_model.dart';
import 'add_car_screen.dart';
import 'join_car_screen.dart';
import 'odometer_update_screen.dart';
import '../services/background_tracking_service.dart';
import 'car_details_screen.dart';
import 'settings_screen.dart';
import 'car_dashboard_screen.dart';
import 'car_location_screen.dart';
import '../services/reminder_service.dart';
import '../services/sms_service.dart';
import 'fuel_sms_confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  final CarService carService = CarService();
  final BackgroundTrackingService _bgService = BackgroundTrackingService();

  late final VoidCallback _activeTrackingsListener;
  late final VoidCallback _backgroundEnabledListener;

  @override
  void initState() {
    super.initState();
    _bgService.init();
    _activeTrackingsListener = () => setState(() {});
    _backgroundEnabledListener = () => setState(() {});
    _bgService.activeTrackings.addListener(_activeTrackingsListener);
    _bgService.backgroundEnabled.addListener(_backgroundEnabledListener);
    final user = AuthService().currentUser;
    if (user != null) {
      ReminderService().runDailyCheck(user.uid);
      // فحص SMS بعد ثانيتين حتى تكتمل الشاشة
      Future.delayed(const Duration(seconds: 2), () => _checkForFuelSms(user.uid));
    }
  }

  Future<void> _checkForFuelSms(String uid) async {
    try {
      final results = await SmsService().checkNewFuelSms();
      if (results.isEmpty || !mounted) return;

      final cars = await carService.getUserCars(uid).first;
      if (!mounted) return;

      for (final sms in results) {
        if (!mounted) break;
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => FuelSmsConfirmationScreen(
              smsResult: sms,
              cars: cars,
            ),
          ),
        );
      }
    } catch (_) {
      // SMS غير مدعوم أو تم رفض الصلاحية — نتجاهل بصمت
    }
  }

  @override
  void dispose() {
    _bgService.activeTrackings.removeListener(_activeTrackingsListener);
    _bgService.backgroundEnabled.removeListener(_backgroundEnabledListener);
    _bgService.stopAllPassiveMonitors();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.logout,
                                  color: Colors.white70),
                              onPressed: () => authService.logout(),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'مرحباً 👋',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'مساعد السيارة الذكي 🚗',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          StreamBuilder<List<CarWithRole>>(
            stream: carService.getUserCarsWithRole(user?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final cars = snapshot.data ?? [];

              if (cars.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1E88E5).withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 60,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'مفيش سيارات لسه!',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط + عشان تضيف سيارتك الأولى',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final carWithRole = cars[index];
                      return _CarCard(
                        car: carWithRole.car,
                        bgService: _bgService,
                        role: carWithRole.role,
                      );
                    },
                    childCount: cars.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.add, color: Color(0xFF1E88E5)),
                ),
                title: Text('إضافة سيارة جديدة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('أضف سيارتك الخاصة',
                    style:
                        GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddCarScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key,
                      color: Color(0xFF43A047)),
                ),
                title: Text('انضم لسيارة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('ادخل كود الدعوة من المالك',
                    style:
                        GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const JoinCarScreen()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _CarCard — StatefulWidget مع كشف الحركة التلقائي
// ══════════════════════════════════════════════════════════════
class _CarCard extends StatefulWidget {
  final CarModel car;
  final BackgroundTrackingService bgService;
  final String role;

  const _CarCard({required this.car, required this.bgService, required this.role});

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard> with WidgetsBindingObserver {
  bool _dialogPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.bgService.movementDetectedForCar.addListener(_onMovementDetected);
    widget.bgService.trackingCompleted.addListener(_onTrackingCompleted);
    _startPassiveMonitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.bgService.movementDetectedForCar.removeListener(_onMovementDetected);
    widget.bgService.trackingCompleted.removeListener(_onTrackingCompleted);
    widget.bgService.stopPassiveMonitor(widget.car.carId);
    super.dispose();
  }

  /// معالجة lifecycle التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق عاد للمقدمة — أعد تشغيل المراقبة لو مش شغالة
        if (!widget.bgService.isTrackingForCar(widget.car.carId) &&
            !widget.bgService.isPassiveMonitoring(widget.car.carId) &&
            !_dialogPending) {
          _startPassiveMonitor();
        }
        break;
      case AppLifecycleState.paused:
        // التطبيق ذهب للخلفية — وقّف المراقبة السلبية لتوفير البطارية
        // (التتبع الكامل يستمر عبر foreground notification)
        if (!widget.bgService.isTrackingForCar(widget.car.carId)) {
          widget.bgService.stopPassiveMonitor(widget.car.carId);
        }
        break;
      default:
        break;
    }
  }

  void _startPassiveMonitor() {
    widget.bgService.startPassiveMonitor(widget.car);
  }

  // ─── نهاية التتبع (يدوي أو تلقائي) ───
  void _onTrackingCompleted() {
    final entry = widget.bgService.trackingCompleted.value;
    if (entry == null || entry.key != widget.car.carId) return;
    if (!mounted) return;

    // لو شاشة العداد مفتوحة → هي ستعالج النتيجة وتستهلكها
    if (widget.bgService.odometerScreenOpenCars.contains(widget.car.carId)) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) _startPassiveMonitor();
      });
      return;
    }

    // أعِد تعيين الـ notifier فورًا حتى لا يُفعَّل مرة ثانية
    widget.bgService.trackingCompleted.value = null;

    // أعِد المراقبة السلبية بعد 30 ثانية
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _startPassiveMonitor();
    });

    _showTrackingResultDialog(entry.value);
  }

  void _showTrackingResultDialog(TrackingResult res) {
    if (res.distanceKm < 0.05) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم إيقاف التتبع (لم تُسجَّل مسافة كافية)',
            style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Text('📏  '),
            Expanded(
              child: Text('انتهى التتبع!',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.car.make} ${widget.car.model}',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                    fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${res.distanceKm.toStringAsFixed(1)} كم',
                      style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF43A047)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.route, color: const Color(0xFF43A047), size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('هل تريد تحديث عداد السيارة؟',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.black87)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('لا، شكرًا', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.speed, color: Colors.white, size: 18),
              label: Text('تحديث العداد',
                  style: GoogleFonts.cairo(color: Colors.white)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OdometerUpdateScreen(
                      car: widget.car,
                      initialOdometer: res.suggestedOdometer,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onMovementDetected() {
    final detectedId = widget.bgService.movementDetectedForCar.value;
    if (detectedId != widget.car.carId) return;
    if (_dialogPending) return;
    if (!mounted) return;

    // إعادة تعيين الـ notifier فورًا حتى لا تُفعّل بطاقات أخرى
    widget.bgService.movementDetectedForCar.value = null;
    _dialogPending = true;
    _showMovementDialog();
  }

  void _showMovementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🚗  '),
              Expanded(
                child: Text(
                  'السيارة بتتحرك!',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.car.make} ${widget.car.model}',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تم رصد حركة السيارة.\nهل تريد تفعيل تتبع العداد التلقائي؟',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            // تجاهل — يعيد المراقبة بعد 5 دقائق
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _dialogPending = false;
                Future.delayed(const Duration(minutes: 5), () {
                  if (mounted) _startPassiveMonitor();
                });
              },
              child: Text('تجاهل',
                  style: GoogleFonts.cairo(color: Colors.grey[600])),
            ),
            // تفعيل التتبع
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
              label: Text('تفعيل التتبع',
                  style: GoogleFonts.cairo(color: Colors.white)),
              onPressed: () async {
                Navigator.pop(ctx);
                _dialogPending = false;
                try {
                  await widget.bgService.startTracking(widget.car);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('بدأ تتبع العداد! 📍',
                          style: GoogleFonts.cairo()),
                      backgroundColor: const Color(0xFF43A047),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تعذر بدء التتبع: $e',
                          style: GoogleFonts.cairo()),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualTracking() async {
    final isTracking =
        widget.bgService.activeTrackings.value.contains(widget.car.carId);

    if (!isTracking) {
      try {
        await widget.bgService.startTracking(widget.car);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('بدأ تتبع السيارة 📍', style: GoogleFonts.cairo()),
            backgroundColor: const Color(0xFF43A047),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تعذر بدء التتبع: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      // _onTrackingCompleted ستستقبل النتيجة وتعرض الـ dialog
      await widget.bgService.stopTracking(widget.car.carId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final double kmDriven = car.currentOdometer - car.lastOilChangeOdometer;
    final double kmToNextOil = car.oilChangeInterval - kmDriven;
    final bool oilSoon = kmToNextOil <= 500;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CarDashboardScreen(
                  car: car,
                  isAdmin: widget.role == 'admin',
                )),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withAlpha(102),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          car.licensePlate,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.role == 'driver') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'سواق',
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_capitalize(car.make)} ${_capitalize(car.model)}',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${car.year}',
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withAlpha(51)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (oilSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'تغيير الزيت قريب!',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'الزيت تمام',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.speed,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${car.currentOdometer.toStringAsFixed(0)} كم',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // زرار الموقع
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CarLocationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(38),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: Text(
                    'أين عربيتي؟',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ─── منطقة التتبع ───
              ValueListenableBuilder<Set<String>>(
                valueListenable: widget.bgService.activeTrackings,
                builder: (context, active, _) {
                  final isTracking = active.contains(car.carId);

                  if (!isTracking) {
                    // زرار بدء التتبع
                    return SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _handleManualTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.location_searching,
                            color: Color(0xFF1E88E5)),
                        label: Text('تشغيل تتبع العداد',
                            style: GoogleFonts.cairo(
                                color: const Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }

                  // ─── عداد مرئي أثناء التتبع ───
                  return ValueListenableBuilder<Map<String, LiveTrackingData>>(
                    valueListenable: widget.bgService.liveTrackingData,
                    builder: (context, liveMap, _) {
                      final live =
                          liveMap[car.carId] ?? LiveTrackingData.zero;
                      return _LiveTrackingCard(
                        live: live,
                        onStop: _handleManualTracking,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ══════════════════════════════════════════════════════════════
//  بطاقة التتبع المرئي (تظهر بدل زر التتبع أثناء الجلسة)
// ══════════════════════════════════════════════════════════════
class _LiveTrackingCard extends StatelessWidget {
  final LiveTrackingData live;
  final VoidCallback onStop;

  const _LiveTrackingCard({required this.live, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final speedColor = live.speedKmh < 60
        ? const Color(0xFF43A047)
        : live.speedKmh < 100
            ? Colors.orange
            : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(60), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // شريط الحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(),
              const SizedBox(width: 6),
              Text('جاري التتبع...',
                  style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),

          // العداد المرئي
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // رسم الـ Speedometer
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpeedometerPainter(speedKmh: live.speedKmh),
                  ),
                ),
                // رقم السرعة في المنتصف أسفل
                Positioned(
                  bottom: 6,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          '${live.speedKmh.toStringAsFixed(0)}',
                          key: ValueKey(live.speedKmh.toStringAsFixed(0)),
                          style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: speedColor),
                        ),
                      ),
                      Text('كم/س',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // المسافة والوقت
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.route,
                label: '${live.distanceKm.toStringAsFixed(2)} كم',
              ),
              const SizedBox(width: 16),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: _formatDuration(live.elapsedSeconds),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // زرار الإيقاف
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withAlpha(200),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.stop, color: Colors.white, size: 18),
              label: Text('إيقاف التتبع',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.cairo(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// نقطة نبضية متحركة
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF43A047),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Speedometer Painter — عداد السرعة المرئي
// ══════════════════════════════════════════════════════════════
class _SpeedometerPainter extends CustomPainter {
  final double speedKmh;
  static const double _maxSpeed = 160;
  static const double _strokeW = 9;

  const _SpeedometerPainter({required this.speedKmh});

  @override
  void paint(Canvas canvas, Size size) {
    // المركز في أسفل المنتصف
    final center = Offset(size.width / 2, size.height);
    final radius =
        math.min(size.width / 2, size.height) * 0.88;

    // القوس يبدأ من اليسار (π) ويسير باتجاه عقارب الساعة (sweep +π)
    // مرورًا بالأعلى وصولًا لليمين (0)
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // ─── خلفية القوس ───
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        bgPaint);

    // ─── مناطق اللون ───
    void _zone(double from, double to, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW
        ..strokeCap = StrokeCap.round;
      final start = startAngle + (from / _maxSpeed) * sweepAngle;
      final sweep = ((to - from) / _maxSpeed) * sweepAngle;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          paint);
    }

    _zone(0, 60, const Color(0xFF43A047).withAlpha(130));
    _zone(60, 100, Colors.orange.withAlpha(130));
    _zone(100, 160, Colors.red.withAlpha(130));

    // ─── قوس السرعة الحالية ───
    final clampedSpeed = speedKmh.clamp(0.0, _maxSpeed);
    if (clampedSpeed > 0) {
      final speedColor = clampedSpeed < 60
          ? const Color(0xFF43A047)
          : clampedSpeed < 100
              ? Colors.orange
              : Colors.red;
      final speedPaint = Paint()
        ..color = speedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW + 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          (clampedSpeed / _maxSpeed) * sweepAngle,
          false,
          speedPaint);
    }

    // ─── الإبرة ───
    final needleAngle =
        startAngle + (clampedSpeed / _maxSpeed) * sweepAngle;
    final needleEnd = Offset(
      center.dx + (radius * 0.72) * math.cos(needleAngle),
      center.dy + (radius * 0.72) * math.sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // ─── نقطة المركز ───
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
        center, 3, Paint()..color = const Color(0xFF1E88E5));

    // ─── علامات السرعة (0، 60، 120، 160) ───
    _drawTick(canvas, center, radius, startAngle, 0);
    _drawTick(canvas, center, radius, startAngle, 60);
    _drawTick(canvas, center, radius, startAngle, 120);
    _drawTick(canvas, center, radius, startAngle, 160);
  }

  void _drawTick(Canvas canvas, Offset center, double radius,
      double startAngle, double speed) {
    final angle = startAngle + (speed / _maxSpeed) * math.pi;
    final inner = Offset(
      center.dx + (radius - 14) * math.cos(angle),
      center.dy + (radius - 14) * math.sin(angle),
    );
    final outer = Offset(
      center.dx + (radius + 4) * math.cos(angle),
      center.dy + (radius + 4) * math.sin(angle),
    );
    canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter old) =>
      old.speedKmh != speedKmh;
}
