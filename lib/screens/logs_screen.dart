import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/fuel_service.dart';
import '../services/maintenance_service.dart';
import '../models/fuel_log_model.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';

class LogsScreen extends StatefulWidget {
  final CarModel car;

  const LogsScreen({super.key, required this.car});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FuelService _fuelService = FuelService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'السجلات 📋',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_gas_station, size: 18),
                  const SizedBox(width: 6),
                  Text('الوقود',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build, size: 18),
                  const SizedBox(width: 6),
                  Text('الصيانة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFuelLogs(),
          _buildMaintenanceLogs(),
        ],
      ),
    );
  }

  Widget _buildFuelLogs() {
    return StreamBuilder<List<FuelLogModel>>(
      stream: _fuelService.getCarFuelLogs(widget.car.carId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return _buildEmpty('مفيش سجلات وقود لسه',
              Icons.local_gas_station, const Color(0xFFFB8C00));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) => _buildFuelCard(logs[index]),
        );
      },
    );
  }

  Widget _buildFuelCard(FuelLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB8C00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${log.totalCost.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFFB8C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(log.date),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    if (log.stationName != null)
                      Text(
                        log.stationName!,
                        style: GoogleFonts.cairo(
                            color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLogStat(Icons.speed, '${log.odometer} كم', Colors.blue),
                _buildLogStat(Icons.local_gas_station,
                    '${log.fuelAmount} لتر', const Color(0xFFFB8C00)),
                _buildLogStat(Icons.attach_money,
                    '${log.pricePerUnit} ج.م/ل', Colors.green),
                if (log.calculatedEfficiency != null)
                  _buildLogStat(
                      Icons.show_chart,
                      '${log.calculatedEfficiency!.toStringAsFixed(1)} ل/100',
                      Colors.purple),
              ],
            ),
            if (log.isFullTank) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'خزان ممتلئ',
                    style: GoogleFonts.cairo(
                        color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 14),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceLogs() {
    return StreamBuilder<List<MaintenanceLogModel>>(
      stream: _maintenanceService.getCarMaintenanceLogs(widget.car.carId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return _buildEmpty('مفيش سجلات صيانة لسه', Icons.build,
              const Color(0xFF43A047));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) =>
              _buildMaintenanceCard(logs[index]),
        );
      },
    );
  }

  Widget _buildMaintenanceCard(MaintenanceLogModel log) {
    final categoryData = {
      'oil_change': {'label': 'تغيير زيت', 'icon': Icons.oil_barrel, 'color': Colors.orange},
      'tire': {'label': 'إطارات', 'icon': Icons.tire_repair, 'color': Colors.blue},
      'brakes': {'label': 'فرامل', 'icon': Icons.car_crash, 'color': Colors.red},
      'inspection': {'label': 'فحص دوري', 'icon': Icons.fact_check, 'color': Colors.green},
      'other': {'label': 'أخرى', 'icon': Icons.build, 'color': Colors.grey},
    };

    final data = categoryData[log.category] ?? categoryData['other']!;
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;
    final label = data['label'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${log.cost.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.cairo(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      log.title,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(log.date),
                      style: GoogleFonts.cairo(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (log.garage != null)
                  _buildLogStat(Icons.garage, log.garage!, Colors.grey),
                _buildLogStat(
                    Icons.speed, '${log.odometer} كم', Colors.blue),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(label,
                          style: GoogleFonts.cairo(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(icon, color: color, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            if (log.nextDueOdometer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'الصيانة القادمة عند ${log.nextDueOdometer} كم',
                      style: GoogleFonts.cairo(
                          color: Colors.green, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.notifications,
                        color: Colors.green, size: 14),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
              color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmpty(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}