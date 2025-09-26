import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comercial_screen.dart'; // ✅ for navigation

class AddBloodScreen extends StatefulWidget {
  const AddBloodScreen({super.key});

  @override
  State<AddBloodScreen> createState() => _AddBloodScreenState();
}

class _AddBloodScreenState extends State<AddBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _donorContactController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedDonationType;

  final List<String> bloodTypes = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];
  final List<String> donationTypes = [
    "Whole Blood",
    "Platelets",
    "Plasma",
    "Red Cells",
  ];

  @override
  void dispose() {
    _donorNameController.dispose();
    _donorContactController.dispose();
    _unitsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // ✅ Get current logged-in hospital/bloodbank
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not logged in")),
          );
          return;
        }

        // ✅ Save to Firestore
        await FirebaseFirestore.instance.collection("blood_inventory").add({
          "donorName": _donorNameController.text.trim(),
          "donorContact": _donorContactController.text.trim(),
          "bloodType": _selectedBloodType,
          "donationType": _selectedDonationType,
          "units": int.tryParse(_unitsController.text.trim()) ?? 0,
          "date": _dateController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "orgEmail": user.email, // ✅ hospital identifier
          "orgId": user.uid,      // ✅ unique id of hospital
        });

        // ✅ Clear form after saving
        _formKey.currentState!.reset();
        _donorNameController.clear();
        _donorContactController.clear();
        _unitsController.clear();
        _dateController.clear();
        setState(() {
          _selectedBloodType = null;
          _selectedDonationType = null;
        });

        // ✅ Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blood added to inventory")),
        );

        // ✅ Redirect to comercial_screen.dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HospitalHomeScreen(name: '',)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) =>
            value == null || value.isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Blood to Inventory",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: "Donor Name",
                controller: _donorNameController,
              ),
              _buildTextField(
                label: "Donor Contact",
                controller: _donorContactController,
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: bloodTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedBloodType = value),
                decoration: InputDecoration(
                  labelText: "Blood Type",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null ? "Please select blood type" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedDonationType,
                items: donationTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDonationType = value),
                decoration: InputDecoration(
                  labelText: "Donation Type",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null ? "Please select donation type" : null,
              ),
              _buildTextField(
                label: "Units Collected",
                controller: _unitsController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: "Donation Date",
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text("Save to Inventory"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
