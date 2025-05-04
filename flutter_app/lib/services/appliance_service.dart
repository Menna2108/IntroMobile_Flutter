import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance.dart';

class ApplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'appliances';

  // Voeg een nieuw apparaat toe
  Future<String> addAppliance(Appliance appliance) async {
    try {
      final docRef = await _firestore.collection(collection).add(appliance.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Haal alle apparaten op
  Stream<List<Appliance>> getAppliances() {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appliance.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Haal apparaten op van een specifieke gebruiker
  Stream<List<Appliance>> getUserAppliances(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appliance.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Apparaat bijwerken
  Future<void> updateAppliance(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Apparaat verwijderen
  Future<void> deleteAppliance(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Zoeken naar apparaten op basis van titel of beschrijving
  Stream<List<Appliance>> searchAppliances(String query) {
    return _firestore
        .collection(collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff']) // Unicode karakter voor "end of string"
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appliance.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Haal apparaten op in een specifieke categorie
  Stream<List<Appliance>> getAppliancesByCategory(String category) {
    return _firestore
        .collection(collection)
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appliance.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}