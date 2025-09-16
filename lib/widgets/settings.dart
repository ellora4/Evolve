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
  String _selectedLanguage = "English";

  final _languages = ["English", "Spanish", "French", "Filipino"];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '(no email)';
    final providers = user?.providerData.map((p) => p.providerId).toSet() ?? {};
    final hasGoogle = providers.contains('google.com');
    final hasPassword = providers.contains('password');
    final emailVerified = user?.emailVerified ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Account
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Email: $email'),
                  Text('Verified: ${emailVerified ? 'Yes' : 'No'}'),
                  const SizedBox(height: 8),
                  if (!hasGoogle)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Link Google account'),
                      onPressed: () async {
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
                      },
                    ),
                  const SizedBox(height: 8),
                  if (hasPassword)
                    OutlinedButton(
                      onPressed: () async {
                        if (user?.email == null) return;
                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: user!.email!);
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
                      },
                      child: const Text('Change password'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        if (user?.email == null) return;
                        final controller1 = TextEditingController();
                        final controller2 = TextEditingController();
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Add password'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: controller1,
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: 'New password (min 6)'),
                                  ),
                                  TextField(
                                    controller: controller2,
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: 'Confirm password'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                        if (ok != true) return;
                        final p1 = controller1.text;
                        final p2 = controller2.text;
                        if (p1.length < 6 || p1 != p2) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords must match and be 6+ chars.')),
                          );
                          return;
                        }
                        try {
                          final cred = EmailAuthProvider.credential(email: user!.email!, password: p1);
                          await user.linkWithCredential(cred);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Password added.')));
                          setState(() {});
                        } on FirebaseAuthException catch (e) {
                          final msg = switch (e.code) {
                            'requires-recent-login' => 'Please sign in again, then retry.',
                            'provider-already-linked' => 'Password already linked.',
                            _ => 'Failed: ${e.code}',
                          };
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                      child: const Text('Add password'),
                    ),
                  if (hasPassword && !emailVerified)
                    TextButton(
                      onPressed: () async {
                        try {
                          await user?.sendEmailVerification();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification email sent.')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                      child: const Text('Resend verification email'),
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: _notificationsEnabled,
            activeThumbColor: Colors.deepOrange,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          ListTile(
            title: const Text("Language"),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: _languages
                  .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),
          ),
        ],
      ),
    );
  }
}
