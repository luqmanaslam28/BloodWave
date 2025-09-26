import 'package:flutter/material.dart';

class OurAimScreen extends StatelessWidget {
  const OurAimScreen({super.key});

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
            "Our Aim",
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
              const Icon(Icons.volunteer_activism,
                  size: 80, color: Colors.redAccent),
              const SizedBox(height: 15),

              const Text(
                "Connecting Lives Through Bloodwave",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                "In times of emergency, every second matters. One of the biggest "
                "challenges patients face is finding the right blood donor or "
                "hospital in time. Delays can cost lives, and that's the problem "
                "we aim to solve with Bloodwave.",
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // Need Section
              _buildSection(
                title: "The Need",
                description:
                    "Thousands of people every day struggle to find blood in "
                    "critical situations. Often, families have to make countless "
                    "calls and requests, wasting precious time that could save a life.",
                icon: Icons.bloodtype,
              ),
              const SizedBox(height: 20),

              // Approach Section
              _buildSection(
                title: "Our Approach",
                description:
                    "Bloodwave bridges the gap between patients, donors, and hospitals. "
                    "By creating a seamless platform, we ensure that patients in urgent "
                    "need can instantly connect to available donors or nearby hospitals, "
                    "making the process faster, reliable, and life-saving.",
                icon: Icons.connect_without_contact,
              ),
              const SizedBox(height: 20),

              // Vision Section
              _buildSection(
                title: "Our Vision",
                description:
                    "A world where no life is lost due to lack of blood in emergencies. "
                    "Together, we can build a community of donors and ensure that help is "
                    "always just a tap away.",
                icon: Icons.remove_red_eye,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.redAccent),
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
            ),
          ],
        ),
      ),
    );
  }
}
