import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodIssuedListScreen extends StatefulWidget {
  const BloodIssuedListScreen({super.key});

  @override
  State<BloodIssuedListScreen> createState() => _BloodIssuedListScreenState();
}

class _BloodIssuedListScreenState extends State<BloodIssuedListScreen> {
  String? orgId;

  @override
  void initState() {
    super.initState();
    fetchOrgId();
  }

  Future<void> fetchOrgId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      orgId = user.uid; // current logged-in user's UID
    });
  }

  @override
  Widget build(BuildContext context) {
    if (orgId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Issued Blood Records",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("blood_issued")
            .doc(orgId)
            .collection("records")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No blood has been issued yet"),
            );
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final data = records[index].data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(Icons.bloodtype,
                        color: Colors.red, size: 28),
                  ),
                  title: Text(
                   (data["patientName"] ?? "Unknown").toString().toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Purpose: ${data["purpose"] ?? "-"}"),
                      Text("Units: ${data["unitsGiven"] ?? "0"}"),
                      Text("Date: ${data["date"] ?? "-"}"),
                      Text("Blood Type: ${data["bloodType"] ?? "-"}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
