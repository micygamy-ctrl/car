import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTrip(TripModel trip) async {
    await _firestore.collection('trips').doc(trip.tripId).set(trip.toMap());
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
