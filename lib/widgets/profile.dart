import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
  final displayName = user?.displayName ?? 'User';
  final email = user?.email ?? '(no email)';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFB6A6A6),
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : '',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
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
          // Name
          const Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(displayName, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          // Email
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(email, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          // Bio
          const Text('Bio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
            child: const Text('', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          // Phone Number
          const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: const Text('', style: TextStyle(fontSize: 15, color: Colors.grey)),
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
    );
  }
}
