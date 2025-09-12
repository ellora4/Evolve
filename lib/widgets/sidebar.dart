import 'package:flutter/material.dart';
import 'profile.dart';
import 'favoritemaps.dart';
import 'settings.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF512F), Color(0xFFFF9966), Color(0xFFFFC837)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage("assets/avatar.png"),
                  backgroundColor: Colors.white,
                ),
                title: const Text(
                  'Your Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'My Account',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              _navItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                page: const ProfilePage(),
              ),
              _navItem(
                context,
                icon: Icons.map,
                label: 'Favorite',
                page: const MapsPage(),
              ),
              _navItem(
                context,
                icon: Icons.settings,
                label: 'Settings',
                page: const SettingsPage(),
              ),

              const Divider(color: Colors.white70),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, "/login");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context,
      {required IconData icon, required String label, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(label, style: const TextStyle(color: Colors.white)),
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
