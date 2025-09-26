// ignore_for_file: deprecated_member_use

import 'package:bloodwave/hospital/add_blood.dart';
import 'package:bloodwave/hospital/blood_summary.dart';
import 'package:bloodwave/hospital/blood_units.dart';
import 'package:bloodwave/hospital/comercial_profile.dart';
import 'package:bloodwave/hospital/given_blood.dart';
import 'package:bloodwave/hospital/incoming_donor.dart';
import 'package:bloodwave/hospital/profile.dart';
import 'package:bloodwave/auth/login_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';

class HospitalHomeScreen extends StatelessWidget {
  final String name;

  const HospitalHomeScreen({super.key, required this.name});

  // -------------------------
  // Logout Function
  // -------------------------
  Future<void> _logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigate to login screen after logout
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true, 
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // -------------------------
      // Drawer
      // -------------------------
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.redAccent),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Welcome, $name",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              buildDrawerItem(context, Icons.person, "My Profile", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );
              }),
              const Divider(color: Colors.black),
              buildDrawerItem(context, Icons.logout, "Log Out", () {
                _logoutUser(context);
              }),
            ],
          ),
        ),
      ),

      // -------------------------
      // Body Grid
      // -------------------------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            buildCard(Icons.inventory, "Available Blood Units", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodUnitsScreen(),
                ),
              );
            }),
            buildCard(Icons.people_alt, "Incoming Donors", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncomingDonorScreen(),
                ),
              );
            }),
            buildCard(Icons.add_box, "Add Blood Units", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBloodScreen()),
              );
            }),
            buildCard(Icons.outbond, "Given Blood Units", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GiveBloodScreen()),
              );
            }),
            buildCard(Icons.list_alt, "Blood Summary", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodIssuedListScreen(),
                ),
              );
            }),
            buildCard(Icons.business, "Hospital/Blood Bank Register", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HospitalProfileScreen(),
                ),
              );
            }),
            // buildCard(Icons.logout, "Log Out", () {
            //   _logoutUser(context);
            // }),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Grid Card
  // -------------------------
  Widget buildCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.red.withOpacity(0.2),
        highlightColor: Colors.red.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Colors.redAccent),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // Drawer Item
  // -------------------------
  Widget buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context); // close drawer
        onTap();
      },
    );
  }
}
