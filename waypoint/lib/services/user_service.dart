import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches the list of friends for a given user ID.
  /// Returns an empty list if the document doesn’t exist or an error occurs.
  Future<List<String>> getFriendsList(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return List<String>.from(data?['friends'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching friends list for user $userId: $e');
      return []; // Return empty list on error to prevent crashes
    }
  }

  /// Gets the current user's email from Firebase Auth.
  /// Returns null if no user is signed in.
  Future<String?> getUserEmail(String userId) async {
    try {
      final user = _auth.currentUser;
      return user?.email;
    } catch (e) {
      print('Error fetching user email: $e');
      return null;
    }
  }

  /// Fetches the user's city based on their email.
  /// Returns null if no matching user is found or an error occurs.
  Future<String?> getUserCity(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['city'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user city for email $email: $e');
      return null;
    }
  }

  /// Fetches the display name for a given user ID.
  /// Returns 'Unknown User' if the document doesn’t exist or an error occurs.
  Future<String> getUserDisplayName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['displayName'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error fetching display name for user $userId: $e');
      return 'Unknown User';
    }
  }
}