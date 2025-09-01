import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'signinpage.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              "assets/mountain.png",
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: Image.asset(
              "assets/logonobg.png",
              height: 150,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavButton(
                    context,
                    label: "LOG IN",
                    page: const LoginPage(),
                  ),
                  const SizedBox(width: 20),
                  Container(height: 16, width: 2, color: Colors.white),
                  const SizedBox(width: 20),
                  _buildNavButton(
                    context,
                    label: "SIGN UP",
                    page: const SignUpPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context,
      {required String label, required Widget page}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
