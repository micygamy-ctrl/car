import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/maintenance_service.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';

class AddServiceScreen extends StatefulWidget {
  final CarModel car;

  const AddServiceScreen({super.key, required this.car});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaintenanceService _MaintenanceService = MaintenanceService();

  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _odometerController = TextEditingController();
  final _garageController = TextEditingController();
  final _nextOdometerController = TextEditingController();
  final _providerController = TextEditingController();
  final _violationNumberController = TextEditingController();
  final _violationLocationController = TextEditingController();

  String _selectedCategory = 'maintenance';
  DateTime _selectedDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isLoading = false;

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

  Future<void> _saveServiceLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final log = ServiceLogModel(
        logId: _MaintenanceService.generateId(),
        carId: widget.car.carId,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        date: _selectedDate,
        cost: double.parse(_costController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: 'done',
        reminderSent: false,
        odometer: _odometerController.text.trim().isEmpty
            ? null
            : double.tryParse(_odometerController.text.trim()),
        garage: _garageController.text.trim().isEmpty
            ? null
            : _garageController.text.trim(),
        nextDueOdometer: _nextOdometerController.text.trim().isEmpty
            ? null
            : double.tryParse(_nextOdometerController.text.trim()),
        expiryDate: _expiryDate,
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

      await _MaintenanceService.addServiceLog(log);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل الخدمة بنجاح! ✅',
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
                    colors: [categoryColor, categoryColor.withOpacity(0.7)],
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
                                onTap: () => setState(
                                    () => _selectedCategory = cat['value']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
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
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat['label'],
                                        style: GoogleFonts.cairo(
                                          color: isSelected
                                              ? Colors.white
                                              : color,
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
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل التكلفة' : null,
                        ),

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
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey),
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

  Widget _buildExpiryDatePicker(Color color) {
    return GestureDetector(
      onTap: () => _pickDate(true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expiryDate != null
              ? color.withOpacity(0.1)
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
      case 'maintenance': return 'مثال: تغيير زيت + فلتر';
      case 'insurance': return 'مثال: تأمين شامل 2025';
      case 'license': return 'مثال: تجديد رخصة السيارة';
      case 'violation': return 'مثال: تجاوز السرعة';
      case 'wash': return 'مثال: غسيل كامل داخلي وخارجي';
      case 'inspection': return 'مثال: فحص دوري سنوي';
      case 'emergency': return 'مثال: تغيير إطار طارئ';
      default: return 'اسم الخدمة';
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
    required Color color,
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