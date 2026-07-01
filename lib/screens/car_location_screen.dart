import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../services/car_location_service.dart';

class CarLocationScreen extends StatefulWidget {
  final CarModel car;
  const CarLocationScreen({super.key, required this.car});

  @override
  State<CarLocationScreen> createState() => _CarLocationScreenState();
}

class _CarLocationScreenState extends State<CarLocationScreen> {
  Map<String, dynamic>? _savedLocation;
  bool _loading = false;
  bool _initialLoading = true;

  static const _primaryColor = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final loc = await CarLocationService.getSavedLocation(widget.car.carId);
    if (mounted) {
      setState(() {
        _savedLocation = loc;
        _initialLoading = false;
      });
    }
  }

  Future<void> _saveCurrent() async {
    setState(() => _loading = true);
    final success = await CarLocationService.saveCarLocation(widget.car.carId);
    if (success) await _loadSaved();
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم حفظ مكان العربية ✅'
                : 'تعذّر الحصول على الموقع، تأكد من تفعيل خدمة الموقع',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.right,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
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
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text('أين عربيتي؟ 🚗',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _primaryColor.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_car_filled,
                        size: 64, color: _primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${widget.car.make} ${widget.car.model}',
                    style: GoogleFonts.cairo(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 24),
                  if (_savedLocation != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('آخر موقع محفوظ',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(width: 6),
                              const Icon(Icons.location_on,
                                  color: _primaryColor, size: 18),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_savedLocation!["lat"].toStringAsFixed(5)}, '
                            '${_savedLocation!["lng"].toStringAsFixed(5)}',
                            style: GoogleFonts.cairo(
                                color: Colors.grey[700], fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                          if (_savedLocation!['time'] is DateTime) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy - hh:mm a', 'ar')
                                  .format(_savedLocation!['time'] as DateTime),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[500], fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            CarLocationService.openCarInMaps(widget.car.carId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: Text('فتح الموقع في Google Maps',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'مفيش موقع محفوظ للعربية لسه.\nاحفظ موقعها الحالي وأنت تركنها.',
                      style: GoogleFonts.cairo(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _saveCurrent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(
                        _savedLocation == null
                            ? 'حفظ مكان العربية الحالي'
                            : 'تحديث مكان العربية',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
