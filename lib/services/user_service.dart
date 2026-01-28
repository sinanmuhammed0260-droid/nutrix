import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user document stream (real-time)
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Get user document once
  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Get health profile stream (real-time)
  Stream<DocumentSnapshot> getHealthProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('healthProfile')
        .doc('profile')
        .snapshots();
  }

  // Get health profile once
  Future<DocumentSnapshot> getHealthProfile(String uid) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .collection('healthProfile')
        .doc('profile')
        .get();
  }

  // Get user type
  Future<String?> getUserType(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['userType'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Save scan result
  Future<void> saveScanResult({
    required String uid,
    required String foodName,
    required String status,
    String? imageUrl,
    Map<String, dynamic>? details,
  }) async {
    try {
      final scanData = {
        'foodName': foodName,
        'status': status, // 'safe', 'warning', 'unsafe'
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      if (imageUrl != null) {
        scanData['imageUrl'] = imageUrl;
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scans')
          .add(scanData);

      // Update user's last scan time
      await _firestore.collection('users').doc(uid).update({
        'lastScanAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error saving scan result: ${e.toString()}';
    }
  }

  // Get recent scans stream (real-time)
  Stream<QuerySnapshot> getRecentScansStream(String uid, {int limit = 10}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get recent scans once
  Future<QuerySnapshot> getRecentScans(String uid, {int limit = 10}) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw 'Error updating profile: ${e.toString()}';
    }
  }

  // Check if health profile is completed
  Future<bool> isHealthProfileCompleted(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('healthProfile')
          .doc('profile')
          .get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }
}
