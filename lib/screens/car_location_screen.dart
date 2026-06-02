import 'package:flutter/material.dart';
import '../services/car_location_service.dart';


class CarLocationScreen extends StatefulWidget {
  const CarLocationScreen({super.key});
  @override
  State<CarLocationScreen> createState() => _CarLocationScreenState();
}

class _CarLocationScreenState extends State<CarLocationScreen> {
  Map<String, dynamic>? _savedLocation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final loc = await CarLocationService.getSavedLocation();
    setState(() => _savedLocation = loc);
  }

  Future<void> _saveCurrent() async {
    setState(() => _loading = true);
    final success = await CarLocationService.saveCarLocation();
    if (success) await _loadSaved();
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '✅ تم حفظ مكان العربية!' : '❌ مشكلة في اللوكيشن')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أين عربيتي؟')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car, size: 80, color: Colors.blue),
            const SizedBox(height: 24),

            if (_savedLocation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Text('📍 آخر موقع محفوظ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_savedLocation!["lat"]?.toStringAsFixed(5)}, '
                         '${_savedLocation!["lng"]?.toStringAsFixed(5)}'),
                    Text(_savedLocation!['time'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: CarLocationService.openCarInMaps,
                icon: const Icon(Icons.map),
                label: const Text('أين عربيتي؟ 🗺️'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton.icon(
              onPressed: _loading ? null : _saveCurrent,
              icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_alt),
              label: Text(_savedLocation == null
                ? 'حفظ مكان العربية الحالي'
                : 'تحديث مكان العربية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}