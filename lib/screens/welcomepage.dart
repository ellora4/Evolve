import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'signinpage.dart';
import 'homepage.dart';
import 'package:evolve/widgets/primary_button.dart';
import 'package:evolve/widgets/google_button.dart';
import 'package:evolve/services/auth_service.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _google(BuildContext context) async {
    try {
      final res = await AuthService.signInWithGoogle();
      if (res == null) return; // cancelled
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top hero section (logo only)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 255, 255, 255), // near black
                        Color.fromARGB(255, 255, 255, 255), // deep navy
                      ],
                    ),
                  ),
                ),
                // Replace headline with app logo
                SafeArea(
                  child: Center(
                    child: Image.asset(
                      'assets/logonobg.png',
                      height: 140,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  // Mountain background inside the sheet
                  Positioned.fill(
                    child: Opacity(
                      opacity: 1,
                      child: Image.asset(
                        'assets/mountain.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome to Evolve',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GoogleButton(
                          onPressed: () => _google(context),
                          text: 'Sign Up with Google',
                        ),
                        const SizedBox(height: 16),
                        _OrDivider(),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Sign Up with Email',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _LoginHint(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1.2, color: Color(0x33000000))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
        Expanded(child: Divider(thickness: 1.2, color: Color(0x33000000))),
      ],
    );
  }
}

class _LoginHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF1A73E8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
