import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> getFriendsList(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['friends'] ?? []);
    }
    return [];
  }

  Future<String?> getUserEmail(String userId) async {
    final user = _auth.currentUser;
    return user?.email;
  }

  Future<String?> getUserCity(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['city'] as String?;
    }
    return null;
  }

  Future<String> getUserDisplayName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['displayName'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }
}