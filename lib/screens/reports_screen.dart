import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/fuel_service.dart';
import '../services/maintenance_service.dart';
import '../models/fuel_log_model.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';

class ReportsScreen extends StatefulWidget {
  final CarModel car;
  const ReportsScreen({super.key, required this.car});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FuelService _fuelService = FuelService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: const Color(0xFFE53935),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'التقارير 📊',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.car.make} ${widget.car.model}',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'التقارير',
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'الوقود ⛽'),
                Tab(text: 'الصيانة 🔧'),
                Tab(text: 'الإجمالي 💰'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _FuelReportTab(car: widget.car, fuelService: _fuelService),
            _MaintenanceReportTab(
                car: widget.car, maintenanceService: _maintenanceService),
            _TotalReportTab(
              car: widget.car,
              fuelService: _fuelService,
              maintenanceService: _maintenanceService,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 1 — FUEL
// ═══════════════════════════════════════════════════════
class _FuelReportTab extends StatelessWidget {
  final CarModel car;
  final FuelService fuelService;

  const _FuelReportTab({required this.car, required this.fuelService});

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
          return _emptyState('مفيش سجلات وقود لسه', Icons.local_gas_station);
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
              _statsGrid([
                _StatData('إجمالي الإنفاق', '${totalCost.toStringAsFixed(0)}',
                    'ج.م', Icons.attach_money, const Color(0xFFE53935)),
                _StatData('إجمالي الوقود', '${totalFuel.toStringAsFixed(0)}',
                    'لتر', Icons.local_gas_station, const Color(0xFFFB8C00)),
                _StatData(
                    'عدد التزودات', '${logs.length}', 'مرة',
                    Icons.format_list_numbered, const Color(0xFF1E88E5)),
                _StatData(
                    'متوسط التزود',
                    avgCostPerFill.toStringAsFixed(0),
                    'ج.م',
                    Icons.show_chart,
                    const Color(0xFF8E24AA)),
              ]),

              const SizedBox(height: 20),

              // Chart: تكلفة كل تزود
              _ChartCard(
                title: 'تكلفة كل تزود ⛽',
                color: const Color(0xFFE53935),
                chart: _buildCostBarChart(chartLogs),
              ),

              const SizedBox(height: 16),

              // Chart: استهلاك الوقود
              if (avgEff != null) ...[
                _ChartCard(
                  title: 'استهلاك الوقود (ل/100كم)',
                  color: const Color(0xFF43A047),
                  chart: _buildEfficiencyLineChart(
                      chartLogs.where((l) => l.calculatedEfficiency != null).toList()),
                  subtitle: 'متوسط ${avgEff.toStringAsFixed(1)} ل/100كم',
                ),
                const SizedBox(height: 16),
              ],

              // آخر السجلات
              _sectionHeader('آخر التزودات', Icons.history, const Color(0xFFE53935)),
              const SizedBox(height: 8),
              ...logs.take(6).map((l) => _FuelRow(log: l)),
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
          maxY: logs.map((l) => l.totalCost).reduce((a, b) => a > b ? a : b) * 1.3,
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: logs.map((l) => l.totalCost).reduce((a, b) => a > b ? a : b) * 1.3,
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

// ═══════════════════════════════════════════════════════
//  TAB 2 — MAINTENANCE
// ═══════════════════════════════════════════════════════
class _MaintenanceReportTab extends StatelessWidget {
  final CarModel car;
  final MaintenanceService maintenanceService;

  const _MaintenanceReportTab(
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
          return _emptyState('مفيش سجلات صيانة لسه', Icons.build);
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
              _statsGrid([
                _StatData('إجمالي الصيانة', totalCost.toStringAsFixed(0),
                    'ج.م', Icons.build, const Color(0xFF43A047)),
                _StatData('عدد العمليات', '${logs.length}', 'عملية',
                    Icons.format_list_numbered, const Color(0xFF1E88E5)),
                _StatData('متوسط تكلفة', avgCost.toStringAsFixed(0), 'ج.م',
                    Icons.analytics, const Color(0xFFE53935)),
                _StatData('آخر صيانة',
                    DateFormat('dd/MM').format(logs.first.date), '',
                    Icons.calendar_today, const Color(0xFFFB8C00)),
              ]),

              const SizedBox(height: 20),

              // Bar chart: تكلفة الصيانة لآخر 6 عمليات
              if (chartLogs.isNotEmpty)
                _ChartCard(
                  title: 'تكلفة آخر العمليات 🔧',
                  color: const Color(0xFF43A047),
                  chart: _buildMaintenanceBarChart(chartLogs),
                ),

              const SizedBox(height: 16),

              // Pie chart: توزيع حسب الفئة
              if (byCategory.isNotEmpty && byCategory.length > 1)
                _ChartCard(
                  title: 'توزيع التكاليف حسب الفئة',
                  color: const Color(0xFF8E24AA),
                  chart: _buildPieChart(byCategory),
                ),

              const SizedBox(height: 16),

              _sectionHeader('آخر العمليات', Icons.history, const Color(0xFF43A047)),
              const SizedBox(height: 8),
              ...logs.take(6).map((l) => _MaintenanceRow(log: l)),
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
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700]),
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

// ═══════════════════════════════════════════════════════
//  TAB 3 — TOTAL SPENDING
// ═══════════════════════════════════════════════════════
class _TotalReportTab extends StatelessWidget {
  final CarModel car;
  final FuelService fuelService;
  final MaintenanceService maintenanceService;

  const _TotalReportTab(
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

            double totalFuelCost =
                fuelLogs.fold(0, (s, l) => s + l.totalCost);
            double totalMaintCost =
                maintLogs.fold(0, (s, l) => s + l.cost);
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

            final allMonths = {
              ...fuelByMonth.keys,
              ...maintByMonth.keys
            }.toList()
              ..sort();
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
                            _totalChip('وقود',
                                totalFuelCost.toStringAsFixed(0), Colors.orange),
                            const SizedBox(width: 12),
                            _totalChip('صيانة',
                                totalMaintCost.toStringAsFixed(0), Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pie: نسبة وقود vs صيانة
                  if (grandTotal > 0)
                    _ChartCard(
                      title: 'توزيع الإنفاق',
                      color: const Color(0xFF1E88E5),
                      chart: _buildSpendingPie(totalFuelCost, totalMaintCost),
                    ),

                  const SizedBox(height: 16),

                  // Stacked bar: إنفاق شهري
                  if (last6.isNotEmpty)
                    _ChartCard(
                      title: 'الإنفاق الشهري 📅',
                      color: const Color(0xFFFB8C00),
                      chart: _buildMonthlyChart(
                          last6, fuelByMonth, maintByMonth),
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

// ═══════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════
class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget chart;
  final String? subtitle;

  const _ChartCard(
      {required this.title,
      required this.color,
      required this.chart,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (subtitle != null)
                Text(subtitle!,
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
              if (subtitle != null) const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}

class _StatData {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.unit, this.icon, this.color);
}

Widget _statsGrid(List<_StatData> stats) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.45,
    children: stats.map((s) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(s.icon, color: s.color, size: 22),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: s.value,
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: s.color)),
                if (s.unit.isNotEmpty)
                  TextSpan(
                      text: ' ${s.unit}',
                      style:
                          GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            Text(s.label,
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.right),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _sectionHeader(String title, IconData icon, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 6),
      Icon(icon, color: color, size: 18),
    ],
  );
}

Widget _emptyState(String msg, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.withAlpha(102)),
        const SizedBox(height: 12),
        Text(msg,
            style: GoogleFonts.cairo(
                fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _FuelRow extends StatelessWidget {
  final FuelLogModel log;
  const _FuelRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${log.totalCost.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE53935))),
          Row(children: [
            Text('${log.fuelAmount} لتر',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yy').format(log.date),
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  final ServiceLogModel log;
  const _MaintenanceRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${log.cost.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF43A047))),
          Text(log.title,
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
