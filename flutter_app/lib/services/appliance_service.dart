import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance.dart';

class ApplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'appliances';

  Future<String> addAppliance(Appliance appliance) async {
    try {
      final docRef = await _firestore.collection(collection).add(appliance.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> updateAppliance(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAppliance(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserAppliancesUserName(String userId, String newUserName) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        await _firestore.collection(collection).doc(doc.id).update({
          'userName': newUserName,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Appliance>> searchAppliances(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    
    if (normalizedQuery.isEmpty) {
      return _firestore
          .collection(collection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Appliance.fromMap(doc.data(), doc.id))
            .toList();
      });
    }

    return _firestore
        .collection(collection)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final appliances = snapshot.docs
          .map((doc) => Appliance.fromMap(doc.data(), doc.id))
          .toList();
      return appliances.where((appliance) {
        return appliance.title.toLowerCase().contains(normalizedQuery) ||
               appliance.description.toLowerCase().contains(normalizedQuery) ||
               appliance.userName.toLowerCase().contains(normalizedQuery);
      }).toList();
    });
  }

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