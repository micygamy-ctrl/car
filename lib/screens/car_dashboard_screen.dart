import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car_model.dart';
import '../models/car_part_model.dart';
import '../models/fuel_log_model.dart';
import '../services/car_part_service.dart';
import '../services/car_service.dart';
import '../services/fuel_service.dart';
import '../services/notification_service.dart';
import '../services/maintenance_service.dart';
import 'add_fuel_screen.dart';
import 'add_service_screen.dart';
import 'logs_screen.dart';
import 'reports_screen.dart';
import 'edit_car_screen.dart';
import 'odometer_update_screen.dart';
import 'manage_drivers_screen.dart';
import 'active_trip_screen.dart';
import 'trips_history_screen.dart';
import '../widgets/car_dashboard/dashboard_header.dart';
import '../widgets/car_dashboard/part_status_card.dart';
import '../widgets/car_dashboard/fuel_summary_card.dart';

class CarDashboardScreen extends StatefulWidget {
  final CarModel car;
  final bool isAdmin;

  const CarDashboardScreen({super.key, required this.car, this.isAdmin = true});

  @override
  State<CarDashboardScreen> createState() => _CarDashboardScreenState();
}

class _CarDashboardScreenState extends State<CarDashboardScreen> {
  final CarPartService _partService = CarPartService();
  final FuelService _fuelService = FuelService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  CarModel? _liveCar;
  StreamSubscription<CarModel?>? _carSubscription;

  CarModel get _car => _liveCar ?? widget.car;

