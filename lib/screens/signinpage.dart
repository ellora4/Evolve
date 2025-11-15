import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcomepage.dart';
import 'package:evolve/services/auth_service.dart';
import 'package:evolve/services/user_profile_service.dart';
import 'package:evolve/widgets/google_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signupEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      final name = _nameController.text.trim();
      if (user != null) {
        await user.updateDisplayName(name);
        await UserProfileService.ensureUserDocument(
          user,
          nameOverride: name,
          emailOverride: email,
        );
        await user.sendEmailVerification();
      }
      // Send verification email and return to root so AuthGate shows VerifyEmailPage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Verification email sent. Please verify.')),
        );
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        if (mounted) {
          const text =
              'Email already in use. If you previously used Google for this email, tap "Continue with Google" on the Welcome screen, then add a password from Settings.';
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text(text)));
        }
      } else {
        final msg = switch (e.code) {
          'invalid-email' => 'Invalid email.',
          'weak-password' => 'Password too weak (min 6).',
          _ => 'Sign-up failed: ${e.code}',
        };
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupGoogle() async {
    try {
      final cred = await AuthService.signInWithGoogle(allowSilent: false);
      if (!mounted) return;
      if (cred == null) return; // user cancelled picker
      // Back to root so AuthGate decides next screen
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final code = e.code;
      final msg = switch (code) {
        'account-exists-with-different-credential' =>
          'Use your existing sign-in method, then link Google in settings.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => 'Google sign-in failed: $code',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomePage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(height: 150, child: Image.asset("assets/logonobg.png")),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildField(
                          _nameController,
                          Icons.person,
                          "Name",
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Enter your name"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          _emailController,
                          Icons.email,
                          "Email Address",
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Enter email";
                            if (!v.contains("@")) return "Enter valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          _passwordController,
                          Icons.lock,
                          "Password",
                          isPassword: true,
                          obscure: _obscure1,
                          onToggle: () =>
                              setState(() => _obscure1 = !_obscure1),
                          validator: (v) => (v == null || v.length < 6)
                              ? "Password must be 6+ chars"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          _confirmController,
                          Icons.lock,
                          "Confirm Password",
                          isPassword: true,
                          obscure: _obscure2,
                          onToggle: () =>
                              setState(() => _obscure2 = !_obscure2),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Re-enter password";
                            }
                            if (v != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _loading ? null : _signupEmail,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text(
                                    "SIGN UP",
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('or',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        GoogleButton(
                          onPressed: _signupGoogle,
                          text: 'Sign up with Google',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    IconData icon,
    String hint, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: isPassword ? obscure : false,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.deepOrange,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
