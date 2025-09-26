// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  // ✅ Step 1: Safely get logged in user's uid
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Step 2: Stream requests for logged in user
  Stream<QuerySnapshot<Map<String, dynamic>>> _getUserRequests() {
    if (_currentUserId == null) {
      // If user not logged in → return empty stream
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('blood_requests')
        .where('userId', isEqualTo: _currentUserId)
        // .orderBy('createdAt', descending: true) // ⚡ ensure field exists
        .snapshots();
  }

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "My Requests",
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

        body: _currentUserId == null
            ? const Center(
                child: Text(
                  "You are not logged in.",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getUserRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No requests found",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    );
                  }

                  final requests = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index].data();

                      // Safely handle createdAt
                      String formattedDate = "N/A";
                      if (req['createdAt'] != null) {
                        final createdAt =
                            (req['createdAt'] as Timestamp).toDate();
                        formattedDate =
                            DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_hospital,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${req['orgName']} (${req['orgType']})",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "City: ${req['city']}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.priority_high,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Urgency: ${req['urgency']}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Date: $formattedDate",
                                    style: const TextStyle(fontSize: 16),
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
              ),
      ),
    );
  }
}