  @override
  void initState() {
    super.initState();
    _liveCar = _car;
    _carSubscription = CarService().getCarStream(_car.carId).listen((car) {
      if (car != null && mounted) setState(() => _liveCar = car);
    });
    _partService.initDefaultParts(_car.carId, _car.currentOdometer);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChecks());
  }

  @override
  void dispose() {
    _carSubscription?.cancel();
    super.dispose();
  }

  Future<void> _runChecks() async {
    final notif = NotificationService();
    final carName = '${_car.make} ${_car.model}';

    await notif.checkOilChangeReminder(
      carId: _car.carId,
      carName: carName,
      currentOdometer: _car.currentOdometer,
      lastOilChangeOdometer: _car.lastOilChangeOdometer,
      oilChangeInterval: _car.oilChangeInterval,
    );

    final logs =
        await _maintenanceService.getCarMaintenanceLogs(_car.carId).first;
    final parts = await _partService.getCarParts(_car.carId).first;

    await notif.checkExpiryReminders(
      carId: _car.carId,
      carName: carName,
      logs: logs,
    );
    await notif.checkOdometerReminders(
      carId: _car.carId,
      carName: carName,
      currentOdometer: _car.currentOdometer,
      logs: logs,
    );
    await notif.checkCarPartsReminders(
      carId: _car.carId,
      carName: carName,
      currentOdometer: _car.currentOdometer,
      parts: parts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: StreamBuilder<List<CarPartModel>>(
        stream: _partService.getCarParts(_car.carId),
        builder: (context, partsSnap) {
          final parts = partsSnap.data ?? [];

          // ترتيب القطع: أحمر ← أصفر ← أخضر
          final sortedParts = List<CarPartModel>.from(parts)
            ..sort((a, b) {
              final sA = a.status(_car.currentOdometer).index;
              final sB = b.status(_car.currentOdometer).index;
              // overdue=0, dueSoon=1, ok=2 — نعكسهم عشان overdue يجي أول
              return sA.compareTo(sB);
            });

          final overdueCount = sortedParts
              .where(
                  (p) => p.status(_car.currentOdometer) == PartStatus.overdue)
              .length;
          final dueSoonCount = sortedParts
              .where(
                  (p) => p.status(_car.currentOdometer) == PartStatus.dueSoon)
              .length;
          final okCount = sortedParts
              .where((p) => p.status(_car.currentOdometer) == PartStatus.ok)
              .length;

          final healthScore =
              _calcHealthScore(overdueCount, dueSoonCount, parts.length);

          return CustomScrollView(
            slivers: [
              // ═══════════════════════ HEADER ═══════════════════════
              SliverAppBar(
                expandedHeight: 210,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (widget.isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.people_rounded,
                          color: Colors.white70, size: 22),
                      tooltip: 'إدارة السواقين',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ManageDriversScreen(car: _car)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: Colors.white70, size: 22),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditCarScreen(car: _car)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white70, size: 22),
                      tooltip: 'حذف السيارة',
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: CarDashboardHeader(
                    car: _car,
                    healthScore: healthScore,
                    overdueCount: overdueCount,
                    dueSoonCount: dueSoonCount,
                    okCount: okCount,
                    total: parts.length,
                  ),
                ),
                title: Text(
                  '${_cap(_car.make)} ${_cap(_car.model)}',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ═══════════════════════ أزرار سريعة ═══════════════════════
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickBtn(context, Icons.local_gas_station_rounded,
                              'وقود', const Color(0xFFF97316), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AddFuelScreen(car: _car)));
                          }),
                          _quickBtn(context, Icons.build_rounded, 'خدمة',
                              const Color(0xFF22C55E), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AddServiceScreen(car: _car)));
                          }),
                          if (widget.isAdmin)
                            _quickBtn(context, Icons.speed_rounded, 'عداد',
                                const Color(0xFF38BDF8), () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          OdometerUpdateScreen(car: _car)));
                            }),
                          _quickBtn(context, Icons.receipt_long_rounded,
                              'سجلات', const Color(0xFF8B5CF6), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LogsScreen(
                                        car: _car, isAdmin: widget.isAdmin)));
                          }),
                          _quickBtn(context, Icons.bar_chart_rounded, 'تقارير',
                              const Color(0xFFEF4444), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ReportsScreen(car: _car)));
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ═══════════════════════ زرار الرحلات (سواق فقط) ═══════════════════════
                      if (!widget.isAdmin) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ActiveTripScreen(car: _car)),
                                ),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF22C55E),
                                        Color(0xFF16A34A)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E)
                                            .withAlpha(80),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow_rounded,
                                          color: Colors.white, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ابدأ رحلة',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _quickBtn(context, Icons.route_rounded,
                                  'الرحلات', const Color(0xFF06B6D4), () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            TripsHistoryScreen(car: _car)));
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ═══════════════════════ تحذيرات ═══════════════════════
                      if (overdueCount > 0)
                        _buildAlertBanner(
                          '⚠️ $overdueCount ${overdueCount == 1 ? 'قطعة' : 'قطع'} تجاوزت موعد الصيانة!',
                          Colors.red,
                        ),
                      if (dueSoonCount > 0)
                        _buildAlertBanner(
                          '🔔 $dueSoonCount ${dueSoonCount == 1 ? 'قطعة' : 'قطع'} تحتاج صيانة قريباً',
                          Colors.orange,
                        ),
                      if (overdueCount > 0 || dueSoonCount > 0)
                        const SizedBox(height: 12),

                      // ═══════════════════════ القطع الذكية ═══════════════════════
                      _buildSectionHeader('حالة القطع', Icons.settings_rounded,
                          const Color(0xFF8B5CF6)),
                      const SizedBox(height: 10),

                      if (partsSnap.connectionState ==
                              ConnectionState.waiting &&
                          parts.isEmpty)
                        const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF38BDF8)))
                      else if (parts.isEmpty)
                        _buildEmptyParts()
                      else
                        ...sortedParts.map((part) => PartStatusCard(
                            part: part,
                            currentOdometer: _car.currentOdometer,
                            onLongPress: () => _confirmDeletePart(part),
                          )),

                      const SizedBox(height: 20),

                      // ═══════════════════════ آخر وقود ═══════════════════════
                      _buildSectionHeader(
                          'آخر تزود وقود',
                          Icons.local_gas_station_rounded,
                          const Color(0xFFF97316)),
                      const SizedBox(height: 10),
                      StreamBuilder<List<FuelLogModel>>(
                        stream: _fuelService.getCarFuelLogs(_car.carId),
                        builder: (ctx, fuelSnap) {
                          final logs = fuelSnap.data ?? [];
                          if (logs.isEmpty) {
                            return _buildEmptyCard(
                                'لا توجد سجلات وقود بعد',
                                Icons.local_gas_station_rounded,
                                const Color(0xFFF97316));
                          }
                          return FuelSummaryCard(
                            last: logs.first,
                            all: logs,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LogsScreen(car: _car))),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════
  //  حذف قطعة (Long Press على الكارت)
  // ══════════════════════════════════════
  void _confirmDeletePart(CarPartModel part) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف "${part.name}"؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right),
        content: Text(
          'هتشيل القطعة دي من قائمة الصيانة. تقدر تستخدم هذا الخيار لحذف القطع المكررة.',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _partService.disablePart(part.partId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف "${part.name}"',
                          style: GoogleFonts.cairo()),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: Text('حذف',
                style: GoogleFonts.cairo(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ],
    );
  }

  Widget _buildAlertBanner(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.notifications_active, color: color, size: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyParts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.settings, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text('جاري تحضير القطع...',
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 15)),
          Text('سيتم تهيئة القطع الافتراضية تلقائياً',
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String msg, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withAlpha(128), size: 24),
          const SizedBox(width: 8),
          Text(msg, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _quickBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return SizedBox(
      width: 82,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  int _calcHealthScore(int overdueCount, int dueSoonCount, int total) {
    if (total == 0) return 100;
    int score = 100;
    score -= overdueCount * 15;
    score -= dueSoonCount * 5;
    return score.clamp(0, 100);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف السيارة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من حذف "${_car.make} ${_car.model}"؟\nلن يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف',
                style: GoogleFonts.cairo(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await CarService().deleteCar(_car.carId);
      if (context.mounted) {
        // يرجع لشاشة الـ home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  String _cap(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}