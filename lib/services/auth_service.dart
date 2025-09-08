import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _google = GoogleSignIn(scopes: ['email']);

  /// Sign in with Google. If [allowSilent] is true, tries a background
  /// sign-in first (no account picker) and falls back to the picker.
  static Future<UserCredential?> signInWithGoogle({bool allowSilent = true}) async {
    GoogleSignInAccount? acc;
    if (allowSilent) {
      try {
        acc = await _google.signInSilently(reAuthenticate: true);
      } catch (_) {/* ignore */}
    }
    acc ??= await _google.signIn();        // null if user cancels
    if (acc == null) return null;

    final auth = await acc.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: auth.idToken, accessToken: auth.accessToken,
    );

    try {
      return await FirebaseAuth.instance.signInWithCredential(cred);
    } on FirebaseAuthException {
      // If the email already exists with another provider, you can link:
      // if (e.code == 'account-exists-with-different-credential') { ... }
      rethrow;
    }
  }

  /// Link the currently signed-in Firebase user with Google (optional helper).
  static Future<UserCredential?> linkWithGoogle() async {
    final acc = await _google.signIn();
    if (acc == null) return null;
    final auth = await acc.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: auth.idToken, accessToken: auth.accessToken,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.linkWithCredential(cred);
  }

  /// Full sign-out (Firebase + Google session).
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try { await _google.signOut(); } catch (_) {/* ignore */}
  }

  /// Quick check if a Google account is cached on device.
  static Future<bool> isGoogleSignedIn() => _google.isSignedIn();
}
