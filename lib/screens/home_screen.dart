import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/background_tracking_service.dart';
import '../services/reminder_service.dart';
import '../services/sms_service.dart';
import 'login_screen.dart';
import 'add_car_screen.dart';
import 'join_car_screen.dart';
import 'settings_screen.dart';
import 'fuel_sms_confirmation_screen.dart';
import '../widgets/car_tracking_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  final CarService carService = CarService();
  final BackgroundTrackingService _bgService = BackgroundTrackingService();
  late final Stream<List<CarWithRole>> _carsStream;


  late final VoidCallback _activeTrackingsListener;
  late final VoidCallback _backgroundEnabledListener;

  @override
  void initState() {
    super.initState();
    _bgService.init();
    _activeTrackingsListener = () => setState(() {});
    _backgroundEnabledListener = () => setState(() {});
    _bgService.activeTrackings.addListener(_activeTrackingsListener);
    _bgService.backgroundEnabled.addListener(_backgroundEnabledListener);
    _carsStream = carService.getUserCarsWithRole(authService.currentUser?.uid ?? '');
    final user = AuthService().currentUser;
    if (user != null) {
      ReminderService().runDailyCheck(user.uid);
      // فحص SMS بعد ثانيتين حتى تكتمل الشاشة
      Future.delayed(
          const Duration(seconds: 2), () => _checkForFuelSms(user.uid));
    }
  }

  Future<void> _checkForFuelSms(String uid) async {
    try {
      final results = await SmsService().checkNewFuelSms();
      if (results.isEmpty || !mounted) return;

      final carsWithRole = await carService.getUserCarsWithRole(uid).first;
      if (!mounted) return;
      final cars = carsWithRole.map((c) => c.car).toList();

      for (final sms in results) {
        if (!mounted) break;
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => FuelSmsConfirmationScreen(
              smsResult: sms,
              cars: cars,
            ),
          ),
        );
      }
    } catch (_) {
      // SMS غير مدعوم أو تم رفض الصلاحية — نتجاهل بصمت
    }
  }

  @override
  void dispose() {
    _bgService.activeTrackings.removeListener(_activeTrackingsListener);
    _bgService.backgroundEnabled.removeListener(_backgroundEnabledListener);
    _bgService.stopAllPassiveMonitors();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withAlpha(18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withAlpha(10),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await authService.logout();
                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginScreen()),
                                        (route) => false,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withAlpha(25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text('خروج',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white60,
                                                fontSize: 12)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.logout_rounded,
                                            color: Colors.white60, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'أهلاً بيك 👋',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      user?.displayName ??
                                          user?.email?.split('@')[0] ??
                                          'مستخدم',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 20,
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
                  ],
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Text(
                  'سياراتي',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          StreamBuilder<List<CarWithRole>>(
            stream: _carsStream,
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
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withAlpha(80),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'لا توجد سيارات بعد',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط + لإضافة سيارتك الأولى',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AddCarScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(
                                    'إضافة سيارة',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const JoinCarScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.vpn_key_rounded),
                                  label: Text(
                                    'الانضمام بكود دعوة',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                      final carWithRole = cars[index];
                      return CarCard(
                        car: carWithRole.car,
                        bgService: _bgService,
                        role: carWithRole.role,
                      );
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
        onPressed: () => _showAddOptions(context),
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text('إضافة سيارة',
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF1E88E5)),
                ),
                title: Text('إضافة سيارة جديدة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('أضف سيارتك الخاصة',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddCarScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key, color: Color(0xFF43A047)),
                ),
                title: Text('انضم لسيارة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('ادخل كود الدعوة من المالك',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const JoinCarScreen()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}