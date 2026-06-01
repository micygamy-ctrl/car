import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class CarDashboardScreen extends StatefulWidget {
  final CarModel car;

  const CarDashboardScreen({super.key, required this.car});

  @override
  State<CarDashboardScreen> createState() => _CarDashboardScreenState();
}

class _CarDashboardScreenState extends State<CarDashboardScreen> {
  final CarPartService _partService = CarPartService();
  final FuelService _fuelService = FuelService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  void initState() {
    super.initState();
    // تهيئة القطع الافتراضية لو أول مرة
    _partService.initDefaultParts(
        widget.car.carId, widget.car.currentOdometer);
    // تشغيل التنبيهات
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChecks());
  }

  Future<void> _runChecks() async {
    final notif = NotificationService();
    // فحص الزيت
    await notif.checkOilChangeReminder(
      carName: '${widget.car.make} ${widget.car.model}',
      currentOdometer: widget.car.currentOdometer,
      lastOilChangeOdometer: widget.car.lastOilChangeOdometer,
      oilChangeInterval: widget.car.oilChangeInterval,
    );
    // جلب السجلات وفحص التنبيهات
    _maintenanceService
        .getCarMaintenanceLogs(widget.car.carId)
        .first
        .then((logs) async {
      await notif.checkExpiryReminders(
        carName: '${widget.car.make} ${widget.car.model}',
        logs: logs,
      );
      await notif.checkOdometerReminders(
        carName: '${widget.car.make} ${widget.car.model}',
        currentOdometer: widget.car.currentOdometer,
        logs: logs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<List<CarPartModel>>(
        stream: _partService.getCarParts(widget.car.carId),
        builder: (context, partsSnap) {
          final parts = partsSnap.data ?? [];

          // ترتيب القطع: أحمر ← أصفر ← أخضر
          final sortedParts = List<CarPartModel>.from(parts)
            ..sort((a, b) {
              final sA = a.status(widget.car.currentOdometer).index;
              final sB = b.status(widget.car.currentOdometer).index;
              // overdue=0, dueSoon=1, ok=2 — نعكسهم عشان overdue يجي أول
              return sA.compareTo(sB);
            });

          final overdueCount = sortedParts
              .where((p) =>
                  p.status(widget.car.currentOdometer) == PartStatus.overdue)
              .length;
          final dueSoonCount = sortedParts
              .where((p) =>
                  p.status(widget.car.currentOdometer) == PartStatus.dueSoon)
              .length;
          final okCount = sortedParts
              .where(
                  (p) => p.status(widget.car.currentOdometer) == PartStatus.ok)
              .length;

          final healthScore =
              _calcHealthScore(overdueCount, dueSoonCount, parts.length);

          return CustomScrollView(
            slivers: [
              // ═══════════════════════ HEADER ═══════════════════════
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1E88E5),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditCarScreen(car: widget.car)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'حذف السيارة',
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(healthScore, overdueCount,
                      dueSoonCount, okCount, parts.length),
                ),
                title: Text(
                  '${_cap(widget.car.make)} ${_cap(widget.car.model)}',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ═══════════════════════ أزرار سريعة ═══════════════════════
                      Row(
                        children: [
                          _quickBtn(context, Icons.local_gas_station, 'وقود',
                              const Color(0xFFFB8C00), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AddFuelScreen(car: widget.car)));
                          }),
                          const SizedBox(width: 8),
                          _quickBtn(context, Icons.build, 'خدمة',
                              const Color(0xFF43A047), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AddServiceScreen(car: widget.car)));
                          }),
                          const SizedBox(width: 8),
                          _quickBtn(context, Icons.speed, 'عداد',
                              const Color(0xFF1E88E5), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => OdometerUpdateScreen(
                                        car: widget.car)));
                          }),
                          const SizedBox(width: 8),
                          _quickBtn(context, Icons.history, 'سجلات',
                              const Color(0xFF8E24AA), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        LogsScreen(car: widget.car)));
                          }),
                          const SizedBox(width: 8),
                          _quickBtn(context, Icons.bar_chart, 'تقارير',
                              const Color(0xFFE53935), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ReportsScreen(car: widget.car)));
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ═══════════════════════ لو في تحذيرات ═══════════════════════
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
                      _buildSectionHeader('حالة القطع 🔧', const Color(0xFF8E24AA)),
                      const SizedBox(height: 8),

                      if (partsSnap.connectionState ==
                              ConnectionState.waiting &&
                          parts.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (parts.isEmpty)
                        _buildEmptyParts()
                      else
                        ...sortedParts.map((part) => _buildPartCard(part)),

                      const SizedBox(height: 20),

                      // ═══════════════════════ آخر وقود ═══════════════════════
                      _buildSectionHeader('آخر تزود وقود ⛽', const Color(0xFFFB8C00)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FuelLogModel>>(
                        stream:
                            _fuelService.getCarFuelLogs(widget.car.carId),
                        builder: (ctx, fuelSnap) {
                          final logs = fuelSnap.data ?? [];
                          if (logs.isEmpty) {
                            return _buildEmptyCard(
                                'مفيش سجلات وقود لسه',
                                Icons.local_gas_station,
                                const Color(0xFFFB8C00));
                          }
                          return _buildFuelSummary(logs.first, logs);
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
  //  HEADER
  // ══════════════════════════════════════
  Widget _buildHeader(int healthScore, int overdueCount, int dueSoonCount,
      int okCount, int total) {
    final healthColor = healthScore >= 80
        ? Colors.green
        : healthScore >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Health score + مؤشرات بصرية
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حالة السيارة',
                      style: GoogleFonts.cairo(
                          color: Colors.white70, fontSize: 12)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$healthScore',
                        style: GoogleFonts.cairo(
                          color: healthColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('/100',
                          style: GoogleFonts.cairo(
                              color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                  // شريط التقدم
                  Container(
                    width: 110,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: healthScore / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: healthColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // مؤشرات الألوان
                  if (total > 0)
                    Row(
                      children: [
                        if (overdueCount > 0)
                          _miniChip('$overdueCount', Colors.red),
                        if (dueSoonCount > 0) ...[
                          if (overdueCount > 0) const SizedBox(width: 4),
                          _miniChip('$dueSoonCount', Colors.orange),
                        ],
                        if (okCount > 0) ...[
                          if (overdueCount > 0 || dueSoonCount > 0)
                            const SizedBox(width: 4),
                          _miniChip('$okCount', Colors.green),
                        ],
                      ],
                    ),
                ],
              ),
              // معلومات السيارة
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_cap(widget.car.make)} ${_cap(widget.car.model)}',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.car.year} • ${widget.car.licensePlate}',
                    style: GoogleFonts.cairo(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${widget.car.currentOdometer.toStringAsFixed(0)} كم',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.speed,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  //  PART CARD
  // ══════════════════════════════════════
  Widget _buildPartCard(CarPartModel part) {
    final status = part.status(widget.car.currentOdometer);
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (status) {
      case PartStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        statusText = 'متأخر!';
        break;
      case PartStatus.dueSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusText = 'قريب';
        break;
      case PartStatus.ok:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'تمام';
        break;
    }

    final km = part.kmRemaining(widget.car.currentOdometer);
    final days = part.daysRemaining();
    String remainingText = '';
    if (km != null) {
      remainingText = km <= 0
          ? 'تجاوز ${(-km).toStringAsFixed(0)} كم'
          : 'باقي ${km.toStringAsFixed(0)} كم';
    } else if (days != null) {
      remainingText = days < 0
          ? 'تجاوز ${(-days)} يوم'
          : days == 0
              ? 'ينتهي اليوم!'
              : 'باقي $days يوم';
    }

    final prog = part.progress(widget.car.currentOdometer);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status != PartStatus.ok
              ? statusColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: status != PartStatus.ok ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge الحالة
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(statusText,
                        style: GoogleFonts.cairo(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              // اسم القطعة
              Text(
                part.name,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: status == PartStatus.overdue
                      ? Colors.red
                      : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prog,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remainingText,
                style: GoogleFonts.cairo(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (part.nextDueOdometer != null)
                Text(
                  'عند ${part.nextDueOdometer!.toStringAsFixed(0)} كم',
                  style:
                      GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
                )
              else if (part.nextDueDate != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(part.nextDueDate!),
                  style:
                      GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  //  FUEL SUMMARY
  // ══════════════════════════════════════
  Widget _buildFuelSummary(FuelLogModel last, List<FuelLogModel> all) {
    // حساب متوسط الاستهلاك من آخر 5 سجلات
    double? avgEff;
    final withEff =
        all.where((l) => l.calculatedEfficiency != null).take(5).toList();
    if (withEff.isNotEmpty) {
      avgEff = withEff.map((l) => l.calculatedEfficiency!).reduce((a, b) => a + b) /
          withEff.length;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => LogsScreen(car: widget.car))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                    Text('كل السجلات',
                        style: GoogleFonts.cairo(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(last.date),
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _fuelStat('${last.totalCost.toStringAsFixed(0)} ج.م',
                    'التكلفة', Icons.attach_money, Colors.red),
                _fuelStat('${last.fuelAmount} لتر', 'الكمية',
                    Icons.local_gas_station, const Color(0xFFFB8C00)),
                _fuelStat('${last.odometer.toStringAsFixed(0)} كم', 'العداد',
                    Icons.speed, Colors.blue),
                if (avgEff != null)
                  _fuelStat('${avgEff.toStringAsFixed(1)}', 'ل/100كم',
                      Icons.show_chart, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fuelStat(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // ══════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════
  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Icon(icon, color: color.withOpacity(0.5), size: 24),
          const SizedBox(width: 8),
          Text(msg,
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _quickBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
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
        title: Text('حذف السيارة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من حذف "${widget.car.make} ${widget.car.model}"؟\nلن يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await CarService().deleteCar(widget.car.carId);
      if (context.mounted) {
        // يرجع لشاشة الـ home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  String _cap(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}