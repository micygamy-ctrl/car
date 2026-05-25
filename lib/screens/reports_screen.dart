import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/fuel_service.dart';
import '../models/fuel_log_model.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';
import '../services/maintenance_service.dart';

class ReportsScreen extends StatelessWidget {
  final CarModel car;

  const ReportsScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final FuelService fuelService = FuelService();
     final MaintenanceService maintenanceService = MaintenanceService();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
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
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
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
                          '${car.make} ${car.model}',
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
                  StreamBuilder<List<FuelLogModel>>(
                    stream: fuelService.getCarFuelLogs(car.carId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final logs = snapshot.data ?? [];

                      if (logs.isEmpty) {
                        return _buildEmptyCard(
                          'مفيش سجلات وقود لسه',
                          Icons.local_gas_station,
                          const Color(0xFFE53935),
                        );
                      }

                      double totalCost = 0;
                      double totalFuel = 0;
                      double totalEfficiency = 0;
                      int efficiencyCount = 0;

                      for (var log in logs) {
                        totalCost += log.totalCost;
                        totalFuel += log.fuelAmount;
                        if (log.calculatedEfficiency != null) {
                          totalEfficiency += log.calculatedEfficiency!;
                          efficiencyCount++;
                        }
                      }

                      final avgEfficiency = efficiencyCount > 0
                          ? totalEfficiency / efficiencyCount
                          : null;

                      return Column(
                        children: [
                          _buildSectionHeader('إحصاءات الوقود', Icons.local_gas_station, const Color(0xFFE53935)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'إجمالي الإنفاق',
                                  '${totalCost.toStringAsFixed(0)}',
                                  'ج.م',
                                  Icons.attach_money,
                                  const Color(0xFFE53935),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'إجمالي الوقود',
                                  '${totalFuel.toStringAsFixed(1)}',
                                  'لتر',
                                  Icons.local_gas_station,
                                  const Color(0xFFFB8C00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'عدد التزود',
                                  '${logs.length}',
                                  'مرة',
                                  Icons.format_list_numbered,
                                  const Color(0xFF1E88E5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'متوسط الاستهلاك',
                                  avgEfficiency != null
                                      ? avgEfficiency.toStringAsFixed(1)
                                      : '-',
                                  'ل/100كم',
                                  Icons.show_chart,
                                  const Color(0xFF43A047),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader('آخر سجلات الوقود', Icons.history, const Color(0xFFE53935)),
                          const SizedBox(height: 12),
                          ...logs.take(5).map((log) => _buildFuelMiniCard(log)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<ServiceLogModel>>(
                    stream: maintenanceService.getCarMaintenanceLogs(car.carId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final logs = snapshot.data ?? [];

                      if (logs.isEmpty) {
                        return _buildEmptyCard(
                          'مفيش سجلات صيانة لسه',
                          Icons.build,
                          const Color(0xFF43A047),
                        );
                      }

                      double totalCost = 0;
                      for (var log in logs) {
                        totalCost += log.cost;
                      }

                      return Column(
                        children: [
                          _buildSectionHeader('إحصاءات الصيانة', Icons.build, const Color(0xFF43A047)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'إجمالي تكلفة الصيانة',
                                  '${totalCost.toStringAsFixed(0)}',
                                  'ج.م',
                                  Icons.attach_money,
                                  const Color(0xFF43A047),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'عدد العمليات',
                                  '${logs.length}',
                                  'عملية',
                                  Icons.build,
                                  const Color(0xFF1E88E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<FuelLogModel>>(
                            stream: fuelService.getCarFuelLogs(car.carId),
                            builder: (context, fuelSnapshot) {
                              double fuelTotal = 0;
                              for (var log in fuelSnapshot.data ?? []) {
                                fuelTotal += log.totalCost;
                              }
                              final grandTotal = totalCost + fuelTotal;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E88E5).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'إجمالي الإنفاق على السيارة',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${grandTotal.toStringAsFixed(0)} ج.م',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'وقود + صيانة',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader('آخر سجلات الصيانة', Icons.history, const Color(0xFF43A047)),
                          const SizedBox(height: 12),
                          ...logs.take(5).map((log) => _buildMaintenanceMiniCard(log)),
                        ],
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 20),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.cairo(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFuelMiniCard(FuelLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${log.totalCost.toStringAsFixed(0)} ج.م',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53935),
            ),
          ),
          Row(
            children: [
              Text(
                '${log.fuelAmount} لتر',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd/MM/yyyy').format(log.date),
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceMiniCard(ServiceLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${log.cost.toStringAsFixed(0)} ج.م',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF43A047),
            ),
          ),
          Text(
            log.title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}