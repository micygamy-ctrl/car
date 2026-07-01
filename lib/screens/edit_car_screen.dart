import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/car_service.dart';
import '../services/car_part_service.dart';
import '../models/car_model.dart';
import '../models/car_part_model.dart';

class EditCarScreen extends StatefulWidget {
  final CarModel car;

  const EditCarScreen({super.key, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();
  final CarPartService _carPartService = CarPartService();

  // --- Controllers: بيانات السيارة ---
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateController;
  late TextEditingController _odometerController;
  late TextEditingController _tankCapacityController;
  late TextEditingController _oilIntervalController;

  late String _selectedFuelType;
  bool _isLoading = false;

  // --- بيانات القطع ---
  List<CarPartModel> _parts = [];
  final Map<String, TextEditingController> _partLastKmCtrl = {};
  final Map<String, TextEditingController> _partNextKmCtrl = {};
  final Map<String, TextEditingController> _partIntervalKmCtrl = {};
  final Map<String, TextEditingController> _partIntervalDaysCtrl = {};
  final Map<String, DateTime?> _partNextDates = {};
  bool _partsLoaded = false;

  final List<Map<String, dynamic>> _fuelTypes = [
    {'value': 'petrol', 'label': 'بنزين', 'icon': Icons.local_gas_station},
    {'value': 'diesel', 'label': 'ديزل', 'icon': Icons.oil_barrel},
    {'value': 'hybrid', 'label': 'هايبريد', 'icon': Icons.electric_bolt},
  ];

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.car.make);
    _modelController = TextEditingController(text: widget.car.model);
    _yearController = TextEditingController(text: '${widget.car.year}');
    _plateController = TextEditingController(text: widget.car.licensePlate);
    _odometerController = TextEditingController(
        text: widget.car.currentOdometer.toStringAsFixed(0));
    _tankCapacityController =
        TextEditingController(text: widget.car.tankCapacity.toStringAsFixed(0));
    _oilIntervalController = TextEditingController(
        text: widget.car.oilChangeInterval.toStringAsFixed(0));
    _selectedFuelType = widget.car.fuelType;
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      final parts = await _carPartService.getCarParts(widget.car.carId).first;
      parts.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _parts = parts;
        for (final p in parts) {
          _partLastKmCtrl[p.partId] = TextEditingController(
              text: p.lastServiceOdometer?.toStringAsFixed(0) ?? '');
          _partNextKmCtrl[p.partId] = TextEditingController(
              text: p.nextDueOdometer?.toStringAsFixed(0) ?? '');
          _partIntervalKmCtrl[p.partId] = TextEditingController(
              text: p.intervalKm?.toStringAsFixed(0) ?? '');
          _partIntervalDaysCtrl[p.partId] =
              TextEditingController(text: p.intervalDays?.toString() ?? '');
          _partNextDates[p.partId] = p.nextDueDate;
        }
        _partsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _partsLoaded = true);
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _tankCapacityController.dispose();
    _oilIntervalController.dispose();
    for (final c in _partLastKmCtrl.values) c.dispose();
    for (final c in _partNextKmCtrl.values) c.dispose();
    for (final c in _partIntervalKmCtrl.values) c.dispose();
    for (final c in _partIntervalDaysCtrl.values) c.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────
  //  حفظ كل التعديلات
  // ─────────────────────────────────────
  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newOdometer = double.parse(_odometerController.text.trim());

