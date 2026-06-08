import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/maintenance_service.dart';
import '../services/maintenance_item_service.dart';
import '../services/car_service.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';
import '../services/car_part_service.dart';

class _MaintenanceTemplate {
  final String title;
  final IconData icon;
  final int intervalKm;
  final int intervalDays;

  const _MaintenanceTemplate({
    required this.title,
    required this.icon,
    required this.intervalKm,
    required this.intervalDays,
  });
}

class AddServiceScreen extends StatefulWidget {
  final CarModel car;

  const AddServiceScreen({super.key, required this.car});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaintenanceService _maintenanceService = MaintenanceService();
  final MaintenanceItemService _maintenanceItemService =
      MaintenanceItemService();
  final CarService _carService = CarService();
  final CarPartService _carPartService = CarPartService();

  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _odometerController = TextEditingController();
  final _garageController = TextEditingController();
  final _nextOdometerController = TextEditingController();
  final _intervalKmController = TextEditingController();
  final _intervalDaysController = TextEditingController();
  final _providerController = TextEditingController();
  final _violationNumberController = TextEditingController();
  final _violationLocationController = TextEditingController();

  String _selectedCategory = 'maintenance';
  String _serviceStatus = 'done';
  DateTime _selectedDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _updateCarOdometer = true;
  bool _addReminder = true;
  _MaintenanceTemplate? _selectedTemplate;

