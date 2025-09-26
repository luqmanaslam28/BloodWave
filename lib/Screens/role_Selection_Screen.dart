import 'package:bloodwave/hospital/comercial_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcomescreen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String name;
  final VoidCallback onRoleSelected;
  const RoleSelectionScreen({super.key, required this.name, required this.onRoleSelected});

  void _selectRole(BuildContext context, String accountType) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('user_roles').doc(uid).set({
      'accountType': accountType,
    }, SetOptions(merge: true)); // ✅ Only set once

    onRoleSelected();

    if (accountType == 'person') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HospitalHomeScreen(name: 'Hospital/Blood Bank')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Your Role", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoleButton(context, "Person", () => _selectRole(context, 'person')),
            const SizedBox(height: 20),
            _buildRoleButton(context, "Hospital / Blood Bank", () => _selectRole(context, 'hospital')),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
        child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
