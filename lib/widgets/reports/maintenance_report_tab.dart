import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/car_model.dart';
import '../../models/maintenance_log_model.dart';
import '../../services/maintenance_service.dart';
import 'report_shared_widgets.dart';

// ═══════════════════════════════════════════════════════
//  TAB 2 — MAINTENANCE
// ═══════════════════════════════════════════════════════
class MaintenanceReportTab extends StatelessWidget {
  final CarModel car;
  final MaintenanceService maintenanceService;

  const MaintenanceReportTab(
      {required this.car, required this.maintenanceService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceLogModel>>(
      stream: maintenanceService.getCarMaintenanceLogs(car.carId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return emptyState('مفيش سجلات صيانة لسه', Icons.build);
        }

        double totalCost = 0;
        for (final l in logs) {
          totalCost += l.cost;
        }
        final avgCost = totalCost / logs.length;

        // تجميع التكاليف بالشهر (آخر 6 شهور)
        final Map<String, double> byMonth = {};
        for (final l in logs) {
          final key = DateFormat('MM/yy').format(l.date);
          byMonth[key] = (byMonth[key] ?? 0) + l.cost;
        }

        // pie chart: توزيع التكاليف حسب الفئة
        final Map<String, double> byCategory = {};
        for (final l in logs) {
          final cat = _catLabel(l.category);
          byCategory[cat] = (byCategory[cat] ?? 0) + l.cost;
        }

        final chartLogs = logs.reversed.take(6).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              statsGrid([
                StatData('إجمالي الصيانة', totalCost.toStringAsFixed(0), 'ج.م',
                    Icons.build, const Color(0xFF43A047)),
                StatData('عدد العمليات', '${logs.length}', 'عملية',
                    Icons.format_list_numbered, const Color(0xFF1E88E5)),
                StatData('متوسط تكلفة', avgCost.toStringAsFixed(0), 'ج.م',
                    Icons.analytics, const Color(0xFFE53935)),
                StatData(
                    'آخر صيانة',
                    DateFormat('dd/MM').format(logs.first.date),
                    '',
                    Icons.calendar_today,
                    const Color(0xFFFB8C00)),
              ]),

              const SizedBox(height: 20),

              // Bar chart: تكلفة الصيانة لآخر 6 عمليات
              if (chartLogs.isNotEmpty)
                ChartCard(
                  title: 'تكلفة آخر العمليات 🔧',
                  color: const Color(0xFF43A047),
                  chart: _buildMaintenanceBarChart(chartLogs),
                ),

              const SizedBox(height: 16),

              // Pie chart: توزيع حسب الفئة
              if (byCategory.isNotEmpty && byCategory.length > 1)
                ChartCard(
                  title: 'توزيع التكاليف حسب الفئة',
                  color: const Color(0xFF8E24AA),
                  chart: _buildPieChart(byCategory),
                ),

              const SizedBox(height: 16),

              sectionHeader(
                  'آخر العمليات', Icons.history, const Color(0xFF43A047)),
              const SizedBox(height: 8),
              ...logs.take(6).map((l) => MaintenanceRow(log: l)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceBarChart(List<ServiceLogModel> logs) {
    if (logs.isEmpty) return const SizedBox(height: 160);
    final maxY = logs.map((l) => l.cost).reduce((a, b) => a > b ? a : b) * 1.3;
    if (maxY == 0) return const SizedBox(height: 160);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} ج',
                GoogleFonts.cairo(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= logs.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      logs[i].title.length > 5
                          ? logs[i].title.substring(0, 5)
                          : logs[i].title,
                      style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, meta) => Text(
                  val.toStringAsFixed(0),
                  style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.withAlpha(38), strokeWidth: 1),
          ),
          barGroups: logs.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.cost,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withAlpha(20),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF1E88E5),
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
      const Color(0xFF8E24AA),
      const Color(0xFF00ACC1),
    ];
    final entries = data.entries.toList();
    final total = data.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 38,
                sections: entries.asMap().entries.map((e) {
                  final pct = (e.value.value / total * 100);
                  return PieChartSectionData(
                    value: e.value.value,
                    color: colors[e.key % colors.length],
                    radius: 55,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          // Legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value.key,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _catLabel(String? cat) {
    switch (cat) {
      case 'oil':
        return 'زيت';
      case 'brakes':
        return 'فرامل';
      case 'tires':
        return 'إطارات';
      case 'electrical':
        return 'كهرباء';
      case 'engine':
        return 'موتور';
      case 'fuel':
        return 'وقود';
      default:
        return 'أخرى';
    }
  }
}