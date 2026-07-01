import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';

class TripsHistoryScreen extends StatelessWidget {
  final CarModel car;
  const TripsHistoryScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('رحلات ${car.make} ${car.model}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<TripModel>>(
        stream: TripService().getCarTrips(car.carId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route,
                      size: 80, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'مفيش رحلات لسه',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ رحلتك الأولى من داشبورد السيارة',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // إجماليات
          final totalKm =
              trips.fold<double>(0, (s, t) => s + (t.distanceKm ?? 0));
          final totalMins =
              trips.fold<int>(0, (s, t) => s + t.duration.inMinutes);

          return Column(
            children: [
              // شريط الإجماليات
              Container(
                color: const Color(0xFF1E88E5),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _totalChip(Icons.route, '${totalKm.toStringAsFixed(1)} كم',
                        'إجمالي المسافة'),
                    const SizedBox(width: 12),
                    _totalChip(
                        Icons.directions_car, '${trips.length}', 'عدد الرحلات'),
                    const SizedBox(width: 12),
                    _totalChip(
                        Icons.timer,
                        '${totalMins ~/ 60}س ${totalMins % 60}د',
                        'إجمالي الوقت'),
                  ],
                ),
              ),

              // قائمة الرحلات
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, i) => _TripCard(trip: trips[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _totalChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateStr = trip.startTime != null
        ? DateFormat('dd/MM/yyyy – hh:mm a', 'ar').format(trip.startTime!)
        : '—';
    final mins = trip.duration.inMinutes;
    final secs = trip.duration.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // التاريخ والسواق
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                ),
                if (trip.driverName.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(trip.driverName,
                          style: GoogleFonts.cairo(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // المسافة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route,
                      color: Color(0xFF1E88E5), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(trip.distanceKm ?? 0).toStringAsFixed(2)} كم',
                      style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5)),
                    ),
                    Text(
                      '${mins}د ${secs}ث',
                      style:
                          GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                // العداد
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${trip.startOdometer.toStringAsFixed(0)} ← ${(trip.endOdometer ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'كم (العداد)',
                      style:
                          GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
