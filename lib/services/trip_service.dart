import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTrip(TripModel trip) async {
    await _firestore.collection('trips').doc(trip.tripId).set(trip.toMap());
  }

  /// يحفظ رحلة منتهية ويحدّث عداد السيارة بشكل آمن (Transaction).
  ///
  /// بدل ما نعتمد على قيمة العداد اللي كانت موجودة وقت بداية الرحلة
  /// (ممكن تكون قديمة لو سواق تاني حدّث العداد في نفس الوقت)، بنقرا
  /// القيمة الحالية الفعلية من Firestore لحظة الحفظ، ونزود عليها مسافة
  /// الرحلة، وبنكتب النتيجة كـ "all-or-nothing" — يعني مفيش احتمال
  /// إن العداد "يرجع لورا" بسبب تعارض بين سواقين.
  ///
  /// يرجّع (startOdometer, endOdometer) الفعليين بعد الحساب، عشان
  /// تُعرض في ملخص الرحلة.
  Future<(double startOdometer, double endOdometer)> saveCompletedTrip({
    required String tripId,
    required String carId,
    required String driverId,
    required String driverName,
    required double distanceKm,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final carRef = _firestore.collection('cars').doc(carId);
    final tripRef = _firestore.collection('trips').doc(tripId);

    return _firestore.runTransaction<(double, double)>((transaction) async {
      final carSnap = await transaction.get(carRef);
      final liveOdometer =
          ((carSnap.data()?['currentOdometer'] ?? 0) as num).toDouble();
      final newOdometer = liveOdometer + distanceKm;

      final trip = TripModel(
        tripId: tripId,
        carId: carId,
        driverId: driverId,
        driverName: driverName,
        startOdometer: liveOdometer,
        endOdometer: newOdometer,
        distanceKm: distanceKm,
        startTime: startTime,
        endTime: endTime,
        status: 'completed',
      );

      transaction.set(tripRef, trip.toMap());
      transaction.update(carRef, {'currentOdometer': newOdometer});

      return (liveOdometer, newOdometer);
    });
  }

  Stream<List<TripModel>> getCarTrips(String carId) {
    return _firestore
        .collection('trips')
        .where('carId', isEqualTo: carId)
        .snapshots()
        .map((snap) {
      final trips = snap.docs
          .map((d) => TripModel.fromMap(d.data()))
          .where((t) => t.status == 'completed')
          .toList();
      trips.sort((a, b) =>
          (b.startTime ?? DateTime(0)).compareTo(a.startTime ?? DateTime(0)));
      return trips;
    });
  }

  Future<void> deleteTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).delete();
  }
}
