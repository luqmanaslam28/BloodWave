import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IncomingDonorScreen extends StatelessWidget {
  const IncomingDonorScreen({super.key});

  // Fetch donor profile from 'users' collection
  Future<Map<String, dynamic>?> _getDonorProfile(String donorId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(donorId).get();
      if (snapshot.exists) return snapshot.data();
    } catch (e) {
      debugPrint("Error fetching donor profile: $e");
    }
    return null;
  }

  // Fetch organization profile by orgType and ownerId match
  Future<Map<String, dynamic>?> _getOrganizationProfile(
      String ownerId, String orgType) async {
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

  // Popup for confirmation (✅ only store in new collection, don't delete anything)
  void _confirmDonation(
    BuildContext context,
    String requestId,
    String donorId,
    Map<String, dynamic> requestData,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Donation"),
        content: const Text("Did this donor donate blood?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("Marked as ❌ Not Donated"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // ✅ Store donation in donation_history without deleting anything
                await FirebaseFirestore.instance
                    .collection('donation_history')
                    .add({
                  ...requestData,
                  'requestId': requestId,
                  'donorId': donorId,
                  'donatedAt': FieldValue.serverTimestamp(),
                });

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("✅ Donor stored in donation history"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint("Error storing donor: $e");
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final String currentOrgId = FirebaseAuth.instance.currentUser!.uid;

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
          "Incoming Donors",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
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
              final requestId = docs[index].id;

              String donorId = data['donorId'] ?? '';
              String city = data['city'] ?? '';
              String urgency = data['urgency'] ?? '';
              String orgType = data['orgType'] ?? '';
              String ownerId = data['ownerId'] ?? '';
              DateTime createdAt = (data['createdAt'] as Timestamp).toDate();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getOrganizationProfile(ownerId, orgType),
                builder: (context, orgSnapshot) {
                  if (orgSnapshot.connectionState == ConnectionState.waiting) {
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

                      final donor = donorSnapshot.data ?? {};
                      String donorName = donor['name'] ?? 'Unknown';
                      String donorContact = donor['contactNumber'] ?? 'N/A';
                      String donorCity = donor['city'] ?? 'N/A';

                      return InkWell(
                        onTap: () => _confirmDonation(
                          context,
                          requestId,
                          donorId,
                          data,
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "👤 Donor: $donorName",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text("📞 Contact: $donorContact"),
                                Text("🌆 Donor City: $donorCity"),
                                const Divider(height: 20, thickness: 1),
                                Text("📍 Request City: $city"),
                                Text(
                                  "⚡ Urgency: $urgency",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "🕒 Requested on: ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
