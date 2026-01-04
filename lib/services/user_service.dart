import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /// Ensures /users/{uid} exists. Safe to call any time.
  static Future<void> ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);

    // Using merge: true avoids overwriting existing points
    await ref.set({
      'displayName': user.displayName ?? 'User',
      'photoUrl': user.photoURL ?? '',
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),

      // Ensure leaderboard fields exist as numbers
      'points': FieldValue.increment(0),
      'minutes': FieldValue.increment(0),
    }, SetOptions(merge: true));
  }
}
