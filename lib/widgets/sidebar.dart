import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'favoritemaps.dart';
import 'settings.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            children: [
              Builder(
                builder: (context) {
                  final user = FirebaseAuth.instance.currentUser;
                  final email = user?.email ?? '(no email)';
                  final displayName = user?.displayName ?? 'User';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFB6A6A6),
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF7B7B7B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              const Text(
                'MENU',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),

              _navItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                page: const ProfilePage(),
                iconColor: Color(0xFF7B7B7B),
                textColor: Color(0xFF7B7B7B),
              ),
              _navItem(
                context,
                icon: Icons.map,
                label: 'Favorite',
                page: const MapsPage(),
                iconColor: Color(0xFF7B7B7B),
                textColor: Color(0xFF7B7B7B),
              ),
              _navItem(
                context,
                icon: Icons.settings,
                label: 'Settings',
                page: const SettingsPage(),
                iconColor: Color(0xFF7B7B7B),
                textColor: Color(0xFF7B7B7B),
              ),
              const Divider(thickness: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context,
      {required IconData icon, required String label, required Widget page, Color iconColor = Colors.grey, Color textColor = Colors.grey}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }
}
