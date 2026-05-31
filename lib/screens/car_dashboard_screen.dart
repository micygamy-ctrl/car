import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../models/maintenance_item_model.dart';
import '../services/maintenance_item_service.dart';
import '../services/fuel_service.dart';
import '../models/fuel_log_model.dart';
import 'add_fuel_screen.dart';
import 'add_service_screen.dart';
import 'logs_screen.dart';
import 'reports_screen.dart';
import 'edit_car_screen.dart';
import 'odometer_update_screen.dart';

class CarDashboardScreen extends StatelessWidget {
  final CarModel car;

  const CarDashboardScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final MaintenanceItemService itemService = MaintenanceItemService();
    final FuelService fuelService = FuelService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditCarScreen(car: car)),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: StreamBuilder<List<MaintenanceItemModel>>(
                stream: itemService.getCarMaintenanceItems(car.carId),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  final healthScore = _calcHealthScore(items, car);
                  final healthColor = healthScore >= 80
                      ? Colors.green
                      : healthScore >= 50
                          ? Colors.orange
                          : Colors.red;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E88E5),
                          const Color(0xFF0D47A1),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Health Score
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حالة السيارة',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$healthScore',
                                      style: GoogleFonts.cairo(
                                        color: healthColor,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '/100',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 100,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: healthScore / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: healthColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Car Info
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
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
                                  '${car.year} • ${car.licensePlate}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${car.currentOdometer.toStringAsFixed(0)} كم',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.speed,
                                          color: Colors.white70, size: 14),
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
                },
              ),
            ),
            title: Text(
              '${_capitalize(car.make)} ${_capitalize(car.model)}',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // أزرار سريعة
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          icon: Icons.local_gas_station,
                          label: 'وقود',
                          color: const Color(0xFF1E88E5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddFuelScreen(car: car)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          icon: Icons.build,
                          label: 'خدمة',
                          color: const Color(0xFF43A047),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddServiceScreen(car: car)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          icon: Icons.speed,
                          label: 'عداد',
                          color: const Color(0xFFFB8C00),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    OdometerUpdateScreen(car: car)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          icon: Icons.bar_chart,
                          label: 'تقارير',
                          color: const Color(0xFFE53935),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ReportsScreen(car: car)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // القطع وحالتها
                  StreamBuilder<List<MaintenanceItemModel>>(
                    stream: itemService.getCarMaintenanceItems(car.carId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.build_circle,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'مفيش قطع مسجلة لسه',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'أضف سيارة جديدة لتسجيل القطع',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      // ترتيب القطع: الأحمر الأول ثم الأصفر ثم الأخضر
                      final sortedItems = List<MaintenanceItemModel>.from(items)
                        ..sort((a, b) {
                          final statusA = _getPartStatus(a, car);
                          final statusB = _getPartStatus(b, car);
                          return statusA.compareTo(statusB);
                        });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ملخص سريع
                              Row(
                                children: [
                                  _buildStatusBadge(
                                    sortedItems
                                        .where((i) =>
                                            _getPartStatus(i, car) == 0)
                                        .length,
                                    Colors.red,
                                    'متأخر',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(
                                    sortedItems
                                        .where((i) =>
                                            _getPartStatus(i, car) == 1)
                                        .length,
                                    Colors.orange,
                                    'قريب',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(
                                    sortedItems
                                        .where((i) =>
                                            _getPartStatus(i, car) == 2)
                                        .length,
                                    Colors.green,
                                    'تمام',
                                  ),
                                ],
                              ),
                              Text(
                                'حالة القطع 🔧',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8E24AA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...sortedItems.map((item) =>
                              _buildPartCard(item, car)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // آخر تزود وقود
                  StreamBuilder<List<FuelLogModel>>(
                    stream: fuelService.getCarFuelLogs(car.carId),
                    builder: (context, snapshot) {
                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) return const SizedBox.shrink();

                      final last = logs.first;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LogsScreen(car: car)),
                        ),
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
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 14, color: Colors.grey),
                                      Text(
                                        'كل السجلات',
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'آخر تزود وقود ⛽',
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFB8C00),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildFuelStat(
                                    '${last.totalCost.toStringAsFixed(0)} ج.م',
                                    'التكلفة',
                                    Icons.attach_money,
                                    const Color(0xFFE53935),
                                  ),
                                  _buildFuelStat(
                                    '${last.fuelAmount} لتر',
                                    'الكمية',
                                    Icons.local_gas_station,
                                    const Color(0xFFFB8C00),
                                  ),
                                  _buildFuelStat(
                                    DateFormat('dd/MM').format(last.date),
                                    'التاريخ',
                                    Icons.calendar_today,
                                    const Color(0xFF1E88E5),
                                  ),
                                  if (last.calculatedEfficiency != null)
                                    _buildFuelStat(
                                      '${last.calculatedEfficiency!.toStringAsFixed(1)}',
                                      'ل/100كم',
                                      Icons.show_chart,
                                      const Color(0xFF43A047),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // حساب Health Score
  int _calcHealthScore(List<MaintenanceItemModel> items, CarModel car) {
    if (items.isEmpty) return 100;
    int score = 100;
    for (final item in items) {
      final status = _getPartStatus(item, car);
      if (status == 0) score -= 15; // متأخر
      if (status == 1) score -= 5; // قريب
    }
    return score.clamp(0, 100);
  }

  // 0 = متأخر (أحمر), 1 = قريب (أصفر), 2 = تمام (أخضر)
  int _getPartStatus(MaintenanceItemModel item, CarModel car) {
    bool isOverdue = false;
    bool isSoon = false;

    // فحص بالكيلو
    if (item.nextDueOdometer != null) {
      final remaining = item.nextDueOdometer! - car.currentOdometer;
      if (remaining <= 0) isOverdue = true;
      if (remaining <= 500 && remaining > 0) isSoon = true;
    }

    // فحص بالتاريخ
    if (item.nextDueDate != null) {
      final daysLeft = item.nextDueDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 0) isOverdue = true;
      if (daysLeft <= 30 && daysLeft > 0) isSoon = true;
    }

    if (isOverdue) return 0;
    if (isSoon) return 1;
    return 2;
  }

  Widget _buildPartCard(MaintenanceItemModel item, CarModel car) {
    final status = _getPartStatus(item, car);
    final statusColor = status == 0
        ? Colors.red
        : status == 1
            ? Colors.orange
            : Colors.green;
    final statusIcon = status == 0
        ? Icons.warning
        : status == 1
            ? Icons.access_time
            : Icons.check_circle;
    final statusText = status == 0
        ? 'متأخر!'
        : status == 1
            ? 'قريب'
            : 'تمام';

    // حساب المسافة المتبقية
    String remainingText = '';
    if (item.nextDueOdometer != null) {
      final remaining = item.nextDueOdometer! - car.currentOdometer;
      if (remaining <= 0) {
        remainingText = 'تجاوز ${(-remaining).toStringAsFixed(0)} كم';
      } else {
        remainingText = 'باقي ${remaining.toStringAsFixed(0)} كم';
      }
    } else if (item.nextDueDate != null) {
      final daysLeft = item.nextDueDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 0) {
        remainingText = 'تجاوز ${(-daysLeft)} يوم';
      } else {
        remainingText = 'باقي $daysLeft يوم';
      }
    }

    // شريط التقدم
    double progress = 1.0;
    if (item.intervalKm != null && item.lastServiceOdometer != null) {
      final driven = car.currentOdometer - item.lastServiceOdometer!;
      progress = (driven / item.intervalKm!).clamp(0.0, 1.0);
    } else if (item.intervalDays != null && item.lastServiceDate != null) {
      final elapsed =
          DateTime.now().difference(item.lastServiceDate!).inDays;
      progress = (elapsed / item.intervalDays!).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 0
              ? Colors.red.withOpacity(0.3)
              : status == 1
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
          width: status <= 1 ? 1.5 : 1,
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
              // الحالة
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // اسم القطعة
              Text(
                item.title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: status == 0 ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
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
              if (item.nextDueOdometer != null)
                Text(
                  'عند ${item.nextDueOdometer!.toStringAsFixed(0)} كم',
                  style: GoogleFonts.cairo(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                )
              else if (item.nextDueDate != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(item.nextDueDate!),
                  style: GoogleFonts.cairo(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelStat(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}