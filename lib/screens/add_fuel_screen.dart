import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/fuel_service.dart';
import '../services/car_service.dart';
import '../models/fuel_log_model.dart';
import '../models/car_model.dart';
import 'ocr_screen.dart';

class AddFuelScreen extends StatefulWidget {
  final CarModel car;

  const AddFuelScreen({super.key, required this.car});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final FuelService _fuelService = FuelService();
  final CarService _carService = CarService();

  final _odometerController = TextEditingController();
  final _fuelAmountController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isFullTank = true;
  bool _isLoading = false;
  double _lastFullTankOdometer = 0;

  @override
  void initState() {
    super.initState();
    _lastFullTankOdometer = widget.car.currentOdometer;
    _loadLastFullTankOdometer();
  }

  Future<void> _loadLastFullTankOdometer() async {
    try {
      final logs = await _fuelService.getCarFuelLogs(widget.car.carId).first;
      final fullTankLogs = logs.where((l) => l.isFullTank).toList();
      if (fullTankLogs.isNotEmpty && mounted) {
        setState(() {
          _lastFullTankOdometer = fullTankLogs.first.odometer;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _fuelAmountController.dispose();
    _pricePerUnitController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _calculateEfficiency() {
    final currentOdometer = double.tryParse(_odometerController.text.trim());
    final fuelAmount = double.tryParse(_fuelAmountController.text.trim());
    if (currentOdometer == null || fuelAmount == null || fuelAmount == 0)
      return null;
    final distance = currentOdometer - _lastFullTankOdometer;
    if (distance <= 0) return null;
    return (fuelAmount / distance) * 100;
  }

  double get _totalCost {
    final fuel = double.tryParse(_fuelAmountController.text) ?? 0;
    final price = double.tryParse(_pricePerUnitController.text) ?? 0;
    return fuel * price;
  }

  Future<void> _saveFuelLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final fuelAmount = double.parse(_fuelAmountController.text.trim());
      final pricePerUnit = double.parse(_pricePerUnitController.text.trim());
      final odometer = double.parse(_odometerController.text.trim());
      final efficiency = _isFullTank ? _calculateEfficiency() : null;

      final log = FuelLogModel(
        logId: _fuelService.generateId(),
        carId: widget.car.carId,
        date: DateTime.now(),
        odometer: odometer,
        odometerSource: 'manual',
        fuelAmount: fuelAmount,
        pricePerUnit: pricePerUnit,
        totalCost: fuelAmount * pricePerUnit,
        isFullTank: _isFullTank,
        stationName: _stationController.text.trim().isEmpty
            ? null
            : _stationController.text.trim(),
        calculatedEfficiency: efficiency,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await Future.wait([
        _fuelService.addFuelLog(log),
        _carService.updateCar(widget.car.carId, {'currentOdometer': odometer}),
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              efficiency != null
                  ? 'تم التسجيل! الاستهلاك: ${efficiency.toStringAsFixed(1)} لتر/100كم ⛽'
                  : 'تم تسجيل الوقود بنجاح! ⛽',
              style: GoogleFonts.cairo(),
            ),
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
                          'تسجيل وقود ⛽',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.car.make} ${widget.car.model} • العداد: ${widget.car.currentOdometer} كم',
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'تسجيل وقود',
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // كارت الإجمالي
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الإجمالي',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white70, fontSize: 13)),
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _fuelAmountController,
                                  _pricePerUnitController
                                ]),
                                builder: (context, _) => Text(
                                  '${_totalCost.toStringAsFixed(2)} ج.م',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.local_gas_station,
                              color: Colors.white, size: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // بيانات التزود
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زرار OCR
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OcrScreen(
                                        onOdometerDetected: (value) {
                                          setState(() {
                                            _odometerController.text =
                                                value.toStringAsFixed(0);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.camera_alt,
                                    color: Color(0xFF1E88E5), size: 18),
                                label: Text(
                                  'قراءة بالكاميرا',
                                  style: GoogleFonts.cairo(
                                      color: const Color(0xFF1E88E5),
                                      fontSize: 13),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'بيانات التزود',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E88E5),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_note,
                                      color: Color(0xFF1E88E5), size: 20),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildTextField(
                            controller: _odometerController,
                            label: 'قراءة العداد (كم)',
                            hint:
                                'مثال: ${(widget.car.currentOdometer + 500).toStringAsFixed(0)}',
                            icon: Icons.speed,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v!.isEmpty)
                                return 'من فضلك أدخل قراءة العداد';
                              final val = double.tryParse(v);
                              if (val == null) return 'رقم غير صحيح';
                              if (val <= widget.car.currentOdometer) {
                                return 'يجب أن يكون أكبر من ${widget.car.currentOdometer}';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          _buildTextField(
                            controller: _fuelAmountController,
                            label: 'كمية الوقود (لتر)',
                            hint: 'مثال: 40',
                            icon: Icons.local_gas_station,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'من فضلك أدخل كمية الوقود' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          _buildTextField(
                            controller: _pricePerUnitController,
                            label: 'سعر اللتر',
                            hint: 'مثال: 8.50',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'من فضلك أدخل سعر اللتر' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          _buildTextField(
                            controller: _stationController,
                            label: 'اسم المحطة (اختياري)',
                            hint: 'مثال: محطة الشل',
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // خزان ممتلئ
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Switch(
                            value: _isFullTank,
                            onChanged: (v) => setState(() => _isFullTank = v),
                            activeColor: const Color(0xFF1E88E5),
                          ),
                          Row(
                            children: [
                              Text(
                                'خزان ممتلئ؟',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isFullTank
                                    ? Icons.water_drop
                                    : Icons.water_drop_outlined,
                                color: const Color(0xFF1E88E5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ملاحظات
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
                                'ملاحظات',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.note_alt,
                                  color: Colors.grey, size: 20),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildTextField(
                            controller: _notesController,
                            label: 'ملاحظات (اختياري)',
                            hint: 'أي ملاحظات إضافية',
                            icon: Icons.note,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveFuelLog,
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
                                'تسجيل الوقود ⛽',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
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
