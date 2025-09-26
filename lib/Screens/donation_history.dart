import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IncomingDonorScreen extends StatelessWidget {
  const IncomingDonorScreen({super.key});

  // Fetch donor profile from 'users' collection
  Future<Map<String, dynamic>?> _getDonorProfile(String donorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorId)
          .get();
      if (snapshot.exists) return snapshot.data();
    } catch (e) {
      debugPrint("Error fetching donor profile: $e");
    }
    return null;
  }

  // Fetch organization profile by orgType and ownerId match
  Future<Map<String, dynamic>?> _getOrganizationProfile(
    String ownerId,
    String orgType,
  ) async {
    try {
      String collection = orgType == "Hospital" ? "hospitals" : "bloodbanks";

      final query = await FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) return query.docs.first.data();
    } catch (e) {
      debugPrint("Error fetching organization profile: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final String currentOrgId = FirebaseAuth.instance.currentUser!.uid;

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Donation History",
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donation_history')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No incoming donors yet.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                String donorId = data['donorId'] ?? '';
                String city = data['city'] ?? '';
                String orgType = data['orgType'] ?? '';
                String ownerId = data['ownerId'] ?? '';
                DateTime createdAt = (data['createdAt'] as Timestamp).toDate();

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _getOrganizationProfile(ownerId, orgType),
                  builder: (context, orgSnapshot) {
                    if (orgSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(
                          child: LinearProgressIndicator(color: Colors.red),
                        ),
                      );
                    }

                    final org = orgSnapshot.data;
                    if (org == null) return const SizedBox.shrink();

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getDonorProfile(donorId),
                      builder: (context, donorSnapshot) {
                        if (donorSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                              child: LinearProgressIndicator(color: Colors.red),
                            ),
                          );
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                          color: Colors.white.withOpacity(0.9),
                          shadowColor: Colors.black26,
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Donated City: $city",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Donated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
