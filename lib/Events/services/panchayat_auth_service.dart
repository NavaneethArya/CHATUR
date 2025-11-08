import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayatAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verify panchayat credentials
  static Future<Map<String, dynamic>?> verifyPanchayatMember(
      String email, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('panchayat_members')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Check if user is panchayat member
  static Future<bool> isPanchayatMember(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('panchayat_members')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Add dummy panchayat member (run once for testing)
  static Future<void> addDummyPanchayatMember() async {
    await _firestore.collection('panchayat_members').add({
      'name': 'Ramesh Kumar',
      'email': 'panchayat@chatur.com',
      'password': 'chatur123', // In production, hash this!
      'role': 'Panchayat Officer',
      'village': 'Sample Village',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}


