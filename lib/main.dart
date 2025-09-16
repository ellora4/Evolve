import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:evolve/screens/welcomepage.dart';
import 'package:evolve/screens/homepage.dart';
import 'package:evolve/screens/verify_email.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // uses google-services.json on Android
  // Localize Firebase Auth emails (and remove X-Firebase-Locale warning)
  try { FirebaseAuth.instance.setLanguageCode('en'); } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFFF29E2E); // brand-ish orange
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Volve',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      // Start on an auth gate so a signed-in user stays signed in
      // across app restarts, and signed-out users see Welcome.
      home: const AuthGate(),
    );
  }
}

/// Shows WelcomePage when signed out; goes to Home when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Use userChanges so profile updates (like emailVerified) refresh UI
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const WelcomePage();
        final providers = user.providerData.map((p) => p.providerId).toList();
        final usesPassword = providers.contains('password');
        if (usesPassword && !(user.emailVerified)) {
          return const VerifyEmailPage();
        }
        return const HomePage();
      },
    );
  }
}

/// You can add global sign-out for testing only like below (commented):
/// if (kDebugMode) await FirebaseAuth.instance.signOut();
