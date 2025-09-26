import 'package:bloodwave/admin/detail_screen.dart';
import 'package:bloodwave/admin/hospital_approval_screen.dart';
import 'package:bloodwave/admin/donor_approval_screen.dart';
import 'package:bloodwave/admin/userfeedback.dart';
import 'package:bloodwave/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int totalRequests = 0;
  int totalDonors = 0;
  int totalHospitals = 0;
  int totalBloodBanks = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      // Total requests (users)
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Donors (only approved donation requests)
      final approvedDonorsSnapshot = await FirebaseFirestore.instance
          .collection('donation_requests')
          // .where('status', isEqualTo: 'approved')
          .get();

      // Hospitals
      final hospitalsSnapshot = await FirebaseFirestore.instance
          .collection('hospitals')
          .get();

      // Blood Banks
      final bloodBanksSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .get();

      setState(() {
        totalRequests = requestsSnapshot.size;
        totalDonors = approvedDonorsSnapshot.size;
        totalHospitals = hospitalsSnapshot.size;
        totalBloodBanks = bloodBanksSnapshot.size;
      });
    } catch (e) {
      print("Error fetching counts: $e");
    }
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.redAccent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.redAccent,
                  ),
                ),
                accountName: Text(
                  "Admin Panel",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: Text("Blood Wave"),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.redAccent,
                        ),
                      ),
                      title: const Text(
                        "Hospital Requests",
                        style: TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApprovalScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                        ),
                      ),
                      title: const Text(
                        "Donation Requests",
                        style: TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DonorApprovalScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.feedback,
                          color: Colors.redAccent,
                        ),
                      ),
                      title: const Text(
                        "Users Feedback",
                        style: TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Userfeedback(),
                          ),
                        );
                      },
                    ),
                   
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'v1.0 • BloodWave',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Hospitals',
              totalHospitals,
              Icons.local_hospital,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailsScreen(
                      collectionName: 'hospitals',
                      title: 'Hospitals',
                    ),
                  ),
                );
              },
            ),
            _buildStatCard('Blood Banks', totalBloodBanks, Icons.apartment, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailsScreen(
                    collectionName: 'bloodbanks',
                    title: 'Blood Banks',
                  ),
                ),
              );
            }),
            _buildStatCard('Total Donors', totalDonors, Icons.favorite, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailsScreen(
                    collectionName: 'donation_requests',
                    title: 'Approved Donors',
                  ),
                ),
              );
            }),
            _buildStatCard('Total Users', totalRequests, Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailsScreen(
                    collectionName: 'users',
                    title: 'Users',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
