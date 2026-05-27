import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'add_fuel_screen.dart';
import 'reports_screen.dart';
import 'logs_screen.dart';
import '../services/notification_service.dart';
import 'edit_car_screen.dart';
import 'add_service_screen.dart';
import 'odometer_update_screen.dart';
import '../services/map_screen.dart';


class CarDetailsScreen extends StatelessWidget {
  final CarModel car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final CarService carService = CarService();

    double kmDriven = car.currentOdometer - car.lastOilChangeOdometer;
double kmToNextOil = car.oilChangeInterval - kmDriven;
bool oilSoon = kmToNextOil <= 500;

WidgetsBinding.instance.addPostFrameCallback((_) {
  NotificationService().checkOilChangeReminder(
    carName: '${car.make} ${car.model}',
    currentOdometer: car.currentOdometer,
    lastOilChangeOdometer: car.lastOilChangeOdometer,
    oilChangeInterval: car.oilChangeInterval,
  );
});

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCarScreen(car: car),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                          child: Text('نعم',
                              style: GoogleFonts.cairo(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await carService.deleteCar(car.carId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_capitalize(car.make)} ${_capitalize(car.model)}',
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${car.year} • ${car.licensePlate} • ${car.fuelType}',
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: oilSoon
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    oilSoon ? Icons.warning : Icons.check_circle,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    oilSoon
                                        ? 'حان وقت تغيير الزيت! 🔴'
                                        : 'تغيير الزيت قريب! باقي ${kmToNextOil.toStringAsFixed(0)} كم 🔵',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // كارت العداد
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'العداد الحالي',
                          '${car.currentOdometer.toStringAsFixed(0)}',
                          'كم',
                          Icons.speed,
                          const Color(0xFF1E88E5),
                        ),
                        Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                        _buildStatItem(
                          'سعة الخزان',
                          '${car.tankCapacity.toStringAsFixed(0)}',
                          'لتر',
                          Icons.local_gas_station,
                          const Color(0xFFFB8C00),
                        ),
                        Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                        _buildStatItem(
                          'فترة الزيت',
                          '${car.oilChangeInterval.toStringAsFixed(0)}',
                          'كم',
                          Icons.oil_barrel,
                          const Color(0xFF43A047),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // زرار التعديل
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCarScreen(car: car),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E88E5).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                          const SizedBox(width: 8),
                          Text(
                            'تعديل بيانات السيارة',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // الإجراءات السريعة
                  Text(
                    'الإجراءات السريعة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.local_gas_station,
                        label: 'تسجيل وقود',
                        color: const Color(0xFF1E88E5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFuelScreen(car: car),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.miscellaneous_services,
                        label: 'تسجيل خدمة',
                        color: const Color(0xFF43A047),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddServiceScreen(car: car),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.bar_chart,
                        label: 'التقارير',
                        color: const Color(0xFFE53935),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportsScreen(car: car),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.history,
                        label: 'السجلات',
                        color: const Color(0xFFFB8C00),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogsScreen(car: car),
                          ),
                        ),
                      ),
                      // ✅ كارت الخريطة الجديد
                      _buildActionCard(
                        context,
                        icon: Icons.map,
                        label: 'خريطة قريبة',
                        color: const Color(0xFF00897B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.location_searching,
                        label: 'تتبع العداد بالخلفية',
                        color: const Color(0xFF1E88E5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OdometerUpdateScreen(car: car),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}