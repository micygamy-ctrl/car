import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/fuel_service.dart';
import '../models/fuel_log_model.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';
import '../services/maintenance_service.dart';
import 'add_service_screen.dart';
import 'add_fuel_screen.dart';

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

  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'label': 'الكل', 'icon': Icons.list_alt, 'color': Colors.grey},
    {'value': 'maintenance', 'label': 'صيانة', 'icon': Icons.build, 'color': Color(0xFF43A047)},
    {'value': 'insurance', 'label': 'تأمين', 'icon': Icons.shield, 'color': Color(0xFF1E88E5)},
    {'value': 'license', 'label': 'رخصة', 'icon': Icons.credit_card, 'color': Color(0xFF8E24AA)},
    {'value': 'violation', 'label': 'مخالفة', 'icon': Icons.warning, 'color': Color(0xFFE53935)},
    {'value': 'wash', 'label': 'غسيل', 'icon': Icons.local_car_wash, 'color': Color(0xFF00ACC1)},
    {'value': 'inspection', 'label': 'فحص', 'icon': Icons.fact_check, 'color': Color(0xFFFB8C00)},
    {'value': 'emergency', 'label': 'طوارئ', 'icon': Icons.emergency, 'color': Color(0xFFD81B60)},
    {'value': 'other', 'label': 'أخرى', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFB8C00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'إضافة وقود' : 'إضافة صيانة',
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AddFuelScreen(car: widget.car)));
          } else {
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AddServiceScreen(car: widget.car)));
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'السجلات',
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
                  const Icon(Icons.miscellaneous_services, size: 18),
                  const SizedBox(width: 6),
                  Text('الخدمات',
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
          _buildServiceLogs(),
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

  Widget _buildServiceLogs() {
    return StreamBuilder<List<ServiceLogModel>>(
      stream: _maintenanceService.getCarMaintenanceLogs(widget.car.carId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLogs = snapshot.data ?? [];

        final logs = _selectedCategory == 'all'
            ? allLogs
            : allLogs.where((l) => l.category == _selectedCategory).toList();

        return Column(
          children: [
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['value'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData,
                              size: 14,
                              color: isSelected ? Colors.white : color),
                          const SizedBox(width: 4),
                          Text(
                            cat['label'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? _buildEmpty('مفيش سجلات لسه',
                      Icons.miscellaneous_services, const Color(0xFF43A047))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) =>
                          _buildServiceCard(logs[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard(ServiceLogModel log) {
    final categoryData = {
      'maintenance': {'label': 'صيانة', 'icon': Icons.build, 'color': const Color(0xFF43A047)},
      'insurance': {'label': 'تأمين', 'icon': Icons.shield, 'color': const Color(0xFF1E88E5)},
      'license': {'label': 'رخصة', 'icon': Icons.credit_card, 'color': const Color(0xFF8E24AA)},
      'violation': {'label': 'مخالفة', 'icon': Icons.warning, 'color': const Color(0xFFE53935)},
      'wash': {'label': 'غسيل', 'icon': Icons.local_car_wash, 'color': const Color(0xFF00ACC1)},
      'inspection': {'label': 'فحص', 'icon': Icons.fact_check, 'color': const Color(0xFFFB8C00)},
      'emergency': {'label': 'طوارئ', 'icon': Icons.emergency, 'color': const Color(0xFFD81B60)},
      'oil_change': {'label': 'تغيير زيت', 'icon': Icons.oil_barrel, 'color': Colors.orange},
      'other': {'label': 'أخرى', 'icon': Icons.more_horiz, 'color': Colors.grey},
    };

    final data = categoryData[log.category] ?? categoryData['other']!;
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;
    final label = data['label'] as String;

    int? daysLeft;
    if (log.expiryDate != null) {
      daysLeft = log.expiryDate!.difference(DateTime.now()).inDays;
    }

    return Dismissible(
      key: Key(log.logId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('حذف الخدمة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text('متأكد إنك عايز تمسح الخدمة دي؟',
                style: GoogleFonts.cairo()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('لا', style: GoogleFonts.cairo()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('امسح',
                    style: GoogleFonts.cairo(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _maintenanceService.deleteMaintenanceLog(log.logId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف الخدمة', style: GoogleFonts.cairo()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(label,
                                style: GoogleFonts.cairo(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${log.cost.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (log.garage != null)
                    _buildLogStat(Icons.garage, log.garage!, Colors.grey),
                  if (log.odometer != null)
                    _buildLogStat(Icons.speed,
                        '${log.odometer!.toStringAsFixed(0)} كم', Colors.blue),
                  if (log.provider != null)
                    _buildLogStat(Icons.business, log.provider!, Colors.purple),
                ],
              ),
              if (log.expiryDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: daysLeft != null && daysLeft <= 30
                        ? Colors.red.withAlpha(26)
                        : Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        daysLeft != null && daysLeft <= 0
                            ? 'انتهت الصلاحية!'
                            : daysLeft != null && daysLeft <= 30
                                ? 'ينتهي خلال $daysLeft يوم!'
                                : 'ينتهي في ${DateFormat('dd/MM/yyyy').format(log.expiryDate!)}',
                        style: GoogleFonts.cairo(
                          color: daysLeft != null && daysLeft <= 30
                              ? Colors.red
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        daysLeft != null && daysLeft <= 30
                            ? Icons.warning
                            : Icons.check_circle,
                        color: daysLeft != null && daysLeft <= 30
                            ? Colors.red
                            : Colors.green,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
              if (log.nextDueOdometer != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'الموعد القادم عند ${log.nextDueOdometer!.toStringAsFixed(0)} كم',
                        style: GoogleFonts.cairo(
                            color: Colors.blue, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.update, color: Colors.blue, size: 14),
                    ],
                  ),
                ),
              ],
              if (log.notes != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      log.notes!,
                      style: GoogleFonts.cairo(
                          color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.note, color: Colors.grey, size: 14),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelCard(FuelLogModel log) {
    return Dismissible(
      key: Key(log.logId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('حذف السجل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text('متأكد إنك عايز تمسح سجل الوقود ده؟',
                style: GoogleFonts.cairo()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('لا', style: GoogleFonts.cairo()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('امسح',
                    style: GoogleFonts.cairo(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _fuelService.deleteFuelLog(log.logId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف السجل', style: GoogleFonts.cairo()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                      color: const Color(0xFFFB8C00).withAlpha(26),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      ),
    );
  }

  Widget _buildLogStat(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
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
              color: color.withAlpha(26),
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