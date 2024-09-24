import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() ?? {};
    }
    return {};
  }

  Future<void> updateUserProfile(String displayName, String bio, String? photoURL) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'bio': bio,
        if (photoURL != null) 'photoURL': photoURL,
      });
    }
  }

  Future<Map<String, dynamic>> getPrivacySettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      return {
        'profilePublic': data['profilePublic'] ?? true,
        'showReadingActivity': data['showReadingActivity'] ?? true,
      };
    }
    return {};
  }

  Future<void> updatePrivacySetting(String setting, bool value) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        setting: value,
      });
    }
  }

  Future<void> updateReadingProgress(int pagesRead) async {
    final user = _auth.currentUser;
    if (user != null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore.collection('users').doc(user.uid).update({
        'readingProgress.$today': FieldValue.increment(pagesRead),
      });
    }
  }

  Stream<DocumentSnapshot> getUserStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    throw Exception('User not logged in');
  }
}