      // تحديث بيانات السيارة + تحديث القطع بالتوازي
      await Future.wait([
        _carService.updateCar(widget.car.carId, {
          'make': _makeController.text.trim(),
          'model': _modelController.text.trim(),
          'year': int.parse(_yearController.text.trim()),
          'licensePlate': _plateController.text.trim(),
          'currentOdometer': newOdometer,
          'fuelType': _selectedFuelType,
          'tankCapacity': double.parse(_tankCapacityController.text.trim()),
          'oilChangeInterval': double.parse(_oilIntervalController.text.trim()),
        }),
        _savePartsEdits(),
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التعديلات! 🚗', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
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

  Future<void> _savePartsEdits() async {
    if (_parts.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (final part in _parts) {
      final lastKm =
          double.tryParse(_partLastKmCtrl[part.partId]?.text.trim() ?? '');
      final nextKm =
          double.tryParse(_partNextKmCtrl[part.partId]?.text.trim() ?? '');
      final intervalKm =
          double.tryParse(_partIntervalKmCtrl[part.partId]?.text.trim() ?? '');
      final intervalDays =
          int.tryParse(_partIntervalDaysCtrl[part.partId]?.text.trim() ?? '');
      final nextDate = _partNextDates[part.partId];

      final update = <String, dynamic>{'updatedAt': now};
      if (lastKm != null) update['lastServiceOdometer'] = lastKm;
      if (nextKm != null) update['nextDueOdometer'] = nextKm;
      if (intervalKm != null) update['intervalKm'] = intervalKm;
      if (intervalDays != null) update['intervalDays'] = intervalDays;
      update['nextDueDate'] = nextDate;

      batch.update(
        FirebaseFirestore.instance.collection('carParts').doc(part.partId),
        update,
      );
    }

    await batch.commit();
  }

  // ─────────────────────────────────────
  //  تعديل قطعة في dialog
  // ─────────────────────────────────────
  void _editPartDialog(CarPartModel part) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lastCtrl = _partLastKmCtrl[part.partId]!;
        final nextCtrl = _partNextKmCtrl[part.partId]!;
        final intKmCtrl = _partIntervalKmCtrl[part.partId]!;
        final intDaysCtrl = _partIntervalDaysCtrl[part.partId]!;
        DateTime? pickedDate = _partNextDates[part.partId];

        return StatefulBuilder(builder: (ctx, setDs) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              part.name,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    controller: lastCtrl,
                    label: 'آخر صيانة (كم)',
                    icon: Icons.history,
                    color: const Color(0xFF43A047),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: nextCtrl,
                    label: 'الموعد القادم (كم)',
                    icon: Icons.speed,
                    color: const Color(0xFF1E88E5),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: intKmCtrl,
                    label: 'الفترة بالكيلومتر',
                    icon: Icons.repeat,
                    color: const Color(0xFF8E24AA),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: intDaysCtrl,
                    label: 'الفترة بالأيام',
                    icon: Icons.calendar_today,
                    color: const Color(0xFFFB8C00),
                  ),
                  const SizedBox(height: 12),
                  // اختيار تاريخ الموعد القادم
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: pickedDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF1E88E5))),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDs(() => pickedDate = picked);
                        setState(() => _partNextDates[part.partId] = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.event,
                              color: Color(0xFF1E88E5), size: 20),
                          Text(
                            pickedDate != null
                                ? DateFormat('dd/MM/yyyy').format(pickedDate!)
                                : 'تاريخ الموعد القادم',
                            style: GoogleFonts.cairo(
                              color: pickedDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _partNextDates[part.partId] = pickedDate);
                  Navigator.pop(ctx);
                },
                child:
                    Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 13),
        prefixIcon: Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ─────────────────────────────────────
  //  UI
  // ─────────────────────────────────────
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
                          'تعديل بيانات السيارة ✏️',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.car.make} ${widget.car.model}',
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text('تعديل السيارة',
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
                    // ── بيانات السيارة ──
                    _buildCard(
                      title: 'بيانات السيارة',
                      icon: Icons.directions_car,
                      color: const Color(0xFF1E88E5),
                      children: [
                        _buildTextField(
                          controller: _makeController,
                          label: 'الماركة',
                          hint: 'مثال: Toyota',
                          icon: Icons.branding_watermark,
                          validator: (v) =>
                              v!.isEmpty ? 'من فضلك أدخل الماركة' : null,
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

                    // ── نوع الوقود ──
                    _buildFuelTypeCard(),
                    const SizedBox(height: 16),

                    // ── العداد والوقود ──
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

                    // ── قطع السيارة والتذكيرات ──
                    _buildPartsSection(),
                    const SizedBox(height: 24),

                    // ── زرار الحفظ ──
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
                            : Text('حفظ كل التعديلات ✏️',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
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

  // ─────────────────────────────────────
  //  قسم القطع والتذكيرات
  // ─────────────────────────────────────
  Widget _buildPartsSection() {
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
                'قطع السيارة والتذكيرات',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8E24AA),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.build, color: Color(0xFF8E24AA), size: 20),
            ],
          ),
          const Divider(height: 20),
          if (!_partsLoaded)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ))
          else if (_parts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('لا توجد قطع مسجلة بعد',
                    style: GoogleFonts.cairo(color: Colors.grey)),
              ),
            )
          else
            ...(_parts.map((part) => _buildPartRow(part)).toList()),
        ],
      ),
    );
  }

  Widget _buildPartRow(CarPartModel part) {
    final status = part.status(widget.car.currentOdometer);
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case PartStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        break;
      case PartStatus.dueSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        break;
      case PartStatus.ok:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    final nextKmText = _partNextKmCtrl[part.partId]?.text ?? '';
    final lastKmText = _partLastKmCtrl[part.partId]?.text ?? '';
    final nextDate = _partNextDates[part.partId];

    return GestureDetector(
      onTap: () => _editPartDialog(part),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر التعديل
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, size: 16, color: Color(0xFF1E88E5)),
            ),
            // التفاصيل
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      part.name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (nextKmText.isNotEmpty)
                          Text(
                            'القادم: $nextKmText كم',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        if (nextKmText.isNotEmpty && lastKmText.isNotEmpty)
                          const Text('  ·  ',
                              style: TextStyle(color: Colors.grey)),
                        if (lastKmText.isNotEmpty)
                          Text(
                            'آخر: $lastKmText كم',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        if (nextDate != null && nextKmText.isEmpty)
                          Text(
                            DateFormat('dd/MM/yy').format(nextDate),
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // حالة القطعة
            Icon(statusIcon, color: statusColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────
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
              Text('نوع الوقود',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                  )),
              const SizedBox(width: 8),
              const Icon(Icons.local_gas_station,
                  color: Color(0xFF1E88E5), size: 20),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _fuelTypes.map((fuel) {
              final isSelected = _selectedFuelType == fuel['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedFuelType = fuel['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E88E5)
                        : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF1E88E5).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(fuel['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 24),
                      const SizedBox(height: 4),
                      Text(fuel['label'],
                          style: GoogleFonts.cairo(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
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
              Text(title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
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
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
