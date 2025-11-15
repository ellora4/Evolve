import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  UserProfileService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Ensure the `/users/{uid}` document exists and has basic fields.
  static Future<void> ensureUserDocument(
    User user, {
    String? nameOverride,
    String? emailOverride,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final name = _pickValue(
      override: nameOverride,
      fallback: user.displayName,
    );
    final email = _pickValue(
      override: emailOverride,
      fallback: user.email,
    );
    final photoUrl = user.photoURL ?? '';

    if (!snapshot.exists) {
      await docRef.set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'bio': '',
        'phone': '',
        'unit': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snapshot.data();
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_shouldBackfill(data?['name'], name)) updates['name'] = name;
    if (_shouldBackfill(data?['email'], email)) updates['email'] = email;
    if (_shouldBackfill(data?['photoUrl'], photoUrl)) {
      updates['photoUrl'] = photoUrl;
    }

    if (updates.isNotEmpty) {
      await docRef.set(updates, SetOptions(merge: true));
    }
  }

  static String _pickValue({String? override, String? fallback}) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    return '';
  }

  static bool _shouldBackfill(dynamic current, String candidate) {
    if (candidate.isEmpty) return false;
    final existing = current is String ? current : '';
    return existing.trim().isEmpty;
  }
}
