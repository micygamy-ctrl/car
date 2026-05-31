import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_item_service.dart';
import '../models/car_model.dart';
import '../models/maintenance_item_model.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();
  final AuthService _authService = AuthService();
  final MaintenanceItemService _itemService = MaintenanceItemService();

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

  // القطع الافتراضية
  final List<Map<String, dynamic>> _parts = [
    {
      'title': 'زيت المحرك',
      'category': 'maintenance',
      'icon': Icons.oil_barrel,
      'color': const Color(0xFFFB8C00),
      'kmController': TextEditingController(text: '5000'),
      'daysController': TextEditingController(text: '180'),
      'enabled': true,
    },
    {
      'title': 'فلتر الهواء',
      'category': 'maintenance',
      'icon': Icons.air,
      'color': const Color(0xFF1E88E5),
      'kmController': TextEditingController(text: '15000'),
      'daysController': TextEditingController(text: '365'),
      'enabled': true,
    },
    {
      'title': 'الكاوتش',
      'category': 'maintenance',
      'icon': Icons.tire_repair,
      'color': const Color(0xFF43A047),
      'kmController': TextEditingController(text: '40000'),
      'daysController': TextEditingController(text: ''),
      'enabled': true,
    },
    {
      'title': 'سيور التوقيت',
      'category': 'maintenance',
      'icon': Icons.settings,
      'color': const Color(0xFF8E24AA),
      'kmController': TextEditingController(text: '60000'),
      'daysController': TextEditingController(text: ''),
      'enabled': true,
    },
    {
      'title': 'الفرامل',
      'category': 'maintenance',
      'icon': Icons.dangerous,
      'color': const Color(0xFFE53935),
      'kmController': TextEditingController(text: '30000'),
      'daysController': TextEditingController(text: ''),
      'enabled': true,
    },
    {
      'title': 'البطارية',
      'category': 'maintenance',
      'icon': Icons.battery_charging_full,
      'color': const Color(0xFF00ACC1),
      'kmController': TextEditingController(text: ''),
      'daysController': TextEditingController(text: '730'),
      'enabled': true,
    },
    {
      'title': 'فلتر الوقود',
      'category': 'maintenance',
      'icon': Icons.local_gas_station,
      'color': const Color(0xFFD81B60),
      'kmController': TextEditingController(text: '20000'),
      'daysController': TextEditingController(text: ''),
      'enabled': true,
    },
    {
      'title': 'سائل التبريد',
      'category': 'maintenance',
      'icon': Icons.water_drop,
      'color': const Color(0xFF0288D1),
      'kmController': TextEditingController(text: '40000'),
      'daysController': TextEditingController(text: '730'),
      'enabled': true,
    },
  ];

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
    'أخرى',
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
    for (final part in _parts) {
      (part['kmController'] as TextEditingController).dispose();
      (part['daysController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final carId = _carService.generateId();
      final make = _selectedMake == 'أخرى'
          ? _customMakeController.text.trim()
          : _makeController.text.trim();

      final odometer = double.parse(_odometerController.text.trim());

      final car = CarModel(
        carId: carId,
        ownerId: _authService.currentUser!.uid,
        make: make,
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        licensePlate: _plateController.text.trim(),
        currentOdometer: odometer,
        fuelType: _selectedFuelType,
        tankCapacity: double.parse(_tankCapacityController.text.trim()),
        oilChangeInterval: double.parse(_oilIntervalController.text.trim()),
        lastOilChangeOdometer: odometer,
      );

      await _carService.addCar(car);

      // حفظ القطع المفعّلة
      for (final part in _parts) {
        if (!(part['enabled'] as bool)) continue;

        final kmText = (part['kmController'] as TextEditingController).text.trim();
        final daysText = (part['daysController'] as TextEditingController).text.trim();
        final intervalKm = double.tryParse(kmText);
        final intervalDays = int.tryParse(daysText);

        if (intervalKm == null && intervalDays == null) continue;

        final itemId = _itemService.generateId();
        final nextDueOdometer = intervalKm != null ? odometer + intervalKm : null;
        final nextDueDate = intervalDays != null
            ? DateTime.now().add(Duration(days: intervalDays))
            : null;

        final item = MaintenanceItemModel(
          itemId: itemId,
          carId: carId,
          title: part['title'] as String,
          category: part['category'] as String,
          intervalKm: intervalKm,
          intervalDays: intervalDays,
          lastServiceOdometer: odometer,
          lastServiceDate: DateTime.now(),
          nextDueOdometer: nextDueOdometer,
          nextDueDate: nextDueDate,
          enabled: true,
          updatedAt: DateTime.now(),
        );

        await _itemService.addCustomItem(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة السيارة وقطعها بنجاح! 🚗',
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
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
                          'أدخل بيانات سيارتك وقطعها',
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
                    // بيانات السيارة
                    _buildCard(
                      title: 'بيانات السيارة',
                      icon: Icons.directions_car,
                      color: const Color(0xFF1E88E5),
                      children: [
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
                              constraints:
                                  const BoxConstraints(maxHeight: 300),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedMake = value;
                                _makeController.text = value ?? '';
                                if (value != 'أخرى') {
                                  _customMakeController.text = '';
                                }
                              });
                            },
                            validator: (v) => v == null
                                ? 'من فضلك اختار الماركة'
                                : null,
                          ),
                        ),
                        if (_selectedMake == 'أخرى')
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
                                if (_selectedMake == 'أخرى' &&
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

                    // بيانات العداد
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
                    const SizedBox(height: 16),

                    // قطع السيارة
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
                                'قطع السيارة والتذكيرات 🔧',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8E24AA),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.build_circle,
                                  color: Color(0xFF8E24AA), size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'حدد فترة تغيير كل قطعة بالكيلو أو بالأيام',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const Divider(height: 20),
                          ...List.generate(_parts.length, (index) {
                            final part = _parts[index];
                            final color = part['color'] as Color;
                            final enabled = part['enabled'] as bool;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: enabled
                                    ? color.withOpacity(0.05)
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: enabled
                                      ? color.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Switch(
                                        value: enabled,
                                        onChanged: (v) => setState(
                                            () => _parts[index]['enabled'] = v),
                                        activeColor: color,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            part['title'] as String,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: enabled
                                                  ? color
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            part['icon'] as IconData,
                                            color:
                                                enabled ? color : Colors.grey,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (enabled) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: part['daysController']
                                                as TextEditingController,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            style: GoogleFonts.cairo(
                                                fontSize: 13),
                                            decoration: InputDecoration(
                                              labelText: 'يوم',
                                              labelStyle: GoogleFonts.cairo(
                                                  fontSize: 12),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('أو',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: part['kmController']
                                                as TextEditingController,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            style: GoogleFonts.cairo(
                                                fontSize: 13),
                                            decoration: InputDecoration(
                                              labelText: 'كيلو',
                                              labelStyle: GoogleFonts.cairo(
                                                  fontSize: 12),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
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
                                'حفظ السيارة وقطعها 🚗',
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