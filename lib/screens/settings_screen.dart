import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  String _selectedCurrency = 'EGP';
  String _selectedDistanceUnit = 'km';
  String _selectedFuelUnit = 'L';
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  final List<Map<String, String>> _currencies = [
    {'value': 'EGP', 'label': 'جنيه مصري (ج.م)'},
    {'value': 'SAR', 'label': 'ريال سعودي (ر.س)'},
    {'value': 'AED', 'label': 'درهم إماراتي (د.إ)'},
    {'value': 'USD', 'label': 'دولار أمريكي (\$)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'EGP';
      _selectedDistanceUnit = prefs.getString('distanceUnit') ?? 'km';
      _selectedFuelUnit = prefs.getString('fuelUnit') ?? 'L';
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('distanceUnit', _selectedDistanceUnit);
    await prefs.setString('fuelUnit', _selectedFuelUnit);
    await prefs.setBool('notifications', _notificationsEnabled);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الإعدادات! ✅', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            iconTheme: const IconThemeData(color: Colors.white),
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
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'الإعدادات ⚙️',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'تخصيص التطبيق حسب تفضيلاتك',
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
              'الإعدادات',
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
                  // معلومات الحساب
                  _buildCard(
                    title: 'معلومات الحساب',
                    icon: Icons.person,
                    color: const Color(0xFF1E88E5),
                    children: [
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'البريد الإلكتروني',
                        value: _authService.currentUser?.email ?? '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // إعدادات العملة
                  _buildCard(
                    title: 'العملة',
                    icon: Icons.attach_money,
                    color: const Color(0xFF43A047),
                    children: [
                      ..._currencies.map((currency) => _buildRadioOption(
                            label: currency['label']!,
                            value: currency['value']!,
                            groupValue: _selectedCurrency,
                            onChanged: (v) =>
                                setState(() => _selectedCurrency = v!),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // وحدات القياس
                  _buildCard(
                    title: 'وحدات القياس',
                    icon: Icons.straighten,
                    color: const Color(0xFFFB8C00),
                    children: [
                      Text(
                        'وحدة المسافة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildChipOption(
                            label: 'ميل',
                            value: 'mi',
                            groupValue: _selectedDistanceUnit,
                            onTap: () =>
                                setState(() => _selectedDistanceUnit = 'mi'),
                            color: const Color(0xFFFB8C00),
                          ),
                          const SizedBox(width: 8),
                          _buildChipOption(
                            label: 'كيلومتر',
                            value: 'km',
                            groupValue: _selectedDistanceUnit,
                            onTap: () =>
                                setState(() => _selectedDistanceUnit = 'km'),
                            color: const Color(0xFFFB8C00),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'وحدة الوقود',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildChipOption(
                            label: 'جالون',
                            value: 'gal',
                            groupValue: _selectedFuelUnit,
                            onTap: () =>
                                setState(() => _selectedFuelUnit = 'gal'),
                            color: const Color(0xFFFB8C00),
                          ),
                          const SizedBox(width: 8),
                          _buildChipOption(
                            label: 'لتر',
                            value: 'L',
                            groupValue: _selectedFuelUnit,
                            onTap: () =>
                                setState(() => _selectedFuelUnit = 'L'),
                            color: const Color(0xFFFB8C00),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // الإشعارات
                  _buildCard(
                    title: 'الإشعارات',
                    icon: Icons.notifications,
                    color: const Color(0xFFE53935),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Switch(
                            value: _notificationsEnabled,
                            onChanged: (v) =>
                                setState(() => _notificationsEnabled = v),
                            activeColor: const Color(0xFFE53935),
                          ),
                          Text(
                            'تفعيل الإشعارات',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // تسجيل الخروج
                  _buildCard(
                    title: 'الحساب',
                    icon: Icons.manage_accounts,
                    color: Colors.red,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text('تسجيل الخروج',
                                  style: GoogleFonts.cairo()),
                              content: Text(
                                'هل أنت متأكد من تسجيل الخروج؟',
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
                                      style:
                                          GoogleFonts.cairo(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _authService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'تسجيل الخروج',
                                style: GoogleFonts.cairo(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // زرار الحفظ
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ الإعدادات ✅',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
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
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(label, style: GoogleFonts.cairo(color: Colors.grey)),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required void Function(String?) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.cairo()),
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: const Color(0xFF43A047),
        ),
      ],
    );
  }

  Widget _buildChipOption({
    required String label,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
