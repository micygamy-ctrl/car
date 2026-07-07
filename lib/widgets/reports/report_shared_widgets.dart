import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/fuel_log_model.dart';
import '../../models/maintenance_log_model.dart';

// ═══════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════
class ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget chart;
  final String? subtitle;

  const ChartCard(
      {required this.title,
      required this.color,
      required this.chart,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
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
              if (subtitle != null)
                Text(subtitle!,
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
              if (subtitle != null) const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}

class StatData {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const StatData(this.label, this.value, this.unit, this.icon, this.color);
}

Widget statsGrid(List<StatData> stats) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.45,
    children: stats.map((s) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(s.icon, color: s.color, size: 22),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: s.value,
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: s.color)),
                if (s.unit.isNotEmpty)
                  TextSpan(
                      text: ' ${s.unit}',
                      style:
                          GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            Text(s.label,
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.right),
          ],
        ),
      );
    }).toList(),
  );
}

Widget sectionHeader(String title, IconData icon, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 6),
      Icon(icon, color: color, size: 18),
    ],
  );
}

Widget emptyState(String msg, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.withAlpha(102)),
        const SizedBox(height: 12),
        Text(msg,
            style: GoogleFonts.cairo(
                fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class FuelRow extends StatelessWidget {
  final FuelLogModel log;
  const FuelRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${log.totalCost.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: const Color(0xFFE53935))),
          Row(children: [
            Text('${log.fuelAmount} لتر',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yy').format(log.date),
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class MaintenanceRow extends StatelessWidget {
  final ServiceLogModel log;
  const MaintenanceRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${log.cost.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: const Color(0xFF43A047))),
          Text(log.title,
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}