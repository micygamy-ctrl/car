import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_item_service.dart';
import '../services/car_part_service.dart';
import '../models/car_model.dart';
import '../models/car_part_model.dart';
import '../models/maintenance_item_model.dart';

// ═══════════════════════════════════════════════════════
//  موديلات السيارات حسب الماركة
// ═══════════════════════════════════════════════════════
const Map<String, List<String>> _carModels = {
  'Toyota': ['Corolla','Camry','Yaris','Land Cruiser','Prado','Hilux','RAV4','C-HR','Fortuner','Avalon','Crown','Rush','Innova','Prius','Highlander','Sequoia','Tundra','Tacoma','4Runner','Vios','Avanza','Veloz'],
  'Honda': ['Civic','Accord','CR-V','HR-V','Pilot','Jazz','City','BR-V','Passport','Ridgeline','Odyssey','Fit','Insight','ZR-V'],
  'Nissan': ['Sunny','Sentra','Altima','Maxima','Patrol','Pathfinder','X-Trail','Juke','Murano','Navara','Tiida','Kicks','Terra','Qashqai','370Z','GT-R'],
  'Mazda': ['Mazda2','Mazda3','Mazda6','CX-3','CX-30','CX-5','CX-60','CX-9','MX-5','BT-50'],
  'Mitsubishi': ['Lancer','Galant','Eclipse Cross','Outlander','ASX','Pajero','L200','Mirage','Attrage','Xpander','Eclipse'],
  'BMW': ['Series 1','Series 2','Series 3','Series 4','Series 5','Series 7','X1','X2','X3','X4','X5','X6','X7','Z4','M3','M5','iX','i4','i7'],
  'Mercedes-Benz': ['A-Class','B-Class','C-Class','E-Class','S-Class','GLA','GLB','GLC','GLE','GLS','G-Class','CLA','CLS','EQA','EQB','EQC','EQS'],
  'Audi': ['A1','A3','A4','A5','A6','A7','A8','Q2','Q3','Q5','Q7','Q8','TT','R8','e-tron'],
  'Volkswagen': ['Golf','Polo','Passat','Tiguan','Touareg','T-Roc','T-Cross','Arteon','ID.4','ID.3','Caddy','Transporter'],
  'Opel': ['Astra','Corsa','Insignia','Mokka','Crossland','Grandland','Vectra','Zafira'],
  'Ford': ['Fiesta','Focus','Mondeo','Mustang','Explorer','Expedition','F-150','Ranger','Edge','Escape','Bronco','EcoSport','Puma','Kuga','Territory'],
  'Chevrolet': ['Spark','Aveo','Cruze','Malibu','Camaro','Corvette','Equinox','Trax','Blazer','Traverse','Tahoe','Suburban','Silverado','Colorado','Captiva','Trailblazer'],
  'GMC': ['Sierra','Canyon','Terrain','Acadia','Yukon','Envoy','Jimmy'],
  'Jeep': ['Wrangler','Grand Cherokee','Cherokee','Compass','Renegade','Gladiator','Commander'],
  'Hyundai': ['Accent','Elantra','Sonata','Tucson','Santa Fe','Creta','Venue','i10','i20','i30','Kona','Palisade','Ioniq','Ioniq 5','Ioniq 6','Azera','Veloster','Verna'],
  'Kia': ['Picanto','Rio','Cerato','K5','Sportage','Sorento','Stinger','Telluride','Sonet','Seltos','Carnival','EV6','Niro'],
  'Peugeot': ['208','308','508','2008','3008','5008','Partner','Expert','Boxer','408','107','206','207','307'],
  'Renault': ['Clio','Megane','Laguna','Duster','Kadjar','Koleos','Captur','Zoe','Talisman','Symbol','Logan','Sandero','Arkana'],
  'Citroën': ['C3','C4','C5','Berlingo','Jumpy','C-Elysée','C3 Aircross','C5 Aircross'],
  'Porsche': ['911','Cayenne','Macan','Panamera','Taycan','718'],
  'Jaguar': ['XE','XF','XJ','F-Pace','E-Pace','I-Pace','F-Type'],
  'Land Rover': ['Defender','Discovery','Discovery Sport','Range Rover','Range Rover Sport','Range Rover Evoque','Range Rover Velar','Freelander'],
  'Volvo': ['S60','S90','V60','V90','XC40','XC60','XC90','C40'],
  'Subaru': ['Impreza','Legacy','Outback','Forester','XV','BRZ','WRX','Crosstrek','Ascent'],
  'Suzuki': ['Swift','Baleno','Ciaz','Vitara','S-Cross','Jimny','Ertiga','Carry','Alto'],
  'Lexus': ['IS','ES','GS','LS','UX','NX','RX','GX','LX','LC','RC'],
  'Infiniti': ['Q50','Q60','QX50','QX55','QX60','QX80'],
  'Acura': ['ILX','TLX','RDX','MDX','NSX'],
  'Dodge': ['Charger','Challenger','Durango','Journey','RAM 1500','Grand Caravan'],
  'BYD': ['Atto 3','Han','Tang','Song','Seal','Dolphin','F3','G6','Yuan Plus'],
  'MG': ['MG3','MG5','MG6','ZS','HS','RX5','RX8','VS','Extender','MG4','Cyberster'],
  'Chery': ['Tiggo 4','Tiggo 7','Tiggo 8','Arrizo 5','Arrizo 6','Omoda 5'],
  'Geely': ['Emgrand','Atlas','Coolray','Tugella','Okavango','Preface','Azkarra'],
  'Haval': ['H2','H4','H6','H9','Jolion','Dargo','Big Dog','F7'],
  'Changan': ['Alsvin','CS35','CS55','CS75','CS85','Uni-T','Uni-K','Lamore'],
  'GAC': ['GS3','GS4','GS5','GS8','GA4','GA6','Emzoom','Empow'],
  'Tesla': ['Model 3','Model S','Model X','Model Y','Cybertruck','Roadster'],
  'Fiat': ['500','Punto','Tipo','Bravo','Doblo','Ducato','Panda','Toro'],
  'Alfa Romeo': ['Giulia','Stelvio','Tonale','Giulietta','156','159'],
  'Skoda': ['Octavia','Superb','Fabia','Scala','Karoq','Kodiaq','Enyaq'],
  'Isuzu': ['D-Max','MU-X','Trooper','NPR','NQR'],
  'أخرى': [],
};

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
  final CarPartService _carPartService = CarPartService();

  final _customMakeController = TextEditingController();
  final _customModelController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _tankCapacityController = TextEditingController();
  final _oilIntervalController = TextEditingController();
  final _engineCcController = TextEditingController();

  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String _selectedFuelType = 'petrol';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _parts = [
    {'title': 'زيت المحرك', 'category': 'maintenance', 'icon': Icons.oil_barrel, 'color': const Color(0xFFFB8C00), 'kmController': TextEditingController(text: '5000'), 'daysController': TextEditingController(text: '180'), 'enabled': true},
    {'title': 'فلتر الهواء', 'category': 'maintenance', 'icon': Icons.air, 'color': const Color(0xFF1E88E5), 'kmController': TextEditingController(text: '15000'), 'daysController': TextEditingController(text: '365'), 'enabled': true},
    {'title': 'الكاوتش', 'category': 'maintenance', 'icon': Icons.tire_repair, 'color': const Color(0xFF43A047), 'kmController': TextEditingController(text: '40000'), 'daysController': TextEditingController(text: ''), 'enabled': true},
    {'title': 'سيور التوقيت', 'category': 'maintenance', 'icon': Icons.settings, 'color': const Color(0xFF8E24AA), 'kmController': TextEditingController(text: '60000'), 'daysController': TextEditingController(text: ''), 'enabled': true},
    {'title': 'الفرامل', 'category': 'maintenance', 'icon': Icons.dangerous, 'color': const Color(0xFFE53935), 'kmController': TextEditingController(text: '30000'), 'daysController': TextEditingController(text: ''), 'enabled': true},
    {'title': 'البطارية', 'category': 'maintenance', 'icon': Icons.battery_charging_full, 'color': const Color(0xFF00ACC1), 'kmController': TextEditingController(text: ''), 'daysController': TextEditingController(text: '730'), 'enabled': true},
    {'title': 'فلتر الوقود', 'category': 'maintenance', 'icon': Icons.local_gas_station, 'color': const Color(0xFFD81B60), 'kmController': TextEditingController(text: '20000'), 'daysController': TextEditingController(text: ''), 'enabled': true},
    {'title': 'سائل التبريد', 'category': 'maintenance', 'icon': Icons.water_drop, 'color': const Color(0xFF0288D1), 'kmController': TextEditingController(text: '40000'), 'daysController': TextEditingController(text: '730'), 'enabled': true},
  ];

  final List<String> _carMakes = [
    'Toyota','Honda','Nissan','Mazda','Mitsubishi',
    'BMW','Mercedes-Benz','Audi','Volkswagen','Opel',
    'Ford','Chevrolet','Cadillac','GMC','Jeep',
    'Hyundai','Kia','Genesis',
    'Peugeot','Renault','Citroën',
    'Tesla','Lucid','Rivian',
    'Porsche','Ferrari','Lamborghini','Maserati',
    'Bentley','Rolls-Royce','Aston Martin','McLaren',
    'Jaguar','Land Rover','Mini',
    'Fiat','Alfa Romeo',
    'Volvo','Polestar',
    'Suzuki','Subaru','Lexus','Infiniti','Acura',
    'Dodge','Chrysler','Lincoln','Buick',
    'BYD','MG','Chery','Geely','Haval',
    'Changan','Exeed','Jetour','GAC',
    'NIO','XPeng','Zeekr','Wuling',
    'Skoda','SEAT','Cupra',
    'Isuzu','Daewoo','Lada','Proton',
    'Mahindra','Tata','VinFast',
    'Lotus','Maybach','Hummer',
    'أخرى',
  ];

  final List<Map<String, dynamic>> _fuelTypes = [
    {'value': 'petrol', 'label': 'بنزين', 'icon': Icons.local_gas_station},
    {'value': 'diesel', 'label': 'ديزل', 'icon': Icons.oil_barrel},
    {'value': 'hybrid', 'label': 'هايبريد', 'icon': Icons.electric_bolt},
    {'value': 'electric', 'label': 'كهرباء', 'icon': Icons.electric_car},
  ];

  List<String> get _modelsForMake {
    if (_selectedMake == null) return [];
    return _carModels[_selectedMake] ?? [];
  }

  @override
  void dispose() {
    _customMakeController.dispose();
    _customModelController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _tankCapacityController.dispose();
    _oilIntervalController.dispose();
    _engineCcController.dispose();
    for (final part in _parts) {
      (part['kmController'] as TextEditingController).dispose();
      (part['daysController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // ── Year Picker ──────────────────────────────────────
  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    int tempYear = _selectedYear ?? now;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setBS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedYear = tempYear);
                        Navigator.pop(ctx);
                      },
                      child: Text('تأكيد',
                          style: GoogleFonts.cairo(
                              color: const Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    Text('اختر سنة الصنع',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('إلغاء',
                          style: GoogleFonts.cairo(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 220,
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                      initialItem: now - tempYear),
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) =>
                      setBS(() => tempYear = now - i),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: now - 1970 + 1,
                    builder: (context, i) {
                      final year = now - i;
                      final isSelected = year == tempYear;
                      return Center(
                        child: Text(
                          '$year',
                          style: GoogleFonts.cairo(
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1E88E5)
                                : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('من فضلك اختار سنة الصنع', style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final carId = _carService.generateId();
      final make = _selectedMake == 'أخرى'
          ? _customMakeController.text.trim()
          : (_selectedMake ?? '');

      final model = (_selectedMake == 'أخرى' || _modelsForMake.isEmpty)
          ? _customModelController.text.trim()
          : (_selectedModel ?? _customModelController.text.trim());

      final odometer = double.parse(_odometerController.text.trim());

      final car = CarModel(
        carId: carId,
        ownerId: _authService.currentUser!.uid,
        make: make,
        model: model,
        year: _selectedYear!,
        licensePlate: _plateController.text.trim(),
        currentOdometer: odometer,
        fuelType: _selectedFuelType,
        tankCapacity: double.parse(_tankCapacityController.text.trim()),
        oilChangeInterval: double.parse(_oilIntervalController.text.trim()),
        lastOilChangeOdometer: odometer,
        engineCc: int.tryParse(_engineCcController.text.trim()),
      );

      await _carService.addCar(car);

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

        final partTitle = part['title'] as String;
        final carPart = CarPartModel(
          partId: '${carId}_${partTitle.trim().replaceAll(' ', '_')}',
          carId: carId,
          name: partTitle,
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
        await _carPartService.upsertPart(carPart);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تمت إضافة السيارة بنجاح! 🚗', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
                        Text('إضافة سيارة جديدة 🚗',
                            style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('أدخل بيانات سيارتك وقطعها',
                            style: GoogleFonts.cairo(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text('إضافة سيارة',
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ─── بيانات السيارة ───────────────────────
                    _buildCard(
                      title: 'بيانات السيارة',
                      icon: Icons.directions_car,
                      color: const Color(0xFF1E88E5),
                      children: [
                        // الماركة
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownSearch<String>(
                            items: _carMakes,
                            selectedItem: _selectedMake,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: _inputDeco(
                                  'الماركة', Icons.branding_watermark),
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
                              itemBuilder: (ctx, item, isSelected) => ListTile(
                                title: Text(item, style: GoogleFonts.cairo()),
                                selected: isSelected,
                                selectedTileColor:
                                    const Color(0xFF1E88E5).withOpacity(0.1),
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
                                _selectedModel = null;
                                _customModelController.clear();
                                if (value != 'أخرى') {
                                  _customMakeController.clear();
                                }
                              });
                            },
                            validator: (v) =>
                                v == null ? 'من فضلك اختار الماركة' : null,
                          ),
                        ),

                        // لو الماركة "أخرى" → اكتب الماركة
                        if (_selectedMake == 'أخرى')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _customMakeController,
                              textAlign: TextAlign.right,
                              decoration: _inputDeco(
                                  'اكتب اسم الماركة', Icons.edit),
                              validator: (v) =>
                                  _selectedMake == 'أخرى' && (v == null || v.isEmpty)
                                      ? 'من فضلك اكتب اسم الماركة'
                                      : null,
                            ),
                          ),

                        // الموديل — dropdown لو الماركة معروفة
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _selectedMake != null &&
                                  _selectedMake != 'أخرى' &&
                                  _modelsForMake.isNotEmpty
                              ? _buildModelDropdown()
                              : TextFormField(
                                  controller: _customModelController,
                                  textAlign: TextAlign.right,
                                  decoration: _inputDeco(
                                      'الموديل', Icons.car_repair,
                                      hint: 'مثال: Corolla'),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'من فضلك أدخل الموديل'
                                      : null,
                                ),
                        ),

                        // سنة الصنع — year picker
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: _pickYear,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.arrow_drop_down,
                                      color: _selectedYear == null
                                          ? Colors.grey
                                          : const Color(0xFF1E88E5)),
                                  Row(
                                    children: [
                                      Text(
                                        _selectedYear == null
                                            ? 'اختر سنة الصنع'
                                            : '$_selectedYear',
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          color: _selectedYear == null
                                              ? Colors.grey
                                              : Colors.black87,
                                          fontWeight: _selectedYear == null
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF1E88E5), size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // رقم اللوحة
                        _buildTextField(
                          controller: _plateController,
                          label: 'رقم اللوحة',
                          hint: 'مثال: أ ب ج 1234',
                          icon: Icons.pin,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل رقم اللوحة' : null,
                        ),

                        // سعة المحرك (cc)
                        _buildTextField(
                          controller: _engineCcController,
                          label: 'سعة المحرك (cc)',
                          hint: 'مثال: 1600',
                          icon: Icons.engineering,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── نوع الوقود ───────────────────────────
                    _buildFuelTypeCard(),
                    const SizedBox(height: 16),

                    // ─── العداد والوقود ───────────────────────
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
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل قراءة العداد' : null,
                        ),
                        _buildTextField(
                          controller: _tankCapacityController,
                          label: 'سعة الخزان (لتر)',
                          hint: 'مثال: 55',
                          icon: Icons.local_gas_station,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل سعة الخزان' : null,
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

                    // ─── قطع السيارة ──────────────────────────
                    _buildPartsCard(),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('حفظ السيارة وقطعها 🚗',
                                style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
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

  // ── Model Dropdown ────────────────────────────────────
  Widget _buildModelDropdown() {
    return DropdownSearch<String>(
      items: _modelsForMake,
      selectedItem: _selectedModel,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration:
            _inputDeco('الموديل', Icons.car_repair),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'ابحث عن الموديل...',
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
        itemBuilder: (ctx, item, isSelected) => ListTile(
          title: Text(item, style: GoogleFonts.cairo()),
          selected: isSelected,
          selectedTileColor: const Color(0xFF1E88E5).withOpacity(0.1),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xFF1E88E5))
              : null,
        ),
        constraints: const BoxConstraints(maxHeight: 300),
      ),
      onChanged: (value) => setState(() => _selectedModel = value),
      validator: (v) => v == null ? 'من فضلك اختار الموديل' : null,
    );
  }

  // ── Fuel Type Card ────────────────────────────────────
  Widget _buildFuelTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('نوع الوقود',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5))),
            const SizedBox(width: 8),
            const Icon(Icons.local_gas_station,
                color: Color(0xFF1E88E5), size: 20),
          ]),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _fuelTypes.map((fuel) {
              final isSelected = _selectedFuelType == fuel['value'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedFuelType = fuel['value']),
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
                  child: Column(children: [
                    Icon(fuel['icon'] as IconData,
                        color:
                            isSelected ? Colors.white : Colors.grey,
                        size: 24),
                    const SizedBox(height: 4),
                    Text(fuel['label'],
                        style: GoogleFonts.cairo(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Parts Card ────────────────────────────────────────
  Widget _buildPartsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('قطع السيارة والتذكيرات 🔧',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E24AA))),
            const SizedBox(width: 8),
            const Icon(Icons.build_circle,
                color: Color(0xFF8E24AA), size: 20),
          ]),
          const SizedBox(height: 4),
          Text('حدد فترة تغيير كل قطعة بالكيلو أو بالأيام',
              style:
                  GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right),
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
                        : Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Switch(
                          value: enabled,
                          onChanged: (v) => setState(
                              () => _parts[index]['enabled'] = v),
                          activeColor: color),
                      Row(children: [
                        Text(part['title'] as String,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: enabled ? color : Colors.grey)),
                        const SizedBox(width: 8),
                        Icon(part['icon'] as IconData,
                            color: enabled ? color : Colors.grey,
                            size: 18),
                      ]),
                    ],
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: part['daysController']
                              as TextEditingController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'يوم',
                            labelStyle:
                                GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('أو',
                          style: GoogleFonts.cairo(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller:
                              part['kmController'] as TextEditingController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'كيلو',
                            labelStyle:
                                GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.cairo(),
      prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1E88E5), width: 2)),
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
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 20),
          ]),
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
        decoration: _inputDeco(label, icon, hint: hint),
        validator: validator,
      ),
    );
  }
}
