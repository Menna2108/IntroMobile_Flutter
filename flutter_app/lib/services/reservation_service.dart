import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'reservations';

  // Maak een nieuwe reservering aan
  Future<String> addReservation(Reservation reservation) async {
    try {
      final docRef = await _firestore.collection(collection).add(reservation.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Haal reserveringen op voor een specifieke huurder
  Stream<List<Reservation>> getRenterReservations(String renterId) {
    return _firestore
        .collection(collection)
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Haal reserveringen op voor een specifieke eigenaar
  Stream<List<Reservation>> getOwnerReservations(String ownerId) {
    return _firestore
        .collection(collection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update de status van een reservering
  Future<void> updateReservationStatus(String id, String status) async {
    try {
      await _firestore.collection(collection).doc(id).update({'status': status});
    } catch (e) {
      rethrow;
    }
  }
}