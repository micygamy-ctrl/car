import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/service_log_service.dart';
import '../models/maintenance_log_model.dart';
import '../models/car_model.dart';
import '../services/maintenance_service.dart';



class AddMaintenanceScreen extends StatefulWidget {
  final CarModel car;

  const AddMaintenanceScreen({super.key, required this.car});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaintenanceService _MaintenanceService = MaintenanceService();

  final _titleController = TextEditingController();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _garageController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextOdometerController = TextEditingController();

  String _selectedCategory = 'oil_change';
  bool _isLoading = false;
  bool _addReminder = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'oil_change', 'label': 'تغيير زيت', 'icon': Icons.oil_barrel},
    {'value': 'tire', 'label': 'إطارات', 'icon': Icons.tire_repair},
    {'value': 'brakes', 'label': 'فرامل', 'icon': Icons.car_crash},
    {'value': 'inspection', 'label': 'فحص دوري', 'icon': Icons.fact_check},
    {'value': 'other', 'label': 'أخرى', 'icon': Icons.build},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _odometerController.dispose();
    _costController.dispose();
    _garageController.dispose();
    _notesController.dispose();
    _nextOdometerController.dispose();
    super.dispose();
  }

  Future<void> _saveMaintenanceLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final log = ServiceLogModel(
        logId: _MaintenanceService.generateId(),
        carId: widget.car.carId,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        date: DateTime.now(),
        odometer: double.parse(_odometerController.text.trim()),
        cost: double.parse(_costController.text.trim()),
        garage: _garageController.text.trim().isEmpty ? null : _garageController.text.trim(),
        status: 'done',
        nextDueOdometer: _addReminder && _nextOdometerController.text.trim().isNotEmpty
            ? double.parse(_nextOdometerController.text.trim())
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        reminderSent: false,
      );

      await _MaintenanceService.addMaintenanceLog(log);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل الصيانة بنجاح! 🔧', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            backgroundColor: const Color(0xFF43A047),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
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
                          'تسجيل صيانة 🔧',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.car.make} ${widget.car.model} • العداد: ${widget.car.currentOdometer} كم',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'تسجيل صيانة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // نوع الصيانة
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
                                'نوع الصيانة',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF43A047),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.build, color: Color(0xFF43A047), size: 20),
                            ],
                          ),
                          const Divider(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['value'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat['value']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF43A047) : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cat['label'],
                                        style: GoogleFonts.cairo(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 16,
                                        color: isSelected ? Colors.white : Colors.grey[700],
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

                    // تفاصيل الصيانة
                    _buildCard(
                      title: 'تفاصيل الصيانة',
                      icon: Icons.list_alt,
                      color: const Color(0xFF43A047),
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'وصف الصيانة',
                          hint: 'مثال: تغيير زيت + فلتر هواء',
                          icon: Icons.description,
                          validator: (v) => v!.isEmpty ? 'من فضلك أدخل وصف الصيانة' : null,
                        ),
                        _buildTextField(
                          controller: _odometerController,
                          label: 'قراءة العداد (كم)',
                          hint: '${widget.car.currentOdometer}',
                          icon: Icons.speed,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'من فضلك أدخل قراءة العداد' : null,
                        ),
                        _buildTextField(
                          controller: _costController,
                          label: 'التكلفة',
                          hint: 'مثال: 250',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'من فضلك أدخل التكلفة' : null,
                        ),
                        _buildTextField(
                          controller: _garageController,
                          label: 'الكراج/الورشة (اختياري)',
                          hint: 'مثال: ورشة الأمين',
                          icon: Icons.garage,
                        ),
                        _buildTextField(
                          controller: _notesController,
                          label: 'ملاحظات (اختياري)',
                          hint: 'أي ملاحظات إضافية',
                          icon: Icons.note,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // تذكير
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Switch(
                                value: _addReminder,
                                onChanged: (v) => setState(() => _addReminder = v),
                                activeColor: const Color(0xFF43A047),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'تذكير للصيانة القادمة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.notifications, color: Color(0xFF43A047)),
                                ],
                              ),
                            ],
                          ),
                          if (_addReminder) ...[
                            const Divider(height: 20),
                            _buildTextField(
                              controller: _nextOdometerController,
                              label: 'العداد عند الصيانة القادمة (كم)',
                              hint: 'مثال: 75000',
                              icon: Icons.speed,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMaintenanceLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'تسجيل الصيانة 🔧',
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
            borderSide: const BorderSide(color: Color(0xFF43A047), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}