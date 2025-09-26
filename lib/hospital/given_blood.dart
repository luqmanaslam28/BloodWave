import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comercial_screen.dart'; // For navigation

class GiveBloodScreen extends StatefulWidget {
  const GiveBloodScreen({super.key});

  @override
  State<GiveBloodScreen> createState() => _GiveBloodScreenState();
}

class _GiveBloodScreenState extends State<GiveBloodScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientContactController =
      TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedPurpose;

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

  final List<String> purposes = [
    "Emergency",
    "Surgery",
    "Anemia",
    "Accident",
    "Other"
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientContactController.dispose();
    _unitsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      // Save under orgId / subcollection "records"
      await FirebaseFirestore.instance
          .collection("blood_issued")
          .doc(user.uid) // orgId
          .collection("records")
          .add({
        "patientName": _patientNameController.text.trim(),
        "patientContact": _patientContactController.text.trim(),
        "bloodType": _selectedBloodType,
        "purpose": _selectedPurpose,
        "unitsGiven": int.tryParse(_unitsController.text.trim()) ?? 0,
        "date": _dateController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Clear form
      _formKey.currentState!.reset();
      _patientNameController.clear();
      _patientContactController.clear();
      _unitsController.clear();
      _dateController.clear();
      setState(() {
        _selectedBloodType = null;
        _selectedPurpose = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Blood issued successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HospitalHomeScreen(name: ''),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
          "Issue Blood to Patient",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                label: "Patient Name",
                controller: _patientNameController,
              ),
              _buildTextField(
                label: "Patient Contact",
                controller: _patientContactController,
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: bloodTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBloodType = value),
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
                value: _selectedPurpose,
                items: purposes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPurpose = value),
                decoration: InputDecoration(
                  labelText: "Purpose",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null ? "Please select purpose" : null,
              ),
              _buildTextField(
                label: "Units Issued",
                controller: _unitsController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: "Issued Date",
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
                  icon: const Icon(Icons.local_hospital),
                  label: const Text("Issue Blood"),
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
