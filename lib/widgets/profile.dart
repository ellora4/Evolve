import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _loadingProfile = true;
  bool _saving = false;
  bool _profileExists = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loadingProfile = false;
      return;
    }

    _nameController.text = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!
        : 'User';
    _emailController.text = user.email ?? '(no email)';
    _loadProfileFromFirestore(user.uid);
  }

  Future<void> _loadProfileFromFirestore(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      _profileExists = doc.exists;
      final data = doc.data();
      if (data != null) {
        final name = data['name'] as String?;
        final email = data['email'] as String?;
        final bio = data['bio'] as String?;
        final phone = data['phone'] as String?;

        if (name != null && name.trim().isNotEmpty) {
          _nameController.text = name;
        }
        if (email != null && email.trim().isNotEmpty) {
          _emailController.text = email;
        }
        _bioController.text = bio ?? '';
        _phoneController.text = phone ?? '';
      }
      setState(() {
        _loadingProfile = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load profile: $err')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save changes.')),
      );
      return;
    }
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final trimmedName = _nameController.text.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
        await user.reload();
      }

      final data = {
        'name': trimmedName,
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!_profileExists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );
      _profileExists = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } on FirebaseAuthException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.message ?? 'Unable to save profile at the moment.'),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save profile: $err')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label, {bool readOnly = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: readOnly ? Colors.transparent : const Color(0xFFE0E0E0),
      ),
    );

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFB6A6A6)),
      ),
      disabledBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (_, value, __) {
            final letter = value.text.trim().isNotEmpty
                ? value.text.trim()[0].toUpperCase()
                : 'U';
            return CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFB6A6A6),
              child: Text(
                letter,
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (_, value, __) {
              final displayName =
                  value.text.trim().isNotEmpty ? value.text : 'User';
              return Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF7B7B7B),
                ),
                softWrap: true,
                maxLines: 2,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF7B7B7B),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration('Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: _fieldDecoration('Email', readOnly: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: _fieldDecoration('Bio'),
                    enabled: !_loadingProfile,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration('Phone Number'),
                    enabled: !_loadingProfile,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _saving || _loadingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6A6A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text(
                '\u2190 go back',
                style: TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
