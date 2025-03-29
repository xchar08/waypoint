import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks the current authentication state of the user.
  /// Returns `true` if the user is authenticated, `false` otherwise.
  /// This method is asynchronous to ensure the latest auth state is retrieved.
  Future<bool> handleAuthState() async {
    // Use authStateChanges() to get the latest authentication state.
    // The .first property ensures we only get the current state and then close the stream.
    final user = await _auth.authStateChanges().first;
    return user != null;
  }

  /// Provides a stream of authentication state changes.
  /// This can be used to listen for real-time updates to the user's auth state.
  Stream<bool> get authStateChanges => _auth.authStateChanges().map((user) => user != null);

  /// Signs in a user with the provided email and password.
  /// Throws a [FirebaseAuthException] with a specific code and message if the sign-in fails.
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception with a more user-friendly message
      switch (e.code) {
        case 'user-not-found':
          throw FirebaseAuthException(
            code: e.code,
            message: 'No user found with this email.',
          );
        case 'wrong-password':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Incorrect password. Please try again.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: e.code,
            message: 'The email address is not valid.',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: e.code,
            message: 'This user account has been disabled.',
          );
        default:
          throw FirebaseAuthException(
            code: e.code,
            message: e.message ?? 'An error occurred during sign-in.',
          );
      }
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Signs up a new user with the provided email and password.
  /// Optionally sets the user's display name after successful sign-up.
  /// Throws a [FirebaseAuthException] with a specific code and message if the sign-up fails.
  Future<void> signUp(String email, String password, {String? displayName}) async {
    try {
      // Create the user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If a display name is provided, update the user's profile
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        // Refresh the user to ensure the display name is updated
        await userCredential.user!.reload();
      }
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception with a more user-friendly message
      switch (e.code) {
        case 'email-already-in-use':
          throw FirebaseAuthException(
            code: e.code,
            message: 'This email is already in use by another account.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: e.code,
            message: 'The email address is not valid.',
          );
        case 'weak-password':
          throw FirebaseAuthException(
            code: e.code,
            message: 'The password is too weak. Please use a stronger password.',
          );
        default:
          throw FirebaseAuthException(
            code: e.code,
            message: e.message ?? 'An error occurred during sign-up.',
          );
      }
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns the current user's ID if authenticated, otherwise returns null.
  String? getUserId() => _auth.currentUser?.uid;

  /// Returns the current user's display name if authenticated, otherwise returns null.
  String? getDisplayName() => _auth.currentUser?.displayName;
}