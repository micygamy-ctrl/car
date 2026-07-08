import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/car_part_model.dart';

// ══════════════════════════════════════
//  PART CARD
// ══════════════════════════════════════
class PartStatusCard extends StatelessWidget {
  final CarPartModel part;
  final double currentOdometer;
  final VoidCallback onLongPress;

  const PartStatusCard({
    super.key,
    required this.part,
    required this.currentOdometer,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = part.status(currentOdometer);
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (status) {
      case PartStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        statusText = 'متأخر!';
        break;
      case PartStatus.dueSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusText = 'قريب';
        break;
      case PartStatus.ok:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'تمام';
        break;
    }

    final km = part.kmRemaining(currentOdometer);
    final days = part.daysRemaining();
    String remainingText = '';
    if (km != null) {
      remainingText = km <= 0
          ? 'تجاوز ${(-km).toStringAsFixed(0)} كم'
          : 'باقي ${km.toStringAsFixed(0)} كم';
    } else if (days != null) {
      remainingText = days < 0
          ? 'تجاوز ${(-days)} يوم'
          : days == 0
              ? 'ينتهي اليوم!'
              : 'باقي $days يوم';
    }

    final prog = part.progress(currentOdometer);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status != PartStatus.ok
                ? statusColor.withAlpha(76)
                : Colors.grey.withAlpha(26),
            width: status != PartStatus.ok ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge الحالة
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: GoogleFonts.cairo(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
                // اسم القطعة
                Text(
                  part.name,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: status == PartStatus.overdue
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // شريط التقدم
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prog,
                backgroundColor: Colors.grey.withAlpha(38),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remainingText,
                  style: GoogleFonts.cairo(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (part.nextDueOdometer != null)
                  Text(
                    'عند ${part.nextDueOdometer!.toStringAsFixed(0)} كم',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
                  )
                else if (part.nextDueDate != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(part.nextDueDate!),
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}