import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evolve/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
  final displayName = user?.displayName ?? 'User';
    final providers = user?.providerData.map((p) => p.providerId).toSet() ?? {};
    final hasGoogle = providers.contains('google.com');
    final hasPassword = providers.contains('password');

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          // Avatar and Name
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFB6A6A6),
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : '',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF7B7B7B),
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color(0xFF7B7B7B),
            ),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          // General Section
          const Text(
            'General',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              if (hasPassword && user?.email != null) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bind Account', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              if (!hasGoogle) {
                try {
                  await AuthService.linkWithGoogle();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google linked.')),
                  );
                  setState(() {});
                } on FirebaseAuthException catch (e) {
                  final msg = e.code == 'credential-already-in-use'
                      ? 'That Google account is already linked elsewhere.'
                      : 'Failed: ${e.code}';
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeThumbColor: const Color(0xFFB6A6A6),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          // Feedback Section
          const Text(
            'Feedback',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Report Issues', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          // Log out
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          const Divider(thickness: 1),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('← go back', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
