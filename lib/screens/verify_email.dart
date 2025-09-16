import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _sending = false;
  bool _checking = false;

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _iVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _checking = true);
    try {
      await user.reload();
      var fresh = FirebaseAuth.instance.currentUser;
      if (!(fresh?.emailVerified ?? false)) {
        // Give the backend a brief moment to propagate verification
        await Future.delayed(const Duration(seconds: 2));
        await FirebaseAuth.instance.currentUser?.reload();
        fresh = FirebaseAuth.instance.currentUser;
      }
      if (fresh != null && fresh.emailVerified) {
        if (!mounted) return;
        // Pop back to root so AuthGate rebuilds to Home
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent a verification link to:\n$email',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Please open the link in your inbox, then come back.'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _resend,
                    child: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checking ? null : _iVerified,
                    child: _checking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("I've verified"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
