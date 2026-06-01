import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car_model.dart';
import '../models/fuel_log_model.dart';
import '../models/maintenance_log_model.dart';
import '../services/car_service.dart';
import '../services/fuel_service.dart';
import '../services/maintenance_health_service.dart';
import '../services/maintenance_service.dart';
import 'map_screen.dart';
import '../services/notification_service.dart';
import 'add_fuel_screen.dart';
import 'add_service_screen.dart';
import 'edit_car_screen.dart';
import 'logs_screen.dart';
import 'odometer_update_screen.dart';
import 'reports_screen.dart';

class CarDetailsScreen extends StatelessWidget {
  final CarModel car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final maintenanceService = MaintenanceService();
    final fuelService = FuelService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkOilChangeReminder(
        carName: '${car.make} ${car.model}',
        currentOdometer: car.currentOdometer,
        lastOilChangeOdometer: car.lastOilChangeOdometer,
        oilChangeInterval: car.oilChangeInterval,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: StreamBuilder<List<ServiceLogModel>>(
        stream: maintenanceService.getCarMaintenanceLogs(car.carId),
        builder: (context, serviceSnapshot) {
          final serviceLogs = serviceSnapshot.data ?? [];
          final health = MaintenanceHealthService().evaluate(
            car: car,
            serviceLogs: serviceLogs,
          );

          return StreamBuilder<List<FuelLogModel>>(
            stream: fuelService.getCarFuelLogs(car.carId),
            builder: (context, fuelSnapshot) {
              final fuelLogs = fuelSnapshot.data ?? [];
              final stats = _DashboardStats.from(fuelLogs, serviceLogs);

              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, health),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHealthPanel(health),
                          const SizedBox(height: 14),
                          _buildAttentionPanel(context, health),
                          const SizedBox(height: 14),
                          _buildStatsGrid(stats),
                          const SizedBox(height: 18),
                          _buildQuickActions(context),
                          const SizedBox(height: 18),
                          _buildMaintenanceList(health.items),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    CarHealthSnapshot health,
  ) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: const Color(0xFF1565C0),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          tooltip: 'تعديل',
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditCarScreen(car: car)),
            );
          },
        ),
        IconButton(
          tooltip: 'حذف',
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () => _confirmDelete(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF0B3D91)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildScoreRing(health),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_capitalize(car.make)} ${_capitalize(car.model)}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${car.year} • ${car.licensePlate} • ${car.fuelType}',
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusPill(health),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        '${_capitalize(car.make)} ${_capitalize(car.model)}',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreRing(CarHealthSnapshot health) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: health.score / 100,
            strokeWidth: 8,
            backgroundColor: Colors.white24,
            color: health.statusColor,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${health.score}',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'صحة',
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(CarHealthSnapshot health) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: health.statusColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            health.attentionCount > 0 ? Icons.priority_high : Icons.check,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            health.statusText,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPanel(CarHealthSnapshot health) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SectionTitle(
            title: 'ملخص السيارة',
            icon: Icons.dashboard_customize,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'العداد',
                  value: car.currentOdometer.toStringAsFixed(0),
                  unit: 'كم',
                  icon: Icons.speed,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'تحتاج متابعة',
                  value: '${health.attentionCount}',
                  unit: 'عنصر',
                  icon: Icons.notifications_active,
                  color: health.statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'سعة الخزان',
                  value: car.tankCapacity.toStringAsFixed(0),
                  unit: 'لتر',
                  icon: Icons.local_gas_station,
                  color: const Color(0xFFFB8C00),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'دورة الزيت',
                  value: car.oilChangeInterval.toStringAsFixed(0),
                  unit: 'كم',
                  icon: Icons.oil_barrel,
                  color: const Color(0xFF43A047),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionPanel(
    BuildContext context,
    CarHealthSnapshot health,
  ) {
    final attentionItems = health.items.where((item) => item.needsAttention);
    final visibleItems = attentionItems.take(3).toList();

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SectionTitle(
            title: 'تنبيهات الصيانة',
            icon: Icons.health_and_safety,
            color: health.statusColor,
          ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            _EmptyState(
              icon: Icons.verified,
              text: 'كل القطع المسجلة حالتها مستقرة',
              color: const Color(0xFF43A047),
            )
          else
            ...visibleItems.map((item) => _MaintenanceAlertRow(item: item)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddServiceScreen(car: car),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: health.statusColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: Text(
                'تسجيل صيانة أو ميعاد قادم',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(_DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _CompactStat(
            label: 'وقود',
            value: stats.fuelCost.toStringAsFixed(0),
            unit: 'ج.م',
            icon: Icons.local_gas_station,
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompactStat(
            label: 'صيانة',
            value: stats.serviceCost.toStringAsFixed(0),
            unit: 'ج.م',
            icon: Icons.build,
            color: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompactStat(
            label: 'استهلاك',
            value: stats.averageEfficiency == null
                ? '-'
                : stats.averageEfficiency!.toStringAsFixed(1),
            unit: 'ل/100',
            icon: Icons.show_chart,
            color: const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _DashboardAction(
        label: 'وقود',
        icon: Icons.local_gas_station,
        color: const Color(0xFFE53935),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddFuelScreen(car: car)),
        ),
      ),
      _DashboardAction(
        label: 'صيانة',
        icon: Icons.miscellaneous_services,
        color: const Color(0xFF43A047),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddServiceScreen(car: car)),
        ),
      ),
      _DashboardAction(
        label: 'عداد',
        icon: Icons.location_searching,
        color: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OdometerUpdateScreen(car: car),
          ),
        ),
      ),
      _DashboardAction(
        label: 'تقارير',
        icon: Icons.bar_chart,
        color: const Color(0xFF8E24AA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReportsScreen(car: car)),
        ),
      ),
      _DashboardAction(
        label: 'سجلات',
        icon: Icons.history,
        color: const Color(0xFFFB8C00),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LogsScreen(car: car)),
        ),
      ),
      _DashboardAction(
        label: 'قريب',
        icon: Icons.map,
        color: const Color(0xFF00897B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _SectionTitle(
          title: 'إجراءات سريعة',
          icon: Icons.flash_on,
          color: Color(0xFF1565C0),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) =>
              _ActionButton(action: actions[index]),
        ),
      ],
    );
  }

  Widget _buildMaintenanceList(List<MaintenanceHealthItem> items) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionTitle(
            title: 'خريطة القطع',
            icon: Icons.checklist_rtl,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(height: 12),
          ...items.take(6).map((item) => _MaintenanceProgressRow(item: item)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف السيارة', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من حذف السيارة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لا', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'نعم',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CarService().deleteCar(car.carId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _DashboardStats {
  final double fuelCost;
  final double serviceCost;
  final double? averageEfficiency;

  const _DashboardStats({
    required this.fuelCost,
    required this.serviceCost,
    required this.averageEfficiency,
  });

  factory _DashboardStats.from(
    List<FuelLogModel> fuelLogs,
    List<ServiceLogModel> serviceLogs,
  ) {
    final fuelCost = fuelLogs.fold<double>(
      0,
      (sum, log) => sum + log.totalCost,
    );
    final serviceCost = serviceLogs.fold<double>(
      0,
      (sum, log) => sum + log.cost,
    );
    final efficiencyLogs = fuelLogs
        .where((log) => log.calculatedEfficiency != null)
        .map((log) => log.calculatedEfficiency!)
        .toList();
    final averageEfficiency = efficiencyLogs.isEmpty
        ? null
        : efficiencyLogs.reduce((a, b) => a + b) / efficiencyLogs.length;

    return _DashboardStats(
      fuelCost: fuelCost,
      serviceCost: serviceCost,
      averageEfficiency: averageEfficiency,
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 20),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            '$value $unit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceAlertRow extends StatelessWidget {
  final MaintenanceHealthItem item;

  const _MaintenanceAlertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.statusLabel} • ${item.detail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceProgressRow extends StatelessWidget {
  final MaintenanceHealthItem item;

  const _MaintenanceProgressRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                item.statusLabel,
                style: GoogleFonts.cairo(
                  color: item.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Icon(item.icon, color: item.color, size: 18),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: item.progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFECEFF3),
            color: item.color,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 5),
          Text(
            item.detail,
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color),
        ],
      ),
    );
  }
}

class _DashboardAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionButton extends StatelessWidget {
  final _DashboardAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE6EAF0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 26),
              const SizedBox(height: 8),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  color: action.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
