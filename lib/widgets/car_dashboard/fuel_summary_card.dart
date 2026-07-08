import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/fuel_log_model.dart';

// ══════════════════════════════════════
//  FUEL SUMMARY
// ══════════════════════════════════════
class FuelSummaryCard extends StatelessWidget {
  final FuelLogModel last;
  final List<FuelLogModel> all;
  final VoidCallback onTap;

  const FuelSummaryCard({
    super.key,
    required this.last,
    required this.all,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // حساب متوسط الاستهلاك من آخر 5 سجلات
    double? avgEff;
    final withEff =
        all.where((l) => l.calculatedEfficiency != null).take(5).toList();
    if (withEff.isNotEmpty) {
      avgEff =
          withEff.map((l) => l.calculatedEfficiency!).reduce((a, b) => a + b) /
              withEff.length;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                    Text('كل السجلات',
                        style: GoogleFonts.cairo(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(last.date),
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _fuelStat('${last.totalCost.toStringAsFixed(0)} ج.م', 'التكلفة',
                    Icons.attach_money, Colors.red),
                _fuelStat('${last.fuelAmount} لتر', 'الكمية',
                    Icons.local_gas_station, const Color(0xFFFB8C00)),
                _fuelStat('${last.odometer.toStringAsFixed(0)} كم', 'العداد',
                    Icons.speed, Colors.blue),
                if (avgEff != null)
                  _fuelStat('${avgEff.toStringAsFixed(1)}', 'ل/100كم',
                      Icons.show_chart, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fuelStat(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}