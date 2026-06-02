import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../models/car_model.dart';
import 'add_car_screen.dart';
import 'odometer_update_screen.dart';
import '../services/background_tracking_service.dart';
import 'car_details_screen.dart';
import 'settings_screen.dart';
import 'car_dashboard_screen.dart';
import 'car_location_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  final CarService carService = CarService();
  final BackgroundTrackingService _bgService = BackgroundTrackingService();

  @override
  void initState() {
    super.initState();
    _bgService.init();
    _bgService.activeTrackings.addListener(() => setState(() {}));
    _bgService.backgroundEnabled.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bgService.activeTrackings.removeListener(() {});
    _bgService.backgroundEnabled.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            actions: [
  IconButton(
    icon: const Icon(Icons.settings, color: Colors.white),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.logout,
                                  color: Colors.white70),
                              onPressed: () => authService.logout(),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'مرحباً 👋',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
              'مساعد السيارة الذكي 🚗',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          StreamBuilder<List<CarModel>>(
            stream: carService.getUserCars(user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final cars = snapshot.data ?? [];

              if (cars.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 60,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'مفيش سيارات لسه!',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط + عشان تضيف سيارتك الأولى',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final car = cars[index];
                      return _CarCard(car: car, bgService: _bgService);
                    },
                    childCount: cars.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCarScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1E88E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة سيارة',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final CarModel car;
  final BackgroundTrackingService bgService;

  const _CarCard({required this.car, required this.bgService});

  @override
  Widget build(BuildContext context) {
    double kmDriven = car.currentOdometer - car.lastOilChangeOdometer;
double kmToNextOil = car.oilChangeInterval - kmDriven;
bool oilSoon = kmToNextOil <= 500;

    return GestureDetector(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CarDashboardScreen(car: car),
    ),
  );
},
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car.licensePlate,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
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
                        '${car.year}',
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (oilSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'تغيير الزيت قريب!',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'الزيت تمام',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${car.currentOdometer} كم',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarLocationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: Text(
                    'أين عربيتي؟',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: bgService.activeTrackings,
                  builder: (context, active, _) {
                    final isTracking = active.contains(car.carId);
                    return ElevatedButton.icon(
                      onPressed: () async {
                        if (!isTracking) {
                          try {
                            await bgService.startTracking(car);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('بدأ تتبع السيارة بالخلفية', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF43A047),
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تعذر بدء التتبع: $e', style: GoogleFonts.cairo()),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        } else {
                          final res = await bgService.stopTracking(car.carId);
                          if (context.mounted) {
                            if (res != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم حساب ${res.distanceKm.toStringAsFixed(1)} كم', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF43A047),
                                action: SnackBarAction(
                                  label: 'فتح',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => OdometerUpdateScreen(car: car, initialOdometer: res.suggestedOdometer),
                                      ),
                                    );
                                  },
                                ),
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم إيقاف التتبع', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF43A047),
                              ));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(isTracking ? Icons.stop : Icons.location_searching),
                      label: Text(
                        isTracking ? 'إيقاف التتبع' : 'تشغيل تتبع العداد',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
}