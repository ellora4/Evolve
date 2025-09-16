import 'package:flutter/material.dart';
import 'package:evolve/widgets/sidebar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      // Let body respect notches and the status bar
      body: SafeArea(
        child: Stack(
          children: [
            // Bubble Search Bar pinned to top with padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.grey),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        tooltip: 'Menu',
                      ),
                      // TextField for Search
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Center(
              child: Text(
                "Map",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
