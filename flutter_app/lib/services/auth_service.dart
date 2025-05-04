import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Huidige gebruiker ophalen
  User? get currentUser => _auth.currentUser;

  // Stream van auth veranderingen
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registreer met email en wachtwoord
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      // Eerst de gebruiker aanmaken in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Probeer gebruikersdocument aan te maken in Firestore
      try {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        // Log de specifieke Firestore fout voor debugging
        print('Firestore error: $firestoreError');
        
        // We gaan hier geen exception throwen, omdat de authenticatie wel is gelukt
        // We kunnen later opnieuw proberen het gebruikersprofiel aan te maken
      }
      
      return result;
    } catch (authError) {
      // Hier gooien we de fout voor authenticatie problemen
      rethrow;
    }
  }

  // Inloggen met email en wachtwoord
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Uitloggen
  Future<void> signOut() async {
    return await _auth.signOut();
  }
  
  // Gebruikersprofiel ophalen
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }
  
  // Gebruikersprofiel aanmaken/updaten
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}