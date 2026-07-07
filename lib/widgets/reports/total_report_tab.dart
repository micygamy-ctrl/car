import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/car_model.dart';
import '../../models/fuel_log_model.dart';
import '../../models/maintenance_log_model.dart';
import '../../services/fuel_service.dart';
import '../../services/maintenance_service.dart';
import 'report_shared_widgets.dart';

// ═══════════════════════════════════════════════════════
//  TAB 3 — TOTAL SPENDING
// ═══════════════════════════════════════════════════════
class TotalReportTab extends StatelessWidget {
  final CarModel car;
  final FuelService fuelService;
  final MaintenanceService maintenanceService;

  const TotalReportTab(
      {required this.car,
      required this.fuelService,
      required this.maintenanceService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FuelLogModel>>(
      stream: fuelService.getCarFuelLogs(car.carId),
      builder: (context, fuelSnap) {
        return StreamBuilder<List<ServiceLogModel>>(
          stream: maintenanceService.getCarMaintenanceLogs(car.carId),
          builder: (context, maintSnap) {
            if (fuelSnap.connectionState == ConnectionState.waiting ||
                maintSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final fuelLogs = fuelSnap.data ?? [];
            final maintLogs = maintSnap.data ?? [];

            double totalFuelCost = fuelLogs.fold(0, (s, l) => s + l.totalCost);
            double totalMaintCost = maintLogs.fold(0, (s, l) => s + l.cost);
            final grandTotal = totalFuelCost + totalMaintCost;

            // بناء الداتا للـ stacked bar chart: إنفاق شهري
            final Map<String, double> fuelByMonth = {};
            final Map<String, double> maintByMonth = {};
            for (final l in fuelLogs) {
              final k = DateFormat('MM/yy').format(l.date);
              fuelByMonth[k] = (fuelByMonth[k] ?? 0) + l.totalCost;
            }
            for (final l in maintLogs) {
              final k = DateFormat('MM/yy').format(l.date);
              maintByMonth[k] = (maintByMonth[k] ?? 0) + l.cost;
            }

            final allMonths =
                {...fuelByMonth.keys, ...maintByMonth.keys}.toList()..sort();
            final last6 = allMonths.length > 6
                ? allMonths.sublist(allMonths.length - 6)
                : allMonths;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // بطاقة الإجمالي الكبيرة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withAlpha(102),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'إجمالي الإنفاق على السيارة',
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${grandTotal.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _totalChip('وقود', totalFuelCost.toStringAsFixed(0),
                                Colors.orange),
                            const SizedBox(width: 12),
                            _totalChip(
                                'صيانة',
                                totalMaintCost.toStringAsFixed(0),
                                Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pie: نسبة وقود vs صيانة
                  if (grandTotal > 0)
                    ChartCard(
                      title: 'توزيع الإنفاق',
                      color: const Color(0xFF1E88E5),
                      chart: _buildSpendingPie(totalFuelCost, totalMaintCost),
                    ),

                  const SizedBox(height: 16),

                  // Stacked bar: إنفاق شهري
                  if (last6.isNotEmpty)
                    ChartCard(
                      title: 'الإنفاق الشهري 📅',
                      color: const Color(0xFFFB8C00),
                      chart:
                          _buildMonthlyChart(last6, fuelByMonth, maintByMonth),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _totalChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '$value ج.م',
            style: GoogleFonts.cairo(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSpendingPie(double fuelCost, double maintCost) {
    if (fuelCost == 0 && maintCost == 0) return const SizedBox(height: 160);
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: [
                  if (fuelCost > 0)
                    PieChartSectionData(
                      value: fuelCost,
                      color: const Color(0xFFFB8C00),
                      radius: 55,
                      title:
                          '${(fuelCost / (fuelCost + maintCost) * 100).toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (maintCost > 0)
                    PieChartSectionData(
                      value: maintCost,
                      color: const Color(0xFF43A047),
                      radius: 55,
                      title:
                          '${(maintCost / (fuelCost + maintCost) * 100).toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fuelCost > 0) _legend('وقود', const Color(0xFFFB8C00)),
              const SizedBox(height: 8),
              if (maintCost > 0) _legend('صيانة', const Color(0xFF43A047)),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(width: 6),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(List<String> months,
      Map<String, double> fuelByMonth, Map<String, double> maintByMonth) {
    if (months.isEmpty) return const SizedBox(height: 160);

    final maxY = months.map((m) {
          return (fuelByMonth[m] ?? 0) + (maintByMonth[m] ?? 0);
        }).reduce((a, b) => a > b ? a : b) *
        1.3;
    if (maxY == 0) return const SizedBox(height: 160);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) {
                final m = months[gi];
                final f = (fuelByMonth[m] ?? 0).toStringAsFixed(0);
                final s = (maintByMonth[m] ?? 0).toStringAsFixed(0);
                return BarTooltipItem(
                  'وقود: $f\nصيانة: $s',
                  GoogleFonts.cairo(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox();
                  return Text(months[i],
                      style:
                          GoogleFonts.cairo(fontSize: 9, color: Colors.grey));
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
          barGroups: months.asMap().entries.map((e) {
            final fuel = fuelByMonth[e.value] ?? 0;
            final maint = maintByMonth[e.value] ?? 0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: fuel + maint,
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  rodStackItems: [
                    BarChartRodStackItem(0, fuel, const Color(0xFFFB8C00)),
                    BarChartRodStackItem(
                        fuel, fuel + maint, const Color(0xFF43A047)),
                  ],
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
}