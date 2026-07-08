import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/car_model.dart';

// ══════════════════════════════════════
//  DASHBOARD HEADER
// ══════════════════════════════════════
class CarDashboardHeader extends StatelessWidget {
  final CarModel car;
  final int healthScore;
  final int overdueCount;
  final int dueSoonCount;
  final int okCount;
  final int total;

  const CarDashboardHeader({
    super.key,
    required this.car,
    required this.healthScore,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.okCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = healthScore >= 80
        ? Colors.green
        : healthScore >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Stack(
        children: [
          // دوائر زخرفية
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withAlpha(10),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Health score دائري
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: CircularProgressIndicator(
                                value: healthScore / 100,
                                strokeWidth: 7,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(healthColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$healthScore',
                                  style: GoogleFonts.cairo(
                                    color: healthColor,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('%',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('حالة السيارة',
                          style: GoogleFonts.cairo(
                              color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      if (total > 0)
                        Row(
                          children: [
                            if (overdueCount > 0)
                              _miniChip('$overdueCount', Colors.red),
                            if (dueSoonCount > 0) ...[
                              if (overdueCount > 0) const SizedBox(width: 4),
                              _miniChip('$dueSoonCount', Colors.orange),
                            ],
                            if (okCount > 0) ...[
                              if (overdueCount > 0 || dueSoonCount > 0)
                                const SizedBox(width: 4),
                              _miniChip('$okCount', Colors.green),
                            ],
                          ],
                        ),
                    ],
                  ),
                  // معلومات السيارة
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_capitalize(car.make)} ${_capitalize(car.model)}',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${car.year} • ${car.licensePlate}',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF38BDF8), fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withAlpha(25), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${car.currentOdometer.toStringAsFixed(0)} كم',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.speed_rounded,
                                color: Color(0xFF38BDF8), size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(64),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}