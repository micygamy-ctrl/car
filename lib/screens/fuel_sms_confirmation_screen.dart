import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/fuel_log_model.dart';
import '../models/car_model.dart';
import '../services/fuel_service.dart';
import '../services/car_service.dart';
import '../services/sms_service.dart';

class FuelSmsConfirmationScreen extends StatefulWidget {
  final SmsFuelResult smsResult;
  final List<CarModel> cars;

  const FuelSmsConfirmationScreen({
    super.key,
    required this.smsResult,
    required this.cars,
  });

  @override
  State<FuelSmsConfirmationScreen> createState() =>
      _FuelSmsConfirmationScreenState();
}

class _FuelSmsConfirmationScreenState extends State<FuelSmsConfirmationScreen> {
  final FuelService _fuelService = FuelService();
  final CarService _carService = CarService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _litersController;
  late TextEditingController _odometerController;
  late TextEditingController _pricePerLiterController;

  CarModel? _selectedCar;
  bool _isFullTank = true;
  bool _isSaving = false;
  String _prefs_currency = 'EGP';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.smsResult.amountEGP.toStringAsFixed(2));
    _litersController = TextEditingController();
    _odometerController = TextEditingController();
    _pricePerLiterController = TextEditingController();

    // إذا كان عنده سيارة واحدة اختارها تلقائياً
    if (widget.cars.length == 1) {
      _selectedCar = widget.cars.first;
      _odometerController.text =
          _selectedCar!.currentOdometer.toStringAsFixed(0);
    }

    _loadCurrency();
    _autoCalcPricePerLiter();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString('currency') ?? 'EGP';
    final lastPrice = prefs.getDouble('last_price_per_liter');
    setState(() {
      _prefs_currency = currency;
      if (lastPrice != null && lastPrice > 0) {
        _pricePerLiterController.text = lastPrice.toStringAsFixed(2);
      }
    });
    _calcLiters();
  }

  Future<void> _savePricePerLiter(double price) async {
    if (price <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_price_per_liter', price);
  }

  void _autoCalcPricePerLiter() {
    _amountController.addListener(_calcLiters);
    _pricePerLiterController.addListener(_calcLiters);
  }

  void _calcLiters() {
    final amount = double.tryParse(_amountController.text);
    final price = double.tryParse(_pricePerLiterController.text);
    if (amount != null && price != null && price > 0) {
      final liters = amount / price;
      if (_litersController.text != liters.toStringAsFixed(2)) {
        setState(() {
          _litersController.text = liters.toStringAsFixed(2);
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _litersController.dispose();
    _odometerController.dispose();
    _pricePerLiterController.dispose();
    super.dispose();
  }

  Future<void> _saveFuelLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('اختر السيارة أولاً', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uuid = const Uuid();
      final odometer = double.tryParse(_odometerController.text) ??
          _selectedCar!.currentOdometer;
      final fuelAmount = double.tryParse(_litersController.text) ?? 0;
      final pricePerUnit = double.tryParse(_pricePerLiterController.text) ?? 0;
      final totalCost = double.tryParse(_amountController.text) ?? 0;

      final log = FuelLogModel(
        logId: uuid.v4(),
        carId: _selectedCar!.carId,
        date: widget.smsResult.date,
        odometer: odometer,
        odometerSource: 'manual',
        fuelAmount: fuelAmount,
        pricePerUnit: pricePerUnit,
        totalCost: totalCost,
        isFullTank: _isFullTank,
        stationName: widget.smsResult.merchantName,
        notes: 'تم اكتشافه تلقائياً من رسالة ${widget.smsResult.bankName}',
      );

      await Future.wait([
        _fuelService.addFuelLog(log),
        SmsService().markSmsAsProcessed(widget.smsResult.smsId),
        if (pricePerUnit > 0) _savePricePerLiter(pricePerUnit),
        if (odometer > _selectedCar!.currentOdometer)
          _carService.updateCar(_selectedCar!.carId, {
            'currentOdometer': odometer,
            'odometerUpdateSource': 'manual',
          }),
      ]);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('تم تسجيل الوقود تلقائياً ✅', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF43A047),
        ));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A047),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'تسجيل وقود تلقائي ⛽',
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // بطاقة الرسالة
              _buildSmsCard(),
              const SizedBox(height: 16),

              // اختيار السيارة
              _buildCarSelector(),
              const SizedBox(height: 16),

              // تفاصيل الوقود
              _buildFuelDetailsCard(),
              const SizedBox(height: 16),

              // العداد
              _buildOdometerCard(),
              const SizedBox(height: 24),

              // أزرار
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await SmsService()
                            .markSmsAsProcessed(widget.smsResult.smsId);
                        if (mounted) Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('تجاهل',
                          style: GoogleFonts.cairo(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFuelLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('تسجيل الوقود ✅',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildSmsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'رسالة بنكية مكتشفة! 🏦',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.sms, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmsInfoRow('البنك', widget.smsResult.bankName),
          _buildSmsInfoRow('المحطة', widget.smsResult.merchantName),
          _buildSmsInfoRow('المبلغ',
              '${widget.smsResult.amountEGP.toStringAsFixed(2)} $_prefs_currency'),
          const Divider(color: Colors.white24, height: 20),
          Text(
            widget.smsResult.rawSms,
            style: GoogleFonts.cairo(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSmsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCarSelector() {
    return _buildCard(
      title: 'اختر السيارة',
      icon: Icons.directions_car,
      color: const Color(0xFF1E88E5),
      child: widget.cars.isEmpty
          ? Text('لا توجد سيارات مسجلة',
              style: GoogleFonts.cairo(color: Colors.grey),
              textAlign: TextAlign.right)
          : Column(
              children: widget.cars.map((car) {
                final isSelected = _selectedCar?.carId == car.carId;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCar = car;
                    _odometerController.text =
                        car.currentOdometer.toStringAsFixed(0);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5).withOpacity(0.1)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1E88E5), size: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${car.make} ${car.model}',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1E88E5)
                                      : Colors.black87),
                            ),
                            Text(
                              '${car.year} • ${car.licensePlate}',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFuelDetailsCard() {
    return _buildCard(
      title: 'تفاصيل الوقود',
      icon: Icons.local_gas_station,
      color: const Color(0xFFE53935),
      child: Column(
        children: [
          // المبلغ الإجمالي
          _buildField(
            controller: _amountController,
            label: 'المبلغ الإجمالي ($_prefs_currency)',
            icon: Icons.attach_money,
            hint: 'من الرسالة البنكية',
            validator: (v) => v == null || v.isEmpty ? 'أدخل المبلغ' : null,
          ),
          // سعر اللتر
          _buildField(
            controller: _pricePerLiterController,
            label: 'سعر اللتر',
            icon: Icons.price_change,
            hint: 'مثال: 14.50',
          ),
          // عدد اللترات (محسوب تلقائياً)
          _buildField(
            controller: _litersController,
            label: 'الكمية (لتر) — محسوبة تلقائياً',
            icon: Icons.water_drop,
            hint: 'ستُحسب من المبلغ والسعر',
          ),
          // خزان ممتلئ؟
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: _isFullTank,
                onChanged: (v) => setState(() => _isFullTank = v),
                activeColor: const Color(0xFF43A047),
              ),
              Text('خزان ممتلئ؟',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOdometerCard() {
    return _buildCard(
      title: 'قراءة العداد',
      icon: Icons.speed,
      color: const Color(0xFF7B1FA2),
      child: _buildField(
        controller: _odometerController,
        label: 'قراءة العداد (كم)',
        icon: Icons.speed,
        hint: 'العداد الحالي للسيارة',
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(((0.06) * 255).round()),
              blurRadius: 15,
              offset: const Offset(0, 5))
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
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
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
