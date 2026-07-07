import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/car_model.dart';
import '../../models/fuel_log_model.dart';
import '../../services/fuel_service.dart';
import 'report_shared_widgets.dart';

// ═══════════════════════════════════════════════════════
//  TAB 1 — FUEL
// ═══════════════════════════════════════════════════════
class FuelReportTab extends StatelessWidget {
  final CarModel car;
  final FuelService fuelService;

  const FuelReportTab({required this.car, required this.fuelService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FuelLogModel>>(
      stream: fuelService.getCarFuelLogs(car.carId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return emptyState('مفيش سجلات وقود لسه', Icons.local_gas_station);
        }

        // إحصاءات أساسية
        double totalCost = 0, totalFuel = 0, totalEff = 0;
        int effCount = 0;
        for (final l in logs) {
          totalCost += l.totalCost;
          totalFuel += l.fuelAmount;
          if (l.calculatedEfficiency != null) {
            totalEff += l.calculatedEfficiency!;
            effCount++;
          }
        }
        final avgEff = effCount > 0 ? totalEff / effCount : null;
        final avgCostPerFill = totalCost / logs.length;

        // بيانات chart التكلفة (آخر 8 تزودات)
        final chartLogs = logs.reversed.take(8).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // إحصاءات سريعة
              statsGrid([
                StatData('إجمالي الإنفاق', '${totalCost.toStringAsFixed(0)}',
                    'ج.م', Icons.attach_money, const Color(0xFFE53935)),
                StatData('إجمالي الوقود', '${totalFuel.toStringAsFixed(0)}',
                    'لتر', Icons.local_gas_station, const Color(0xFFFB8C00)),
                StatData('عدد التزودات', '${logs.length}', 'مرة',
                    Icons.format_list_numbered, const Color(0xFF1E88E5)),
                StatData('متوسط التزود', avgCostPerFill.toStringAsFixed(0),
                    'ج.م', Icons.show_chart, const Color(0xFF8E24AA)),
              ]),

              const SizedBox(height: 20),

              // Chart: تكلفة كل تزود
              ChartCard(
                title: 'تكلفة كل تزود ⛽',
                color: const Color(0xFFE53935),
                chart: _buildCostBarChart(chartLogs),
              ),

              const SizedBox(height: 16),

              // Chart: استهلاك الوقود
              if (avgEff != null) ...[
                ChartCard(
                  title: 'استهلاك الوقود (ل/100كم)',
                  color: const Color(0xFF43A047),
                  chart: _buildEfficiencyLineChart(chartLogs
                      .where((l) => l.calculatedEfficiency != null)
                      .toList()),
                  subtitle: 'متوسط ${avgEff.toStringAsFixed(1)} ل/100كم',
                ),
                const SizedBox(height: 16),
              ],

              // آخر السجلات
              sectionHeader(
                  'آخر التزودات', Icons.history, const Color(0xFFE53935)),
              const SizedBox(height: 8),
              ...logs.take(6).map((l) => FuelRow(log: l)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCostBarChart(List<FuelLogModel> logs) {
    if (logs.isEmpty) return const SizedBox(height: 160);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: logs.map((l) => l.totalCost).reduce((a, b) => a > b ? a : b) *
              1.3,
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
                  return Text(
                    DateFormat('d/M').format(logs[i].date),
                    style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
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
                  toY: e.value.totalCost,
                  color: const Color(0xFFE53935),
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: logs
                            .map((l) => l.totalCost)
                            .reduce((a, b) => a > b ? a : b) *
                        1.3,
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

  Widget _buildEfficiencyLineChart(List<FuelLogModel> logs) {
    if (logs.length < 2) return const SizedBox(height: 160);
    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.calculatedEfficiency!);
    }).toList();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} ل/100',
                        GoogleFonts.cairo(color: Colors.white, fontSize: 11),
                      ))
                  .toList(),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= logs.length) return const SizedBox();
                  return Text(
                    DateFormat('d/M').format(logs[i].date),
                    style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
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
                reservedSize: 32,
                getTitlesWidget: (val, meta) => Text(
                  val.toStringAsFixed(1),
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF43A047),
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF43A047),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF43A047).withAlpha(26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}