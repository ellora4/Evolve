import 'package:flutter/material.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maps"),
        backgroundColor: const Color.fromARGB(255, 228, 204, 96),
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Map not available",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
