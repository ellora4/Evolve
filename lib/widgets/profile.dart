import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String _name = "(User)";
  String _email = "(user@gmail.com)";
  String _bio = "(This is my bio)";
  String _phone = "(09123456789)";
  String _unit = "(BYD Sealion 5 DM-i)";

  
  String _avatarPath = "assets/avatar.png";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 228, 204, 96),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color.fromARGB(255, 228, 204, 96),
                backgroundImage: AssetImage(_avatarPath),
                // If asset not found, fallback to icon
                onBackgroundImageError: (_, __) => const Icon(
                  Icons.person,
                  size: 90,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: "Name",
                initialValue: _name,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your name" : null,
                onSaved: (value) => _name = value ?? "",
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Email",
                initialValue: _email,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your email" : null,
                onSaved: (value) => _email = value ?? "",
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Bio",
                initialValue: _bio,
                maxLines: 3,
                onSaved: (value) => _bio = value ?? "",
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Phone Number",
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your phone number" : null,
                onSaved: (value) => _phone = value ?? "",
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: "Car Unit",
                initialValue: _unit,
                keyboardType: TextInputType.text,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your unit" : null,
                onSaved: (value) => _unit = value ?? "",
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 228, 204, 96),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated!")),
      );

      setState(() {});
    }
  }
}
