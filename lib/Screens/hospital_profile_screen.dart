import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  String name = '';
  String contactNumber = '';
  String address = '';
  String city = '';
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHospitalData();
  }

  Future<void> fetchHospitalData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          name = data['name'] ?? '';
          contactNumber = data['contactNumber'] ?? '';
          address = data['address'] ?? '';
          city = data['city'] ?? '';

          // Pre-fill controllers
          nameController.text = name;
          contactController.text = contactNumber;
          addressController.text = address;
          cityController.text = city;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_formKey.currentState!.validate() && uid != null) {
      await FirebaseFirestore.instance.collection('hospitals').doc(uid).update({
        'name': nameController.text.trim(),
        'contactNumber': contactController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
      });

      setState(() {
        name = nameController.text.trim();
        contactNumber = contactController.text.trim();
        address = addressController.text.trim();
        city = cityController.text.trim();
        isEditing = false;
      });
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst); // Go back to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: const Text(
          'Hospital Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: signOut,
          ),
        ],
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isEditing ? buildEditForm() : buildProfileView(),
      ),
      floatingActionButton: !isEditing
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => isEditing = true),
              label: const Text("Edit Profile"),
              icon: const Icon(Icons.edit),
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color.fromARGB(255, 255, 17, 0),
                  width: 1.5,
                ),
              ),
            )
          : null,
    );
  }

  Widget buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _profileItem("Name", name),
        _profileItem("Contact", contactNumber),
        _profileItem("Address", address),
        _profileItem("City", city),
      ],
    );
  }

  Widget buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _formField("Name", nameController),
          _formField("Contact Number", contactController),
          _formField("Address", addressController),
          _formField("City", cityController),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color.fromARGB(255, 255, 17, 0),
                  width: 1.5,
                ),
              ),
            ),
            child: const Text("Save"),
          ),
          TextButton(
            onPressed: () => setState(() => isEditing = false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }

  Widget _formField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
