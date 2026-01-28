import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current logged-in user
  User? get currentUser => _auth.currentUser;

  /// Auth state listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // 1. SIGN IN WITH EMAIL & PASSWORD
  // ---------------------------------------------------------------------------
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SIGN UP WITH EMAIL & PASSWORD
  // ---------------------------------------------------------------------------
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String userType, // user / doctor / admin
    String? name,
    String? licenseNumber,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = result.user;
      if (user == null) {
        throw 'User creation failed.';
      }

      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': email.trim(),
        'userType': userType,
        'role': userType, // kept for backward compatibility
        'displayName': name ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (userType == 'doctor' && licenseNumber != null) {
        userData['licenseNumber'] = licenseNumber;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData);

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Registration failed. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GET USER TYPE (ROLE)
  // ---------------------------------------------------------------------------
  Future<String?> getUserType(String uid) async {
    try {
      final doc =
      await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['userType'] as String?;
    } catch (e) {
      // Important for debugging login routing
      print('Error fetching user type: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. SIGN IN WITH GOOGLE
  // ---------------------------------------------------------------------------
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result =
      await _auth.signInWithCredential(credential);

      final user = result.user;
      if (user == null) return result;

      final userRef =
      _firestore.collection('users').doc(user.uid);

      final userDoc = await userRef.get();

      // Create Firestore record only if user is new
      if (!userDoc.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'userType': 'user',
          'role': 'user',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // 5. SIGN OUT
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}