  final List<_MaintenanceTemplate> _maintenanceTemplates = const [
    _MaintenanceTemplate(
      title: 'تغيير فلتر الزيت',
      icon: Icons.filter_alt,
      intervalKm: 5000,
      intervalDays: 180,
    ),
    _MaintenanceTemplate(
      title: 'تغيير زيت الموتور',
      icon: Icons.oil_barrel,
      intervalKm: 5000,
      intervalDays: 180,
    ),
    _MaintenanceTemplate(
      title: 'تغيير فلتر الهواء',
      icon: Icons.air,
      intervalKm: 10000,
      intervalDays: 365,
    ),
    _MaintenanceTemplate(
      title: 'تغيير فلتر التكييف',
      icon: Icons.ac_unit,
      intervalKm: 10000,
      intervalDays: 365,
    ),
    _MaintenanceTemplate(
      title: 'تغيير بوجيهات',
      icon: Icons.bolt,
      intervalKm: 30000,
      intervalDays: 730,
    ),
    _MaintenanceTemplate(
      title: 'تغيير تيل الفرامل',
      icon: Icons.car_repair,
      intervalKm: 20000,
      intervalDays: 730,
    ),
    _MaintenanceTemplate(
      title: 'تغيير زيت الفتيس',
      icon: Icons.settings,
      intervalKm: 60000,
      intervalDays: 1095,
    ),
    _MaintenanceTemplate(
      title: 'تغيير سائل التبريد',
      icon: Icons.water_drop,
      intervalKm: 40000,
      intervalDays: 730,
    ),
    _MaintenanceTemplate(
      title: 'تغيير البطارية',
      icon: Icons.battery_charging_full,
      intervalKm: 0,
      intervalDays: 730,
    ),
    _MaintenanceTemplate(
      title: 'تغيير/ الإطارات',
      icon: Icons.album,
      intervalKm: 50000,
      intervalDays: 1460,
    ),
    _MaintenanceTemplate(
      title: 'تغيير زيت الباور',
      icon: Icons.settings,
      intervalKm: 60000,
      intervalDays: 1095,
    ),
    _MaintenanceTemplate(
      title: 'تغيير فلتر الوقود',
      icon: Icons.settings,
      intervalKm: 60000,
      intervalDays: 1095,
    ),
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'maintenance',
      'label': 'صيانة',
      'icon': Icons.build,
      'color': const Color(0xFF43A047),
    },
    {
      'value': 'insurance',
      'label': 'تأمين',
      'icon': Icons.shield,
      'color': const Color(0xFF1E88E5),
    },
    {
      'value': 'license',
      'label': 'رخصة',
      'icon': Icons.credit_card,
      'color': const Color(0xFF8E24AA),
    },
    {
      'value': 'violation',
      'label': 'مخالفة',
      'icon': Icons.warning,
      'color': const Color(0xFFE53935),
    },
    {
      'value': 'wash',
      'label': 'غسيل',
      'icon': Icons.local_car_wash,
      'color': const Color(0xFF00ACC1),
    },
    {
      'value': 'inspection',
      'label': 'فحص',
      'icon': Icons.fact_check,
      'color': const Color(0xFFFB8C00),
    },
    {
      'value': 'emergency',
      'label': 'طوارئ',
      'icon': Icons.emergency,
      'color': const Color(0xFFD81B60),
    },
    {
      'value': 'other',
      'label': 'أخرى',
      'icon': Icons.more_horiz,
      'color': const Color(0xFF757575),
    },
  ];

  Map<String, dynamic> get _currentCategory =>
      _categories.firstWhere((c) => c['value'] == _selectedCategory);

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _odometerController.dispose();
    _garageController.dispose();
    _nextOdometerController.dispose();
    _intervalKmController.dispose();
    _intervalDaysController.dispose();
    _providerController.dispose();
    _violationNumberController.dispose();
    _violationLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry
          ? DateTime.now().add(const Duration(days: 365))
          : _selectedDate,
      firstDate: isExpiry ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _selectMaintenanceTemplate(_MaintenanceTemplate template) {
    final currentOdometer = double.tryParse(_odometerController.text.trim()) ??
        widget.car.currentOdometer;

    setState(() {
      _selectedTemplate = template;
      _selectedCategory = 'maintenance';
      _titleController.text = template.title;
      _intervalKmController.text =
          template.intervalKm == 0 ? '' : template.intervalKm.toString();
      _intervalDaysController.text =
          template.intervalDays == 0 ? '' : template.intervalDays.toString();
      if (template.intervalKm > 0) {
        _nextOdometerController.text =
            (currentOdometer + template.intervalKm).toStringAsFixed(0);
      }
      if (template.intervalDays > 0) {
        _expiryDate = _selectedDate.add(Duration(days: template.intervalDays));
      }
      _addReminder = true;
    });
  }

  void _recalculateNextReminder() {
    final odometer = double.tryParse(_odometerController.text.trim()) ??
        widget.car.currentOdometer;
    final intervalKm = double.tryParse(_intervalKmController.text.trim()) ?? 0;
    final intervalDays = int.tryParse(_intervalDaysController.text.trim()) ?? 0;

    setState(() {
      if (intervalKm > 0) {
        _nextOdometerController.text =
            (odometer + intervalKm).toStringAsFixed(0);
      }
      if (intervalDays > 0) {
        _expiryDate = _selectedDate.add(Duration(days: intervalDays));
      }
    });
  }

  Future<void> _saveServiceLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final odometer = _odometerController.text.trim().isEmpty
          ? null
          : double.tryParse(_odometerController.text.trim());
      final intervalKm = _addReminder
          ? double.tryParse(_intervalKmController.text.trim())
          : null;
      final intervalDays =
          _addReminder ? int.tryParse(_intervalDaysController.text.trim()) : null;
      final nextDueOdometer =
          _addReminder && _nextOdometerController.text.trim().isNotEmpty
              ? double.tryParse(_nextOdometerController.text.trim())
              : null;
      final expiryDate = _addReminder ? _expiryDate : null;

      final log = ServiceLogModel(
        logId: _maintenanceService.generateId(),
        carId: widget.car.carId,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        date: _selectedDate,
        cost: double.parse(_costController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _serviceStatus,
        reminderSent: false,
        odometer: odometer,
        garage: _garageController.text.trim().isEmpty
            ? null
            : _garageController.text.trim(),
        nextDueOdometer: nextDueOdometer,
        expiryDate: expiryDate,
        provider: _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
        violationNumber: _violationNumberController.text.trim().isEmpty
            ? null
            : _violationNumberController.text.trim(),
        violationLocation: _violationLocationController.text.trim().isEmpty
            ? null
            : _violationLocationController.text.trim(),
      );

      // بناء تحديث بيانات السيارة في خطوة واحدة
      final carUpdate = <String, dynamic>{};
      if (_updateCarOdometer &&
          odometer != null &&
          odometer > widget.car.currentOdometer) {
        carUpdate['currentOdometer'] = odometer;
        carUpdate['odometerUpdateSource'] = 'service';
        carUpdate['odometerUpdatedAt'] = DateTime.now();
      }
      if (_selectedCategory == 'maintenance' &&
          _titleController.text.trim().contains('زيت') &&
          odometer != null) {
        carUpdate['lastOilChangeOdometer'] = odometer;
      }

      final odometerForPart = odometer ?? widget.car.currentOdometer;

      // تشغيل كل العمليات بالتوازي
      await Future.wait([
        _maintenanceService.addServiceLog(log),
        _maintenanceItemService.upsertFromServiceLog(
          log: log,
          intervalKm: intervalKm,
          intervalDays: intervalDays,
        ),
        if (log.category == 'maintenance')
          _carPartService.upsertFromServiceTitle(
            carId: widget.car.carId,
            serviceTitle: log.title,
            currentOdometer: odometerForPart,
            intervalKm: intervalKm,
            intervalDays: intervalDays,
            nextDueOdometer: nextDueOdometer,
            nextDueDate: expiryDate,
          ),
        if (carUpdate.isNotEmpty)
          _carService.updateCar(widget.car.carId, carUpdate),
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تم تسجيل الخدمة بنجاح! ✅', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final categoryColor = _currentCategory['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: categoryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [categoryColor, categoryColor.withAlpha(178)],
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
                          'تسجيل خدمة جديدة',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.car.make} ${widget.car.model}',
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
              'تسجيل خدمة',
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
                    // اختيار التصنيف
                    Container(
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
                                'نوع الخدمة',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(_currentCategory['icon'] as IconData,
                                  color: categoryColor, size: 20),
                            ],
                          ),
                          const Divider(height: 20),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                            children: _categories.map((cat) {
                              final isSelected =
                                  _selectedCategory == cat['value'];
                              final color = cat['color'] as Color;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedCategory = cat['value'];
                                  if (_selectedCategory != 'maintenance') {
                                    _selectedTemplate = null;
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withAlpha(26),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withAlpha(102),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        color:
                                            isSelected ? Colors.white : color,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat['label'],
                                        style: GoogleFonts.cairo(
                                          color:
                                              isSelected ? Colors.white : color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
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

                    if (_selectedCategory == 'maintenance') ...[
                      _buildMaintenanceTemplates(categoryColor),
                      const SizedBox(height: 16),
                    ],

                    // البيانات الأساسية
                    _buildCard(
                      title: 'البيانات الأساسية',
                      icon: Icons.info,
                      color: categoryColor,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'اسم الخدمة',
                          hint: _getHint(),
                          icon: Icons.description,
                          color: categoryColor,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل اسم الخدمة' : null,
                        ),
                        _buildTextField(
                          controller: _costController,
                          label: 'التكلفة',
                          hint: 'مثال: 250',
                          icon: Icons.attach_money,
                          color: categoryColor,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'من فضلك أدخل التكلفة';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'رقم غير صالح';
                            }
                            return null;
                          },
                        ),
                        _buildStatusSelector(categoryColor),

                        // تاريخ الخدمة
                        GestureDetector(
                          onTap: () => _pickDate(false),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.calendar_today,
                                    color: categoryColor, size: 20),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(_selectedDate),
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: categoryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تاريخ الخدمة',
                                      style:
                                          GoogleFonts.cairo(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        _buildTextField(
                          controller: _notesController,
                          label: 'ملاحظات (اختياري)',
                          hint: 'أي تفاصيل إضافية',
                          icon: Icons.note,
                          color: categoryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // حقول خاصة بالتصنيف
                    _buildCategorySpecificFields(categoryColor),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveServiceLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'تسجيل الخدمة ✅',
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

  Widget _buildCategorySpecificFields(Color color) {
    switch (_selectedCategory) {
      case 'maintenance':
        return _buildCard(
          title: 'تفاصيل الصيانة',
          icon: Icons.build,
          color: color,
          children: [
            _buildTextField(
              controller: _odometerController,
              label: 'قراءة العداد (كم)',
              hint: '${widget.car.currentOdometer}',
              icon: Icons.speed,
              color: color,
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalculateNextReminder(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'أدخل قراءة العداد';
                }
                final value = double.tryParse(v.trim());
                if (value == null) return 'رقم غير صالح';
                if (value < widget.car.currentOdometer) {
                  return 'لا يمكن أن يقل عن العداد الحالي';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _garageController,
              label: 'الكراج/الورشة',
              hint: 'مثال: ورشة الأمين',
              icon: Icons.garage,
              color: color,
            ),
            _buildTextField(
              controller: _nextOdometerController,
              label: 'موعد الصيانة القادمة (كم)',
              hint: 'مثال: 80000',
              icon: Icons.update,
              color: color,
              keyboardType: TextInputType.number,
            ),
            _buildReminderTools(color),
          ],
        );

      case 'insurance':
        return _buildCard(
          title: 'تفاصيل التأمين',
          icon: Icons.shield,
          color: color,
          children: [
            _buildTextField(
              controller: _providerController,
              label: 'شركة التأمين',
              hint: 'مثال: الشركة المتحدة',
              icon: Icons.business,
              color: color,
            ),
            _buildExpiryDatePicker(color),
          ],
        );

      case 'license':
        return _buildCard(
          title: 'تفاصيل الرخصة',
          icon: Icons.credit_card,
          color: color,
          children: [
            _buildExpiryDatePicker(color),
          ],
        );

      case 'violation':
        return _buildCard(
          title: 'تفاصيل المخالفة',
          icon: Icons.warning,
          color: color,
          children: [
            _buildTextField(
              controller: _violationNumberController,
              label: 'رقم المخالفة',
              hint: 'مثال: 12345',
              icon: Icons.numbers,
              color: color,
            ),
            _buildTextField(
              controller: _violationLocationController,
              label: 'موقع المخالفة',
              hint: 'مثال: شارع التحرير',
              icon: Icons.location_on,
              color: color,
            ),
          ],
        );

      case 'inspection':
        return _buildCard(
          title: 'تفاصيل الفحص',
          icon: Icons.fact_check,
          color: color,
          children: [
            _buildTextField(
              controller: _odometerController,
              label: 'قراءة العداد (كم)',
              hint: '${widget.car.currentOdometer}',
              icon: Icons.speed,
              color: color,
              keyboardType: TextInputType.number,
            ),
            _buildExpiryDatePicker(color),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMaintenanceTemplates(Color color) {
    return _buildCard(
      title: 'اختار القطعة',
      icon: Icons.tune,
      color: color,
      children: [
        GridView.builder(
          itemCount: _maintenanceTemplates.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.45,
          ),
          itemBuilder: (context, index) {
            final template = _maintenanceTemplates[index];
            final selected = _selectedTemplate?.title == template.title;
            return InkWell(
              onTap: () => _selectMaintenanceTemplate(template),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected ? color : color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : color.withAlpha(36),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          color: selected ? Colors.white : color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      template.icon,
                      color: selected ? Colors.white : color,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusSelector(Color color) {
    final statuses = [
      {'value': 'done', 'label': 'تمت', 'icon': Icons.check_circle},
      {'value': 'planned', 'label': 'مخططة', 'icon': Icons.event_available},
      {'value': 'urgent', 'label': 'طارئة', 'icon': Icons.priority_high},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: statuses.map((status) {
          final selected = _serviceStatus == status['value'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => setState(
                  () => _serviceStatus = status['value'] as String,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? color : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : const Color(0xFFE6EAF0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        status['icon'] as IconData,
                        color: selected ? Colors.white : color,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status['label'] as String,
                        style: GoogleFonts.cairo(
                          color: selected ? Colors.white : color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReminderTools(Color color) {
    return Column(
      children: [
        SwitchListTile(
          value: _addReminder,
          onChanged: (value) => setState(() => _addReminder = value),
          activeColor: color,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'إضافة تنبيه للصيانة القادمة',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          secondary: Icon(Icons.notifications_active, color: color),
        ),
        if (_addReminder) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _intervalDaysController,
                  label: 'كل كام يوم',
                  hint: 'مثال: 180',
                  icon: Icons.calendar_month,
                  color: color,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateNextReminder(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _intervalKmController,
                  label: 'كل كام كم',
                  hint: 'مثال: 5000',
                  icon: Icons.route,
                  color: color,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateNextReminder(),
                ),
              ),
            ],
          ),
          _buildExpiryDatePicker(color),
        ],
        SwitchListTile(
          value: _updateCarOdometer,
          onChanged: (value) => setState(() => _updateCarOdometer = value),
          activeColor: color,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'تحديث عداد السيارة بهذه القراءة',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          secondary: Icon(Icons.speed, color: color),
        ),
      ],
    );
  }

  Widget _buildExpiryDatePicker(Color color) {
    return GestureDetector(
      onTap: () => _pickDate(true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expiryDate != null
              ? color.withAlpha(26)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expiryDate != null ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              _expiryDate != null ? Icons.check_circle : Icons.calendar_month,
              color: color,
              size: 20,
            ),
            Row(
              children: [
                Text(
                  _expiryDate != null
                      ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                      : 'اختار التاريخ',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: _expiryDate != null ? color : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'تاريخ الانتهاء',
                  style: GoogleFonts.cairo(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getHint() {
    switch (_selectedCategory) {
      case 'maintenance':
        return 'مثال: تغيير زيت + فلتر';
      case 'insurance':
        return 'مثال: تأمين شامل 2025';
      case 'license':
        return 'مثال: تجديد رخصة السيارة';
      case 'violation':
        return 'مثال: تجاوز السرعة';
      case 'wash':
        return 'مثال: غسيل كامل داخلي وخارجي';
      case 'inspection':
        return 'مثال: فحص دوري سنوي';
      case 'emergency':
        return 'مثال: تغيير إطار طارئ';
      default:
        return 'اسم الخدمة';
    }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: color),
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
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
