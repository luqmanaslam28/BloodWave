// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:bloodwave/Screens/bloodbank_donor.dart';
import 'package:bloodwave/Screens/free_donor.dart';
import 'package:bloodwave/Screens/paid_donor.dart';
import 'package:bloodwave/Screens/hospital_donor.dart';
import 'package:flutter/material.dart';

class RequestBlood extends StatelessWidget {
  const RequestBlood({super.key});

  @override
  Widget build(BuildContext context) {
    return const BloodDonationScreen();
  }
}

class BloodDonationScreen extends StatelessWidget {
  const BloodDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            "Request Blood",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              shadows: [
                Shadow(
                  offset: Offset(1.2, 1.2),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
              decoration: TextDecoration.underline,
              decorationColor: Colors.black12,
              decorationThickness: 1,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FreeDonorScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180, // 🔹 Equal height
                  child: _buildOptionCard(
                    title: "Voluntary Blood Donors",
                    description:
                        "Selfless donors ready to give blood for free to save lives.",
                    icon: Icons.favorite,
                    iconColor: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaidDonorScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180,
                  child: _buildOptionCard(
                    title: "Paid Blood Donors",
                    description:
                        "Donors willing to provide blood with an asking amount.",
                    icon: Icons.attach_money,
                    iconColor: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HospitalDonorScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180,
                  child: _buildOptionCard(
                    title: "Hospitals",
                    description:
                        "Search hospitals that maintain reliable blood stocks.",
                    icon: Icons.local_hospital,
                    iconColor: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BloodBankDonorScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180,
                  child: _buildOptionCard(
                    title: "Blood Banks",
                    description:
                        "Find trusted blood banks for safe and quick donations.",
                    icon: Icons.bloodtype,
                    iconColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable styled card
  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    Color iconColor = Colors.black,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 🔹 Center content
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              maxLines: 3, // 🔹 Keeps text tidy
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
