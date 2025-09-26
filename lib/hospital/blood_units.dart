import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodUnitsScreen extends StatelessWidget {
  const BloodUnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

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
          "Blood Inventory Summary",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_inventory')
            .where('orgEmail', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No data found for $userEmail",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          /// Group by donationType then by bloodType
          final Map<String, Map<String, int>> summary = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final donationType = data['donationType'] ?? "Unknown";
            final bloodType = data['bloodType'] ?? "N/A";
            final units = int.tryParse(data['units'].toString()) ?? 0;

            summary.putIfAbsent(donationType, () => {});
            summary[donationType]![bloodType] =
                (summary[donationType]![bloodType] ?? 0) + units;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: summary.entries.map((entry) {
              final donationType = entry.key;
              final bloodData = entry.value;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        donationType,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("Blood Type",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            Text("Quantity (ml)",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Table rows
                      ...bloodData.entries.map((row) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(row.key,
                                  style: const TextStyle(fontSize: 16)),
                              Text("${row.value}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 14),

                      // Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // 👉 Navigate to detail view for this donation type
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BloodDetailScreen(
                                  donationType: donationType,
                                  docs: docs
                                      .where((d) =>
                                          (d.data()
                                              as Map<String, dynamic>)['donationType'] ==
                                          donationType)
                                      .toList(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list, color: Colors.white),
                          label: const Text("View Details",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Detail Screen
class BloodDetailScreen extends StatelessWidget {
  final String donationType;
  final List<QueryDocumentSnapshot> docs;

  const BloodDetailScreen(
      {super.key, required this.donationType, required this.docs});

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
        title: Text(
          "$donationType Details",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Show popup dialog with details
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    "${data['bloodType']} • ${data['units']} ml",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text("Donor Name: ${data['donorName'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("Contact: ${data['donorContact'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("Donation Type: ${data['donationType'] ?? '-'}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("Date: ${data['date'] ?? '-'}",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  "${data['bloodType']} • ${data['units']} ml",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Donor: ${data['donorName'] ?? 'N/A'}"),
                    Text("Contact: ${data['donorContact'] ?? 'N/A'}"),
                    Text("Date: ${data['date'] ?? '-'}"),
                  ],
                ),
                trailing: const Icon(Icons.info_outline, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
