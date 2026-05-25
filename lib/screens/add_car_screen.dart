import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../models/car_model.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();
  final AuthService _authService = AuthService();

  final _makeController = TextEditingController();
  final _customMakeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _tankCapacityController = TextEditingController();
  final _oilIntervalController = TextEditingController();

  String? _selectedMake;
  String _selectedFuelType = 'petrol';
  bool _isLoading = false;

  final List<String> _carMakes = [
    'Toyota', 'Honda', 'Nissan', 'Mazda', 'Mitsubishi',
    'BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen', 'Opel',
    'Ford', 'Chevrolet', 'Cadillac', 'GMC', 'Jeep',
    'Hyundai', 'Kia', 'Genesis',
    'Peugeot', 'Renault', 'Citroën',
    'Tesla', 'Lucid', 'Rivian',
    'Porsche', 'Ferrari', 'Lamborghini', 'Maserati',
    'Bentley', 'Rolls-Royce', 'Aston Martin', 'McLaren',
    'Jaguar', 'Land Rover', 'Mini',
    'Fiat', 'Alfa Romeo',
    'Volvo', 'Polestar',
    'Suzuki', 'Subaru', 'Lexus', 'Infiniti', 'Acura',
    'Dodge', 'Chrysler', 'Lincoln', 'Buick',
    'BYD', 'MG', 'Chery', 'Geely', 'Haval',
    'Changan', 'Exeed', 'Jetour', 'GAC',
    'NIO', 'XPeng', 'Zeekr', 'Wuling',
    'Skoda', 'SEAT', 'Cupra',
    'Isuzu', 'Daewoo', 'Lada', 'Proton',
    'Mahindra', 'Tata', 'VinFast',
    'Lotus', 'Maybach', 'Hummer',
    'other',
  ];

  final List<Map<String, dynamic>> _fuelTypes = [
    {'value': 'petrol', 'label': 'بنزين', 'icon': Icons.local_gas_station},
    {'value': 'diesel', 'label': 'ديزل', 'icon': Icons.oil_barrel},
    {'value': 'hybrid', 'label': 'هايبريد', 'icon': Icons.electric_bolt},
    {'value': 'electric', 'label': 'كهرباء', 'icon': Icons.electric_car},
  ];

  @override
  void dispose() {
    _makeController.dispose();
    _customMakeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _tankCapacityController.dispose();
    _oilIntervalController.dispose();
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final carId = _carService.generateId();
      final make = _selectedMake == 'other'
          ? _customMakeController.text.trim()
          : _makeController.text.trim();

      final car = CarModel(
        carId: carId,
        ownerId: _authService.currentUser!.uid,
        make: make,
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        licensePlate: _plateController.text.trim(),
        currentOdometer: double.parse(_odometerController.text.trim()),
        fuelType: _selectedFuelType,
        tankCapacity: double.parse(_tankCapacityController.text.trim()),
        oilChangeInterval: double.parse(_oilIntervalController.text.trim()),
        lastOilChangeOdometer: double.parse(_odometerController.text.trim()),
      );

      await _carService.addCar(car);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة السيارة بنجاح! 🚗',
                style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                          'إضافة سيارة جديدة 🚗',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'أدخل بيانات سيارتك',
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
              'إضافة سيارة',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCard(
                      title: 'بيانات السيارة',
                      icon: Icons.directions_car,
                      color: const Color(0xFF1E88E5),
                      children: [
                        // Dropdown الماركة مع Search
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownSearch<String>(
                            items: _carMakes,
                            selectedItem: _selectedMake,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'الماركة',
                                labelStyle: GoogleFonts.cairo(),
                                prefixIcon: const Icon(
                                    Icons.branding_watermark,
                                    color: Color(0xFF1E88E5)),
                                filled: true,
                                fillColor: const Color(0xFFF5F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E88E5), width: 2),
                                ),
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن الماركة...',
                                  hintStyle: GoogleFonts.cairo(),
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: GoogleFonts.cairo(),
                              ),
                              itemBuilder: (context, item, isSelected) =>
                                  ListTile(
                                title: Text(item, style: GoogleFonts.cairo()),
                                selected: isSelected,
                                selectedTileColor: const Color(0xFF1E88E5)
                                    .withOpacity(0.1),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: Color(0xFF1E88E5))
                                    : null,
                              ),
                              constraints: const BoxConstraints(
                                maxHeight: 300,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedMake = value;
                                _makeController.text = value ?? '';
                                if (value != 'other') {
                                  _customMakeController.text = '';
                                }
                              });
                            },
                            validator: (v) => v == null
                                ? 'من فضلك اختار الماركة'
                                : null,
                          ),
                        ),

                        // خانة الماركة المخصصة لو اختار "other"
                        if (_selectedMake == 'other')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _customMakeController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'اكتب اسم الماركة',
                                hintText: 'مثال: Dacia',
                                labelStyle: GoogleFonts.cairo(),
                                prefixIcon: const Icon(Icons.edit,
                                    color: Color(0xFF1E88E5)),
                                filled: true,
                                fillColor: const Color(0xFFF5F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E88E5), width: 2),
                                ),
                              ),
                              validator: (v) {
                                if (_selectedMake == 'other' &&
                                    (v == null || v.isEmpty)) {
                                  return 'من فضلك اكتب اسم الماركة';
                                }
                                return null;
                              },
                            ),
                          ),

                        _buildTextField(
                          controller: _modelController,
                          label: 'الموديل',
                          hint: 'مثال: Corolla',
                          icon: Icons.car_repair,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل الموديل' : null,
                        ),
                        _buildTextField(
                          controller: _yearController,
                          label: 'سنة الصنع',
                          hint: 'مثال: 2022',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل سنة الصنع' : null,
                        ),
                        _buildTextField(
                          controller: _plateController,
                          label: 'رقم اللوحة',
                          hint: 'مثال: أ ب ج 1234',
                          icon: Icons.pin,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل رقم اللوحة' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // نوع الوقود
                    Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'نوع الوقود',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.local_gas_station,
                                  color: Color(0xFF1E88E5), size: 20),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _fuelTypes.map((fuel) {
                              final isSelected =
                                  _selectedFuelType == fuel['value'];
                              return GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedFuelType = fuel['value']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1E88E5)
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: const Color(0xFF1E88E5)
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4))
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        fuel['icon'] as IconData,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fuel['label'],
                                        style: GoogleFonts.cairo(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      title: 'بيانات العداد والوقود',
                      icon: Icons.speed,
                      color: const Color(0xFF43A047),
                      children: [
                        _buildTextField(
                          controller: _odometerController,
                          label: 'قراءة العداد الحالية (كم)',
                          hint: 'مثال: 45000',
                          icon: Icons.speed,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty
                              ? 'من فضلك أدخل قراءة العداد'
                              : null,
                        ),
                        _buildTextField(
                          controller: _tankCapacityController,
                          label: 'سعة الخزان (لتر)',
                          hint: 'مثال: 55',
                          icon: Icons.local_gas_station,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty
                              ? 'من فضلك أدخل سعة الخزان'
                              : null,
                        ),
                        _buildTextField(
                          controller: _oilIntervalController,
                          label: 'فترة تغيير الزيت (كم)',
                          hint: 'مثال: 5000',
                          icon: Icons.oil_barrel,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty
                              ? 'من فضلك أدخل فترة تغيير الزيت'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'حفظ السيارة 🚗',
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
            color: Colors.black.withOpacity(0.06),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}